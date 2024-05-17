package Authorization::AccessControl::Request 0.03;
use v5.26;
use warnings;

# ABSTRACT: Constructs an ACL request and checks if it is accepted

use Authorization::AccessControl::Dispatch;
use Readonly;
use Scalar::Util qw(looks_like_number);

use constant true  => !0;
use constant false => !1;

use experimental qw(signatures);

use overload
  '""' => \&to_string;

sub new($class, %params) {
  my $acl        = delete($params{acl});
  my $roles      = delete($params{roles});
  my $resource   = delete($params{resource});
  my $action     = delete($params{action});
  my $attributes = delete($params{attributes}) // {};
  my $get_attrs  = delete($params{get_attrs})  // undef;

  die("Unsupported params: ", join(', ', keys(%params))) if (keys(%params));
  die("acl is a required property") unless (defined($acl) && ref($acl) && $acl->isa('Authorization::AccessControl::ACL'));

  Readonly::Scalar my $data => {
    _acl        => $acl,
    _roles      => $roles,
    _resource   => $resource,
    _action     => $action,
    _attributes => $attributes,
    _get_attrs  => $get_attrs,
  };
  bless($data, $class);
}

sub to_string($self, @params) {
  my $roles      = ($self->{_roles} // [])->@* ? '[' . join(',', ($self->{_roles} // [])->@*) . ']' : '';
  my $attributes = '';
  my $resource   = $self->{_resource} // '{NO_RESOURCE}';
  my $action     = $self->{_action}   // '{NO_ACTION}';
  foreach (keys($self->{_attributes}->%*)) {
    my $v;
    if    ($self->{_attributes}->{$_})                    {$v = $self->{_attributes}->{$_}}
    elsif (looks_like_number($self->{_attributes}->{$_})) {$v = 0}
    else                                                  {$v = 'false'}
    $attributes .= "$_=$v,";
  }
  chop($attributes);
  $roles . $resource . ' => ' . $action . '(' . $attributes . ')';
}

sub __properties($self) {
  (
    acl        => $self->{_acl},
    roles      => $self->{_roles},
    resource   => $self->{_resource},
    action     => $self->{_action},
    attributes => $self->{_attributes},
    get_attrs  => $self->{_get_attrs},
  )
}

sub with_roles($self, @roles) {
  return __PACKAGE__->new($self->__properties, roles => [@roles],);
}

sub with_action($self, $action) {
  return __PACKAGE__->new($self->__properties, action => $action,);
}

sub with_resource($self, $resource) {
  return __PACKAGE__->new($self->__properties, resource => $resource,);
}

sub with_attributes($self, $attrs) {
  return __PACKAGE__->new($self->__properties, attributes => {$self->{_attributes}->%*, $attrs->%*},);
}

sub with_get_attrs($self, $sub) {
  return __PACKAGE__->new($self->__properties, get_attrs => $sub,);
}

sub permitted($self) {
  return false unless (defined($self->{_resource}));
  return false unless (defined($self->{_action}));

  my @grants =
    grep {
    $_->accepts(
      roles      => $self->{_roles},
      resource   => $self->{_resource},
      action     => $self->{_action},
      attributes => $self->{_attributes},
    )
    } $self->{_acl}->get_grants;
  if (@grants) {
    $self->{_acl}->_event(on_permit => $grants[0]);
    return true;
  }
  $self->{_acl}->_event(on_deny => $self);
  return false;
}

sub yield($self, $get_obj) {
  unless (defined($self->{_get_attrs})) {
    return Authorization::AccessControl::Dispatch->new(granted => false) unless ($self->permitted);
    my $obj = $get_obj->();
    return Authorization::AccessControl::Dispatch->new(granted => undef) unless (defined($obj));
    return Authorization::AccessControl::Dispatch->new(granted => true, entity => $obj);
  }
  my $obj = $get_obj->();
  return Authorization::AccessControl::Dispatch->new(granted => undef) unless (defined($obj));

  my $attrs = $self->{_get_attrs}->($obj);
  $self = $self->with_attributes($attrs);
  return Authorization::AccessControl::Dispatch->new(granted => true, entity => $obj) if ($self->permitted);
  return Authorization::AccessControl::Dispatch->new(granted => false);
}

=head1 NAME

Authorization::AccessControl::Request - constructs an ACL request and checks if it is accepted

=head1 SYNOPSIS

  return unless(acl->request
    ->with_roles('admin')
    ->with_resource('Media')
    ->with_action('create')
    ->permitted);

  acl->request...->yield(sub() { ... })
    ->granted(sub ($x) { ... })
    ->denied(sub() { ... })

=head1 DESCRIPTION

This class is used to construct a request and check if the ACL accepts it. The 4
C<with_*> methods are used to configure it, with later calls to the same method
overwriting previous ones (with the exception of C<with_attributes> which merges
instead).

L</permitted> can be called directly, or via L</yield>, but either way, it will
return false until L</with_resource> and L<with_action> have been called to
configure it. 

Request instances are immutable: none of their properties may be altered after
object creation.

=head1 METHODS

=head2 with_roles

  $req->with_roles( @roles )

Returns a new request instance with its C<roles> property configured to match
the parameter value.

Chainable.

=head2 with_action

  $req->with_action( $action )

Returns a new request instance with its C<action> property configured to match
the parameter value.

Chainable.

=head2 with_resource

  $req->with_resource( $resource )

Returns a new request instance with its C<resource> property configured to match
the parameter value.

Chainable.

=head2 with_attributes

  $req->with_attributes( $attributes )

Returns a new request instance with its C<attributes> property merged with the
parameter value. 

Chainable.

=head2 with_get_attrs

  $req->with_get_attrs( sub($value) { ... } )

Returns a new request instance with its C<get_attrs> property configured to match
the parameter value. This is a callback that receives a protected data value 
(in L</yield>) and returns the corresponding dynamic attributes for it.

Chainable.

=head2 permitted

  $req->permitted()

Returns a boolean value reflecting whether the request's configured properties
satisfy the requirements for any grant in the ACL.

=head2 yield

  $req->yield(sub() { ... })

Returns an L<Authorization::AccessControl::Disapatch> instance corresponding
to the data value returned by the callback and its permitted status.

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
