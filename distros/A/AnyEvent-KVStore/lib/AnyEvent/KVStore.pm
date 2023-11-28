package AnyEvent::KVStore;

use 5.010;
use strict;
use warnings FATAL => 'all';

=head1 NAME

AnyEvent::KVStore - A pluggable key-value store API for AnyEvent

=head1 VERSION

Version 0.1.2

=cut

use strict;
use warnings;
use Moo;
use Type::Tiny;
use Try::Tiny;
use Types::Standard qw(Str HashRef);
our $VERSION = '0.1.2';


=head1 SYNOPSIS

    use AnyEvent::KVStore;

    my $foo = AnyEvent::KVStore->new(type => 'etcd', config => $config);
    my $val = $foo->read($key);
    $foo->write($key, $val2);

    $foo->watch($keyspace, \&process_vals);

=head1 DESCRIPTION

The AnyEventLLKVStore framework intends to be a simple, pluggable API for
abstracting away the details of key-value store integratoins in event loop for
the standard operations one is likely to experience in an event loop.

The idea is to make key-value stores reasonably pluggable for variou skinds of
operations so that when one fails to scale in one scenario, another can be used
and alaternatively, the same app can support several different stores.

The framework uses Moo (Minimalist Object Orientation) to procide the basic
interface specifications, and modules providing drivers here are expected to
use Moo for defining accessors, etc.

=head1 ACCESSORS/PROPERTIES

=head2 module

The name of the driver used.

=cut

my $kvs_module = Type::Tiny->new(
    name       => 'Module',
    constraint => sub { $_->does('AnyEvent::KVStore::Driver')},
    message    => sub { "Not a kvstore driver object: $_"},
);

has _proxy => ( is => 'lazy', isa => $kvs_module, builder => \&_connect,
                handles => 'AnyEvent::KVStore::Driver');

sub _connect($){
    my ($self) = @_;
    local $@ = undef;
    my $modname = "AnyEvent::KVStore::" . ucfirst($self->module);
    eval "require $modname" or die $@;
    return $modname->new($self->config);
}

has module => (is => => 'ro', isa => Str, required => 1);

=head2 config

This is the configuratoin to connect to the driver.

=cut

has config => (is => 'ro', isa => HashRef, required => 1);

=head1 SUBROUTINES/METHODS

=head2 new($args or %args)

Returns a new kvstore object for use in your application.  Note that the actual
connection is lazy, and therefore is not even made until use.  This uses
standard Moo/Moose constructor syntax.

=head2 list($prefix)

List all keys starting with C<$prefix>

Returns a list of strings.

=head2 exists($key)

Returns true if the key exists, false if it does not.

=head2 read($key)

Returns the value of the key.

=head2 write($key, $value)

Writes the key to the key value store.

=head2 watch($prefix, $callback)

Watch the keys starting with C<$prefix> and for each such key, execute 
$callback with the arguments as ($key, $value)

=head1 WRITING YOUR OWN DRIVER

Your driver should consume the L<AnyEvent::KVStore::Driver> role.  It then
needs to implement the required interfaces.  See the L<AnyEvent::KVStore::Driver>
documentation for details.

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-kvstore at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-KVStore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 MODULE VARIATION

A few properties may vary from one module to another.  For example, most
modules should support multiple watch runs concurrently, though it is possible
that some might not.  Different modules may require different configuration
hash keys.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::KVStore


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-KVStore>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/AnyEvent-KVStore>

=item * Search CPAN

L<https://metacpan.org/release/AnyEvent-KVStore>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Chris Travers.

This is free software, licensed under:

  The (three-clause) BSD License


=cut

1; # End of AnyEvent::KVStore
