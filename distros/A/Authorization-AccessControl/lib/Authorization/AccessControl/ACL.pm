package Authorization::AccessControl::ACL 0.03;
use v5.26;
use warnings;

# ABSTRACT: Access Control List of granted privileges

use Authorization::AccessControl::Grant;
use Authorization::AccessControl::Request;
use List::Util qw(any);
use Readonly;

use experimental qw(signatures);

sub new($class, %params) {
  my $base = delete($params{base});
  my $role = delete($params{role});

  die("Unsupported params: ", join(', ', keys(%params))) if (keys(%params));

  Readonly::Hash1 my %hooks => (
    on_permit => [],
    on_deny   => []
  );

  Readonly::Hash1 my %data => (
    _base   => $base,
    _role   => $role,
    _grants => ($base ? undef : []),        # prevent privs from being saved in non-base instances
    _hooks  => ($base ? undef : \%hooks),
  );
  bless(\%data, $class);
}

sub hook($self, $type, $sub) {
  push($self->_base_instance->{_hooks}->{$type}->@*, $sub);
}

sub clone($self) {
  my $clone = __PACKAGE__->new();
  push($clone->{_grants}->@*,      $self->{_grants}->@*);
  push($clone->{_hooks}->{$_}->@*, $self->{_hooks}->{$_}->@*) foreach (keys($self->{_hooks}->%*));
  return $clone;
}

sub _base_instance($self) {
  $self->{_base} // $self;
}

sub role($self, $role = undef) {
  return __PACKAGE__->new(base => $self->_base_instance, role => $role);
}

sub grant($self, $resource, $action, $restrictions = undef) {
  my $p = Authorization::AccessControl::Grant->new(
    role         => $self->{_role},
    resource     => $resource,
    action       => $action,
    restrictions => $restrictions,
  );
  if (any {$p->is_equal($_)} $self->_base_instance->{_grants}->@*) {
    warn("skipping duplicate grant: $p\n");
  } else {
    push($self->_base_instance->{_grants}->@*, $p);
  }
  return $self;
}

sub __contains($arr, $v) {
  return 0 unless (defined($v));
  any {$_ eq $v} $arr->@*;
}

sub get_grants($self, %filters) {
  my @grants = $self->_base_instance->{_grants}->@*;
  @grants = grep {$_->resource eq $filters{resource}} @grants                          if (exists($filters{resource}));
  @grants = grep {$_->action eq $filters{action}} @grants                              if (exists($filters{action}));
  @grants = grep {__contains($filters{roles}, $_->role) || !defined($_->role)} @grants if (exists($filters{roles}));
  return @grants;
}

sub request($self) {
  warn("Warning: Calling `roles` on the result of `role` or `grant` calls may not yield expected results\n") if ($self->{_base});
  return Authorization::AccessControl::Request->new(acl => $self->_base_instance);
}

sub _event($self, $type, $ctx) {
  $_->($ctx) foreach ($self->_base_instance->{_hooks}->{$type}->@*);
}

=head1 NAME

Authorization::AccessControl::ACL - Access Control List of granted privileges

=head1 SYNOPSIS

  use Authorization::AccessControl::ACL;

  my $acl = Authorization::AccessControl::ACL->new();
  $acl->role("admin")
    ->grant(User => "delete")
    ->grant(User => "create");

  $acl->grant(Book => "search")
    ->grant(Book => 'delete', {owned => true});

  my req = $acl->request;
  ...

=head1 DESCRIPTION

The ACL class provides functionality for maintaining a set of granted privileges.
Each item in the list is an instance of L<Authorization::AccessControl::Grant>.
Every call to L</grant> creates a new grant instance and adds it to the ACL's
list. By default, these grants are role-less: they apply to all users. Calling
L</role> with a role name argument allows you to chain subsquent calls to 
L</grant> off of it: such grants are configured for that role only.

The full grant list can be obtained via the L</get_grants> method, although this
is merely informational - the grants themselves are immutable and have little
relevent functionality outside of the ACL.

The L</request> method generates an L<Authorization::AccessControl::Request>, 
which is used to check if a specific action is permitted by the ACL.

Most ACL instance properties are immutable: with the exception of the list 
contents, none of their properties may be altered after object creation.

=head1 METHODS

=head2 new

  Authorizatrion::AccessControl::ACL->new()

Constructor.

Creates a new ACL instance. Each ACL instance created via this constructor is
entirely unrelated. For a global persistent ACL, see 
L<Authorization::AccessControl/acl>

=head2 clone

  $acl->clone()

Creates a new ACL instance pre-populated with the cloned object's grants and 
hooks. Once cloned, the two instances are entirely unrelated and changes to one 
will not be reflected in the other.

N.B. contextual L<role|/role> is not taken into account when cloning:

  my $acl2 = $acl1->role('admin')->grant(User => "delete")->clone;
  $acl2->grant(User => "update"); 

The second grant is role-less, applying to all users, even though the admin role
context was active when the clone was performed. This may cause you to 
inadvertently grant more privileges than you expect if not attended to.

=head2 role

  $acl->role($role = undef)

Returns a new I<dependent> instance of C<Authorization::AccessControl::ACL>
facilitating chaining in order to create role-specific grants. Dependent 
instances share a grant list with their "parent".

The C<$role> argument is optional, if omitted or C<undef>, the returned instance
becomes role-less. If present, should be a string.

Chainable.

=head2 grant

  $acl->grant($resource => $action)

Creates a privilege L<Authorization::AccessControl::Grant> and adds it to the 
access control list.

Chainable.

=head2 get_grants

  $acl->get_grants()

Returns an array of all grants contained in the access control list.

=head2 request

  $acl->request()

Returns an L<Authorization::AccessControl::Request> instance linked to this ACL.
Subsequent changes to the ACL will be taken into account if made prior to the 
request being evaluated. L</clone> first to avoid the implications of this 
behavior, if required.

=head2 hook

  $acl->hook(on_permit|on_deny => sub {})

Register a callback to be executed when a permission request is granted or 
denied, such as for comprehensive authorization logging. Multiple hooks may be
registered for each status, and will be called in order when the event occurs.

C<on_permit> handlers receive a L<Authorization::AccessControl::Grant> that 
accepted the request as their argument.

C<on_deny> handlers receive a L<Authorization::AccessControl::Request> that 
failed to be accepted by any grant as their argument.

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
