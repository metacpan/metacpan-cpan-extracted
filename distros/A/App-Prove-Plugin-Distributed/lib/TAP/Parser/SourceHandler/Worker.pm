package TAP::Parser::SourceHandler::Worker;

use strict;
use Getopt::Long;
use Sys::Hostname;
use IO::Socket::INET;
use IO::Select;

use vars (qw($VERSION @ISA));

use TAP::Parser::SourceHandler                ();
use TAP::Parser::IteratorFactory              ();
use TAP::Parser::Iterator::Worker             ();
use TAP::Parser::SourceHandler::Perl          ();
use TAP::Parser::Iterator::Stream::Selectable ();
@ISA = 'TAP::Parser::SourceHandler';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::Worker - Stream TAP from an L<IO::Handle> or a GLOB.

=head1 VERSION

Version 0.08

=cut

$VERSION = '0.08';

=head3 C<@workers>

Class static variable to keep track of workers. 

=cut 

my @workers = ();

=head3 C<$number_of_workers>

Class static variable to keep track of number of workers. 

=cut 

my $number_of_workers;

=head3 C<$listener>

Class static variable to store the worker listener. 

=cut 

my $listener;

=head3 C<$use_local_public_ip>

Class static variable to flag the local public ip is needed.
Some of the home network might not have name server setup.  Therefore,
the public local ip is needed. 

=cut 

my $use_local_public_ip;

=head3 C<$local_public_ip>

Class static variable to store the local public ip is needed.
Some of the home network might not have name server setup.  Therefore,
the public local ip is needed. 

=cut 

my $local_public_ip;

=head3 C<$sync_type>

Syncronize the source directory that will be used for testing to the remote
host with the directory specified on the variable C<$destination_dir>.

Currently it only support syncronize type of C<rsync>.

=cut 

my $sync_type;

=head3 C<$destination_dir>

Syncronize the source to destination directory.

If it is not specified, it will be created with L<File::Temp::tempdir>.

=cut 

my $destination_dir;

=head3 C<can_handle>

  my $vote = $class->can_handle( $source );

Casts the following votes:

  Vote the same way as the L<TAP::Parser::SourceHandler::Perl> 
  but with 0.01 higher than perl source.

=cut

sub can_handle {
    my ( $class, $src ) = @_;
    my $vote = TAP::Parser::SourceHandler::Perl->can_handle($src);
    return 0 unless ($vote);
    if ( $src->{config} ) {
        my @config_keys = keys %{ $src->{config} };
        if ( scalar(@config_keys) == 1 ) {

            #LSF: If it is detach, we just run everythings.
            if ( $src->{config}->{ $config_keys[0] }->{detach} ) {
                $vote = 0.90;
            }
        }
    }

    #LSF: If it is a subclass, we will add 0.01 for each level of subclass.
    my $package = __PACKAGE__;
    my $tmp     = $class;
    $tmp =~ s/^$package//;
    my @number = split '::', $tmp;

    return $vote + ( 1 + scalar(@number) ) * 0.01;
}

=head1 SYNOPSIS

=cut

=head3 C<make_iterator>

  my $iterator = $class->make_iterator( $source );

Returns a new L<TAP::Parser::Iterator::Stream::Selectable> for the source.

=cut

sub make_iterator {
    my ( $class, $source, $retry ) = @_;

    my $worker = $class->get_a_worker($source);

    if ($worker) {
        $worker->autoflush(1);
        $worker->print( ${ $source->raw } . "\n" );
        return TAP::Parser::Iterator::Stream::Selectable->new(
            { handle => $worker } );
    }
    elsif ( !$retry ) {

        #LSF: Let check the worker.
        my @active_workers = $class->get_active_workers();

        #unless(@active_workers) {
        #   die "failed to find any worker.\n";
        #}
        @workers = @active_workers;

        #LSF: Retry one more time.
        return $class->make_iterator( $source, 1 );
    }

    #LSF: Pass through everything now.
    return;
}

=head3 C<get_a_worker>

  my $worker = $class->get_a_worker();

Returns a new workder L<IO::Socket>

=cut

sub get_a_worker {
    my $class   = shift;
    my $source  = shift;
    my $package = __PACKAGE__;
    my $tmp     = $class;
    $tmp =~ s/^$package//;
    my $option_name = 'Worker' . $tmp;
    $number_of_workers = $source->{config}->{$option_name}->{number_of_workers}
      || 1;
    my $startup         = $source->{config}->{$option_name}->{start_up};
    my $teardown        = $source->{config}->{$option_name}->{tear_down};
    my $error_log       = $source->{config}->{$option_name}->{error_log};
    my $detach          = $source->{config}->{$option_name}->{detach};
    my $sync_type       = $source->{config}->{$option_name}->{sync_type};
    my $source_dir      = $source->{config}->{$option_name}->{source_dir};
    my $destination_dir = $source->{config}->{$option_name}->{destination_dir};
    my %args            = ();
    $args{start_up}        = $startup             if ($startup);
    $args{tear_down}       = $teardown            if ($teardown);
    $args{detach}          = $detach              if ($detach);
    $args{sync_type}       = $sync_type           if ($sync_type);
    $args{source_dir}      = $source_dir          if ($source_dir);
    $args{destination_dir} = $destination_dir     if ($destination_dir);
    $args{error_log}       = $error_log           if ($error_log);
    $args{switches}        = $source->{switches};
    $args{test_args}       = $source->{test_args} if ( $source->{test_args} );

    if ( @workers < $number_of_workers ) {
        my $listener = $class->listener;
        if ( $use_local_public_ip && !$local_public_ip ) {
            require Net::Address::IP::Local;
            $local_public_ip = Net::Address::IP::Local->public;
        }

        my $spec = (
            $local_public_ip
              || (
                $listener->sockhost eq '0.0.0.0'
                ? hostname
                : $listener->sockhost
              )
          )
          . ':'
          . $listener->sockport;
        my $iterator_class = $class->iterator_class;
        eval "use $iterator_class;";
        $args{spec} = $spec;
        my $iterator = $class->iterator_class->new( \%args );
        push @workers, $iterator;
    }
    return $listener->accept();
}

=head3 C<listener>

  my $listener = $class->listener();

Returns worker listener L<IO::Socket::INET>

=cut

sub listener {
    my $class = shift;
    unless ($listener) {
        $listener = IO::Socket::INET->new(
            Listen  => 5,
            Proto   => 'tcp',
            Timeout => 40,
        );
    }
    return $listener;
}

=head3 C<iterator_class>

The class of iterator to use, override if you're sub-classing.  Defaults
to L<TAP::Parser::Iterator::Worker>.

=cut

use constant iterator_class => 'TAP::Parser::Iterator::Worker';

=head3 C<workers>

Returns list of workers.

=cut

sub workers {
    return @workers;
}

=head3 C<get_active_workers>
  
  my @active_workers = $class->get_active_workers;

Returns list of active workers.

=cut

sub get_active_workers {
    my $class   = shift;
    my @workers = $class->workers;
    return unless (@workers);
    my @active;
    for my $worker (@workers) {
        next unless ( $worker && $worker->{sel} );
        my @handles = $worker->{sel}->can_read();
        for my $handle (@handles) {
            if ( $handle == $worker->{err} ) {
                my $error = '';
                if ( $handle->read( $error, 640000 ) ) {
                    chomp($error);
                    print STDERR "Worker with error [$error].\n";

                    #LSF: Close the handle.
                    $handle->close();
                    $worker = undef;
                    last;
                }
            }
        }
        push @active, $worker if ($worker);
    }
    return @active;
}

=head3 C<load_options>
  
Setup the worker specific options.

  my @active_workers = $class->load_options($app_prove_object, \@ARGV);

Returns boolean.

=cut

sub load_options {
    my $class = shift;
    my ( $app, $args ) = @_;
    {
        local @ARGV = @$args;
        Getopt::Long::Configure(qw(no_ignore_case bundling pass_through));

        # Don't add coderefs to GetOptions
        GetOptions(
            'use-local-public-ip' => \$use_local_public_ip,
            'sync-test-env=s'     => \$sync_type,
            'destination-dir=s'   => \$destination_dir
        ) or croak('Unable to continue');
        if ($sync_type) {
            if ( $sync_type eq 'rsync' ) {
                require File::Rsync;
                unless ($destination_dir) {
                    require File::Temp;
                    $destination_dir = File::Temp::tempdir( CLEANUP => 1 );
                }

                #LSF: This might not support with different directory separator.
                unless ( $destination_dir =~ /\/$/ ) {
                    $destination_dir .= '/';
                }
            }
            else {
                die "not able to sync on the remote with type "
                  . $sync_type
                  . ".\nCurrently, only the rsync type is supported.\n";
            }
        }
    }
    return 1;
}

1;

__END__

##############################################################################
