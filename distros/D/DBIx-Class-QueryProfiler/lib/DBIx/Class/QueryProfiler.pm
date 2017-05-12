package DBIx::Class::QueryProfiler;

=head1 NAME

DBIx::Class::QueryProfiler - DBIx::Class profiler

=head1 DESCRIPTION

Profiler for DBIx::Class. Also it provides more usable output or queries.

=head1 SYNOPSYS

In order to start using just declare in your schema the code

    use DBIx::Class::QueryProfiler;

    sub connection {
        my $self = shift;
        my $response = $self->next::method(@_);
        $response->storage->auto_savepoint(1);
        $response->storage->debug(1);
        $response->storage->debugobj(DBIx::Class::QueryProfiler->new);
        return $response;
    }

Possible to use debugfh () to select right output debuging filehandle

    $response->storage->debugfh(IO::File->new('/tmp/trace.out', 'w'));

or it can be set through an environment variable DBIC_TRACE

    export DBIC_TRACE="1=/tmp/trace.out"

=head1 METHODS

=cut

use utf8;
use strict;
use warnings;
use 5.8.9;


use Carp qw(carp cluck);
use Term::ANSIColor;
use parent 'DBIx::Class::Storage::Statistics';

use Time::HiRes qw(time);
use IO::File;

__PACKAGE__->mk_group_accessors('simple' => qw/is_colored/);

our $start;
our $VERSION = 0.05;
our $N = 0;
our %Q;
our $fh;
our %colormap = ( 'SELECT' => 'magenta', 'INSERT' => 'bold yellow', 'UPDATE' => 'bold blue', DELETE => 'bold red' );

sub _c {
    my $self = shift;
    if ( $self->is_colored() ) {
        return color( @_ );
    } else {
        return '';
    }
}


=head2 query_start

Called before a query is executed. The first argument is the SQL string being executed and subsequent arguments are the parameters used for the query.

=cut

sub query_start {
    my $self = shift();
    my $sql = shift();
    my $n = $Q{$sql} ||= ++$N;
    my @params = @_;
    $sql =~ s{\?}{ shift(@params) }sge;
    my ($type) = ( $sql =~ m/^(\w+)/);
    $self->print("Q$n. Executing < ".$self->_c( $colormap{$type}||'magenta' ).$sql.$self->_c('reset')." >".( @params ? ' +['.join(', ', @params).']' : ''));
    $start = time();
}

=head2 query_end

Called when a query finishes executing. Has the same arguments as query_start.

=cut

sub query_end {
    my $self = shift;
    my $sql = shift;
    my $n = delete $Q{$sql} || '-.0';
    my @params = @_;

    my $elapsed = sprintf("%0.4f", time() - $start);
    my $prefix = '';
    my $suffix = '';
    if ( $self->is_colored() ) {
        if ( $elapsed < 0.01 ) {
            $prefix = color 'green';
        } elsif ( $elapsed < 0.1 ) {
            $prefix = color 'yellow', 'bold';
        } else {
            $prefix = color 'red'
        }
        $suffix = color 'reset';
    }    
    $self->print("Q$n. Execution took $prefix$elapsed$suffix seconds.");
    $start = undef;
}

=head2 print

Prints the specified string to our debugging filehandle, which we will attempt to open if we haven't yet.

=cut

sub print {
    my $self = shift;
    my $i = 0;
    my @c;
    while (@c = caller(++$i)) {
        next if $c[0] =~ m{^(?:DBIx::Class|Catalyst|Class::MOP|Moose::Object)};
        next if exists $Carp::Internal{$c[0]};
        last;
    }
    @c = caller(1) unless @c;

    # by default is colored output
    $self->is_colored(1);
    if (-t $self->debugfh()) {
        # Check if we can get trace filename via ENV
        my $debug_env = $ENV{DBIC_TRACE} || undef;
        if (defined($debug_env) && ($debug_env =~ /=(.+)$/)) {
            $fh = IO::File->new($1, 'w') or die "Cannot open trace file $1";
            $self->is_colored(0);
        } 
        else {
            $fh = IO::File->new('>&STDERR')
                or die('Duplication of STDERR for debug output failed (perhaps your STDERR is closed?)');
        }
        $fh->autoflush();
    }
    else {
        $self->is_colored(0);
        $fh = $self->debugfh();
    }
    return print $fh "@_ at $c[1] line $c[2].\n";
}

1;

        

=head1 BUGS

No bugs. Found? Report please :-)

=head1 AUTHORS

Andrey Kostenko <andrey@kostenko.name>, Mons Anderson <mons@cpan.org>

=head1 COMPANY

Rambler Internet Holding

=head1 CREATED

15.04.2009 19:28:45 MSD

=cut

