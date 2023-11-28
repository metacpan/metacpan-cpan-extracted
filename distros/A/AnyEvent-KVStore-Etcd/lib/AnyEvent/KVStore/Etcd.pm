package AnyEvent::KVStore::Etcd;

use 5.010;
use strict;
use warnings;
use Net::Etcd;
use Types::Standard qw(Str Int Bool);
use Moo;
use JSON 'decode_json';
use MIME::Base64 'decode_base64';
with 'AnyEvent::KVStore::Driver';

=head1 NAME

AnyEvent::KVStore::Etcd - An Etcd driver for AnyEvent::KVStore

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

   use AnyEvent::KVStore;
   $config = { host => $host, port => $port };
   my $store = AnyEvent::KVStore->new(module => 'etcd', config => $config);

=head1 DESCRIPTION

AnyEvent::KVStore::Etcd is a driver for L<AnyEvent::KVStore> which uses the
Etcd distributed key-value store as its backend.  We use the Net::Etcd driver
for this, though there are some important limitations.

The primary documentation for this module is in the L<AnyEvent::KVStore> module
but there are some important limitations discussed here.

This module can also be used directly for simplified access to an Etcd database.

=head2 AnyEvent Loops, Callbacks, and KVStore Operations

Net::Etcd uses L<AnyEvent::HTTP> for its transport layer.  It further blocks in
an L<AnyEvent> loop to wait for the response.  For obvious reasons, this does
not work.  So, the main key/value operations cannot be done from inside an
event loop.  This leads to a number of possible solutions including forking and
running the request in another process.

One option, though it does incur significant startup cost, is to use L<Coro>
and move the callback from a C<sub {}> call to an C<unblock_sub {}> call.  This
is probably the simplest approach and it works.  In general you get sequential
ordering but this is not a hard guarantee.  Another approach might be to move
processing into worker threads.

=head1 ATTRIBUTES/ACCESSORS

If accessing the module directly, the following accessors are available.  These
are not generally needed and are mostly used internally for managing the
connection to the etcd server.

These are also keys for the config hash.

All attributes are optional.

=head2 host Str

This is the hostname for the etcd connection.  It defaults to localhost.

=cut

has host => (is => 'ro', isa => Str, default => sub { 'localhost' });

=head2 port Int

Port for connection.  It defaults to 2379.

=cut

has port => (is => 'ro', isa => Int, default => sub { 2379 } );

=head2 ssl Bool default false

whether to use SSL or not.  The default is no.

=cut

has ssl => (is => 'ro', isa => Bool, default => 0);

=head2 user Str

Username for authentication.  Does not authenticate if not set.

=cut

has user => (is => 'ro', isa => Str);

=head2 password Str

Password for authentication.

=cut


has password => (is => 'ro', isa => Str);

=head2 cnx Net::Etcd

This is the active connection to the etcd database.

=cut

# $self->_slice returns a hashref with the properties requested.
# This relies on the fact that Moo(se) objects are blessed hashrefs.

sub _slice {
    my $self = shift;
    my @vars = @_;
    return { %{$self}{@vars} };
}

sub _etcd_connect {
    my $self = shift;
    my $cnx = Net::Etcd->new($self->_slice('host', 'port', 'ssl'));
    die 'Could not create new etcd connection' unless $cnx;
    $cnx->auth($self->_slice('user', 'password'))->authenticate if $self->user;
    return $cnx;
}


has cnx => (is => 'ro', builder => '_etcd_connect', lazy => 1);

=head1 METHODS

=head2 read

Reads a value from a key and returns a JSON document payload.

=cut

sub read($$) {
    my ($self, $key) = @_;
    my $value =  $self->cnx->range({key => $key })->{response}->{content};
    $value = decode_json($value)->{kvs}->[0]->{value};
    return decode_base64($value);
}



=head2 exists

Checks to see if a key exists.  Here this is no less costly than read.

=cut

sub exists($$) {
    my ($self, $key) = @_;
    my $value =  $self->cnx->range({key => $key })->{response}->{content};
    $value = decode_json($value)->{kvs}->[0]->{value};
    return defined $value;;
}

=head2 list($pfx)

Returns a list of keys

=cut

# adds one to the binary representation of the string for prefix searches
sub _add_one($){
    my ($str) = @_;
    if ($str =~ /^\xff*$/){ # for empty string too
        return "\x00";
    }
    my $inc = $str;
    $inc =~ s/([^\xff])\xff*\z/ $1 =~ tr||\x01-\xff|cr /e;
    return $inc;
}

sub list($$) {
    my ($self, $pfx) = @_;
    my $value =  $self->cnx->range({key => $pfx, range_end => _add_one($pfx)})->{response}->{content};
    return  map { decode_base64($_->{key} ) }  @{decode_json($value)->{kvs}};
}


=head2 write($key, $value)

Writes the key to the database and returns 1 if successful, 0 if not.

=cut

sub write($$$) {
    my ($self, $key, $value)  = @_;
    return $self->cnx->put({ key => $key, value => $value })->is_success;
}

=head2 watch($pfx, $callback)

This sets up a "watch" where notifications of changed keys are passed to the
script.  This can only really be handled inside an AnyEvent loop because the
changes can come from outside the program.

The callback takes the arguments of C<($key, $value)> of the new values.

=cut

sub _portability_wrapper {
    my ($sub, $result) = @_;
    use Data::Dumper;
    for my $e (@{decode_json($result)->{result}->{events}}){
        $e = $e->{kv};
        &$sub(decode_base64($e->{key}), decode_base64($e->{value}));
   }
}

sub watch($$$) {
    my ($self, $pfx, $subroutine ) = @_;
    return $self->cnx->watch({key => $pfx, range_end => _add_one($pfx)},
        sub { my ($result)  = @_; _portability_wrapper($subroutine, $result) })->create;
}


=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-kvstore-etcd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-KVStore-Etcd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::KVStore::Etcd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-KVStore-Etcd>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/AnyEvent-KVStore-Etcd>

=item * Search CPAN

L<https://metacpan.org/release/AnyEvent-KVStore-Etcd>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Chris Travers.

This is free software, licensed under:

  The (three-clause) BSD License


=cut

1; # End of AnyEvent::KVStore::Etcd
