package Authorization::AccessControl::Grant 0.03;
use v5.26;
use warnings;

# ABSTRACT: Encapsulation of the parameters of a privilege grant

use Data::Compare;
use Readonly;
use Scalar::Util qw(looks_like_number);

use experimental qw(signatures);

use overload
  '""' => 'to_string';

sub new($class, %params) {
  my $role         = delete($params{role});
  my $resource     = delete($params{resource});
  my $action       = delete($params{action});
  my $restrictions = delete($params{restrictions});
  $restrictions = {} unless (defined($restrictions));

  die("Unsupported params: ", join(', ', keys(%params))) if (keys(%params));
  die("Role must be a non-empty string") if (defined($role) && (ref($role) || $role eq ''));
  die("Resource is required")           unless ($resource              && !ref($resource));
  die("Action is required")             unless ($action                && !ref($action));
  die("Restrictions must be a HashRef") unless (defined($restrictions) && ref($restrictions) eq 'HASH');

  Readonly::Scalar my $data => {
    _role         => $role,
    _resource     => $resource,
    _action       => $action,
    _restrictions => $restrictions
  };

  bless($data, $class);
}

sub to_string($self, @params) {
  my $role         = $self->{_role} ? '[' . $self->{_role} . '] ' : '';
  my $restrictions = '';
  foreach (keys($self->{_restrictions}->%*)) {
    my $v;
    if    ($self->{_restrictions}->{$_})                    {$v = $self->{_restrictions}->{$_}}
    elsif (looks_like_number($self->{_restrictions}->{$_})) {$v = 0}
    else                                                    {$v = 'false'}
    $restrictions .= "$_=$v,";
  }
  chop($restrictions);
  $role . $self->{_resource} . ' => ' . $self->{_action} . '(' . $restrictions . ')';
}

sub role($self) {
  $self->{_role};
}

sub resource($self) {
  $self->{_resource};
}

sub action($self) {
  $self->{_action};
}

sub restrictions($self) {
  $self->{_restrictions};
}

sub _satisfies_role($self, @roles) {
  return 1 unless ($self->{_role});
  return (grep {$_ eq $self->{_role}} @roles) > 0;
}

sub _satisfies_resource($self, $resource) {
  return 0 unless (defined($resource));
  return $self->{_resource} eq $resource;
}

sub _satisfies_action($self, $action) {
  return 0 unless (defined($action));
  return $self->{_action} eq $action;
}

sub _satisfies_restrictions($self, $attributes) {
  my %attrs = $attributes->%*;
  delete($attrs{$_}) foreach (grep {!exists($self->{_restrictions}->{$_})} keys(%attrs));
  my $v = Compare($self->{_restrictions}, \%attrs);
  return $v;
}

sub is_equal($self, $priv) {
  return 0 unless (($self->role // '') eq ($priv->role // ''));
  return 0 unless ($self->resource eq $priv->resource);
  return 0 unless ($self->action eq $priv->action);
  return 0 unless (Compare($self->restrictions, $priv->restrictions));
  return 1;
}

sub accepts($self, %params) {
  my ($roles, $resource, $action, $attributes) = @params{qw(roles resource action attributes)};

  return 0 unless ($self->_satisfies_resource($resource));
  return 0 unless ($self->_satisfies_action($action));
  return 0 unless ($self->_satisfies_role(($roles // [])->@*));
  return 0 unless ($self->_satisfies_restrictions($attributes // {}));
  return 1;
}

=head1 NAME

Authorization::AccessControl::Grant - Encapsulation of the parameters of a privilege grant

=head1 SYNOPSIS

  use Authorization::AccessControl::Grant;

  my $grant = Authorization::AccessControl::Grant->new(
    resource => 'Book',
    action   => 'read',
  );

  $grant->accepts(resource => 'Book', action => 'read'); 

=head1 DESCRIPTION

This is a simple class to encapsulate the properties of a privilege grant:
resource, action, roles, and restrictions, with the latter two optional. Methods 
are available for checking all properties at once (L</accepts>) and determining 
if another grant is exactly equal (used for duplicate detection) (L<is_equal>).

Grant instances are immutable: none of their properties may be altered after
object creation.

=head1 METHODS

=head2 new

  Authorization::AccessControl::Grant->new( %params )

Creates a new privilege grant instance. Normally, you should use
L<Authorization::AccessControl::ACL/grant> rather than this constructor
directly, to create and "register" instances. C<resource>, C<action>, C<role>,
and C<restrictions> keys are respected in C<%params>

=head2 role

Accessor for the C<role> property

=head2 resource

Accessor for the C<resource> property

=head2 action

Accessor for the C<action> property

=head2 restrictions

Accessor for the C<restrictions> property

=head2 is_equal

  $grant1->is_equal($grant2)

Returns true if all properties of both grants are exactly the same, false 
otherwise

=head2 accepts

  $grant->accepts( %params )

Returns true if the parameters meet all of the requirements of the grant, false
otherwise. Specifically, this means that C<resource> and C<action> must match
exactly, the grant's C<role> (if set) must be contained within the C<roles>
ArrayRef, and every item in the grant's C<restrictions> must be matched by a
corresponding entry with the same value in the C<attributes> HashRef

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
