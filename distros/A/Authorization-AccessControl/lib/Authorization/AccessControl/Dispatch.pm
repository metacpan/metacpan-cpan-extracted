package Authorization::AccessControl::Dispatch 0.04;
use v5.26;
use warnings;

# ABSTRACT: Dispatch result/status appropriately following ACL request yield

use Readonly;

use experimental qw(signatures);

sub new($class, %params) {
  my $granted = delete($params{granted});
  $granted = !!$granted if (defined($granted));    #force into boolean/undef
  my $entity = delete($params{entity});
  undef($entity) unless ($granted);                # ensure we don't hold the protected value if access is not granted

  die("Unsupported params: ", join(', ', keys(%params))) if (keys(%params));

  Readonly::Hash1 my %data => (
    _granted => $granted,
    _entity  => $entity,
  );

  bless(\%data, $class);
}

sub granted($self, $sub) {
  $sub->($self->{_entity}) if ($self->{_granted});
  return $self;
}

sub denied($self, $sub) {
  $sub->() if (defined($self->{_granted}) && !$self->{_granted});
  return $self;
}

sub null($self, $sub) {
  $sub->() if (!defined($self->{_granted}));
  return $self;
}

sub is_granted($self) {
  return ($self->{_granted} // 0) != 0;
}

=head1 NAME

Authorization::AccessControl::Dispatch - Dispatch result/status appropriately 
following ACL request yield

=head1 SYNOPSIS

  use Authorization::AccessControl::Dispatch;

  my $dispatch = Authorization::AccessControl::Dispatch->new(
    granted => 1,
    entity => 'some secure value');

  $dispatch->denied(...); # not called
  $dispatch->null(...); # not called
  $dispatch->granted(sub($val) { $c->render(text => $val) }); # renders value

  $request->yield(sub(){...})
    ->granted(sub($val) { #handle success 
    })
    ->denied(sub() { # handle denial
    })
    ->null(sub() { # handle not found
    })

Handlers can be repeated:

  $request->yield(sub(){...})
    ->granted(sub($value){ $c->render(json => $value) })
    ->granted(\&write_audit_log)

=head1 DESCRIPTION

This is a lightweight class that simply facilitates a "promise-style" callback
interface for dealing with the result of 
L<yield|Authorization::AccessControl::Request/yield> in 
C<Authorization::AccessControl::Request>

Dispatch instances are immutable: none of their properties may be altered after
object creation.

=head1 METHODS

=head2 new

  Authorization::AccessControl::Dispatch->new(granted => [0|1|undef], entity => ...)

Creates a new Dispatch instance. C<granted> is a trinary value reflecting the
request status: "truthy" indicates permitted, "falsy" indicates denied, and
undefined indicates that necessary attributes could not be evaluated because the
data value was not present. C<entity> is the data value, to be passed to 
L</granted> handlers. If C<granted> is anything but "truthy", the C<entity> 
value is immediately undefined before proceeding.

=head2 granted

  $dispatch->granted(sub($result){...})

Registers a handler to be executed when the request is permitted by the ACL. 
Handler receives one argument: the 
L<yield|Authorization::AccessControl::Request/yield>ed value

Repeatable. Chainable.

=head2 denied

  $dispatch->denied(sub(){...})

Registers a handler to be executed when the request is denied by the ACL. 
Handler receives no arguments.

Repeatable. Chainable.

=head2 null

  $dispatch->null(sub(){ ... })

Registers a handler to be executed when the 
L<yield|Authorization::AccessControl::Request/yield>ed value is undefined. 
Handler receives no arguments.

Repeatable. Chainable.

=head2 is_granted

  $dispatch->is_granted()

Returns a boolean value reflecting whether or not the request was permitted by 
the ACL

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
