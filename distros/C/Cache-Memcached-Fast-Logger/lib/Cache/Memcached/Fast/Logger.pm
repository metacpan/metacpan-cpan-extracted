package Cache::Memcached::Fast::Logger;

use strict;
use warnings;

our $VERSION = 0.15;

sub store_namespace (&$);

sub new {
    my ( $class, %opts ) = @_;

    $opts{namespace} ||= 'logger:';
    bless \%opts, $class;

    \%opts;
}

sub log {
    my ( $self, $log ) = @_;

    store_namespace {
	my $new_counter;

	warn "Cannot increment counter - maybe the connect to memcached was loosed"
	  if (   ! defined $self->{cache}->add( 'log_counter', "0" )
	      || ! defined ( $new_counter = $self->{cache}->incr('log_counter') )
	      || ! defined $self->{cache}->set( "log_" . $new_counter, $log ) );
    } $self;
}

sub read_all {
    my ( $self, $sub ) = @_;

    store_namespace {
	my $start = 0;
	my $cache = $self->{cache};
	my ( $log, $ret );

	TERMINATE: while (1) {
	    my ($lc) = $cache->gets('log_counter');
	    last unless defined $lc;

	    for ( my $i = $start; $i <= $lc->[1]; $i++ ) {
		$sub->($log) && ( $cache->delete("log_$i"), 1 ) || last TERMINATE
		  if ( defined( $log = $cache->get("log_$i") ) );
	    }

	    $ret = $cache->cas( 'log_counter', $lc->[0], "0" );
	    last if ! defined($ret) || $ret;

	    # If we are here so some other process has modified a log queue
	    # We try reparse queue again

	    $start = $lc->[1] + 1;
	}
    } $self;
}

sub store_namespace (&$) {
    my ( $code, $self ) = @_;

    my $old_namespace = $self->{cache}->namespace( $self->{namespace} );
    my $ret = eval { $code->() };

    my $error = $@;
    $self->{cache}->namespace( $old_namespace );
    die if $@;

    $ret;
}

1;
__END__

=pod

=head1 NAME

Cache::Memcached::Fast::Logger - the simple logger object for writing and
reading all log items to/from memcached

=head1 SYNOPSIS

    use Cache::Memcached::Fast::Logger;

    my $logger = Cache::Memcached::Fast::Logger->new( cache => Cache::Memcached::Fast->new(...) );

    # one or more processes log items to memcached like this method:
    $logger->log( \%item );

    # Other process - a parser of logs items reads all items by:
    $logger->read_all( sub { $item_hashref = shift; ... ; 1 } );

=head1 DESCRIPTION

Why this module? Sometime i need in helper for logging and parsing some
statistics. To write in file a logs for parsing is very bad idea - I/O of HDD is
very slow.

With this module many concurrent proccesses can write to memcached by L</log> method
and one process (for example a parser of logs) can read all logs in FIFO order
from memcached by L</read_all> method. This module is simple and it uses
atomic L<Cache::Memcached::Fast/incr> & L<Cache::Memcached::Fast/cas>
memcached's protocol methods (for internal counter of queue) for guarantee that
all your items will not be lost during write phase in memcached (memcached
doesn't guarantee a data keeping but if your cache has an enough free slabs you
will not lose your log items)

=head1 CONSTRUCTOR

    my $logger = Cache::Memcached::Fast::Logger->new( %options )

=head2 OPTIONS

=over

=item cache

Example:

    cache => Cache::Memcached::Fast->new(...)

B<Required>. This option used and should be instance of L<Cache::Memcached::Fast>
object. All options of memcached specific features should be
defined by creation of L<Cache::Memcached::Fast> instance.

=item namespace

Example:

    namespace => 'log_1:'

B<Optional>. This namespace will be used into inside L</log> & L</read_all>
methods and restored from outside. If not defined the namespace will be as
I<logger:>. To see L<Cache::Memcached::Fast/namespace> in details.

=back

=head1 METHODS

=over

=item log( $log_item )

C<$log_item> cab be scalar, hashref or arrayref. It's serialized by
L<Cache::Memcached::Fast>.

=item read_all( $cb )

C<$cb> is callback function (parser of one log item). It is called (by this way
C<< $cb->( $log_item ) >>) for every item of log item written to memcached. This
function should return C<true> for continuation of parsing process (a log item
will be deleted from cache) and C<false> if callback wants to terminate a log
reading proccess (a log item will not be deleted from cache so one will be read
in next C<read_all> again. It feature can be used for catching I<TERM> signal
for termination for example). This method is executed up to full reading process
of log items from memcached.

=back

=head1 NOTES

This module uses a following keys for log items (in C<namespace> defined through
same option): I<log_counter> & I<log_N>, where N is positive number from 0 to
max integer of perl. After non-terminated <L/read_all> process a C<log_counter>
will be reseted to "0" (other processes will log from "0" again).

head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>, 2012 year

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.
