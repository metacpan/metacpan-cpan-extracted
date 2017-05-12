package Daemon::Shutdown::Monitor::transmission;

# ABSTRACT: Daemon::Shutdown monitor plugin which checks for active transmission downloads

use warnings;
use strict;
use Params::Validate qw/:all/;
use Transmission::Client;
use Regexp::Common qw/URI/;
use Try::Tiny;
use YAML::Any;
use Log::Log4perl;
use Readonly;

Readonly my $TM_STATUS_DOWNLOADING => 4;
Readonly my $TM_STATUS_SEEDING     => 8;

sub new {
    my $class  = shift;
    my %params = @_;

    # Validate the config file
    %params = validate_with(
        params => \%params,
        spec   => {
            loop_sleep => {
                regex   => qr/^\d*$/,
                default => 60,
            },
            trigger_time => {
                regex   => qr/^\d*$/,
                default => 3600,
            },
            count_seeding => {
                type    => BOOLEAN,
                default => 0,
            },
            url => {
                regex   => qr/$RE{URI}{HTTP}{-scheme => 'https?'}/,
                default => 'http://localhost:9091/transmission/rpc',
            },
            username => {
                type    => SCALAR,
                default => '',
            },
            password => {
                type    => SCALAR,
                default => '',
            },
        },
    );
    my $self = {};
    $self->{params} = \%params;

    $self->{trigger_pending} = 0;

    bless $self, $class;
    my $logger = Log::Log4perl->get_logger();
    $self->{logger} = $logger;
    $logger->debug( "Monitor transmission params:\n" . Dump( \%params ) );

    $self->{client} = $self->_init_tm;

    return $self;
}

sub _init_tm {
    my $self = shift;

    my $client;

    my %tm_opts = (
        autodie  => 1,
        url      => $self->{params}->{url},
        username => $self->{params}->{username},
        password => $self->{params}->{password},
    );

    try {
        $client = Transmission::Client->new( %tm_opts );
    }
    catch {
        $self->{logger}->fatal( 'Monitor transmission: ' . $client->error );
    };

    return $client;
}

sub run {
    my $self = shift;

    my $torrents;
    my $conditions_met = 1;
    my $logger         = $self->{logger};

    $logger->info( 'Monitor started running: transmission' );

    try {
        $logger->debug( 'Monitor transmission: checking for active downloads' );
        $torrents = $self->{client}->read_torrents;
    }
    catch {
        $logger->fatal( 'Monitor transmission: ' . $self->{client}->error );
    };

    return 0 unless defined $torrents;

    # we only need one active download (optionally seed)
    foreach my $torrent ( @{$torrents} ) {
        if ( ( $self->{params}->{count_seeding} && $torrent->status == $TM_STATUS_SEEDING )
            || $torrent->status == $TM_STATUS_DOWNLOADING )
        {
            $logger->debug( 'Monitor transmission sees active torrents' );
            $conditions_met = 0;
            last;
        }
    }

    # TODO - REFACTOR ME - this block is basically the same in each monitor
    if ( $conditions_met ) {
        $self->{trigger_pending} = $self->{trigger_pending} || time();

        if ( $self->{trigger_pending}
            and ( time() - $self->{trigger_pending} ) >= $self->{params}->{trigger_time} )
        {

            # ... and the trigger was set, and time has run out: time to return!
            $logger->info( "Monitor transmission trigger time reached after $self->{params}->{trigger_time}" );
            return 1;
        }

        $logger->info( "Monitor transmission found no active downloads: trigger pending." );

    } else {
        if ( $self->{trigger_pending} ) {
            $logger->info( "Monitor transmission trigger time being reset due to new active torrents" );
        }

        # Conditions not met - reset the trigger incase it was previously set.
        $self->{trigger_pending} = 0;
    }

    return 0;
}

1;

__END__

=head3 Example configuration
 
monitor:
  transmission:
    trigger_time: 1800
    loop_sleep: 360
    count_seeding: 1
    url: http://localhost:9091
    username: rpcusername
    password: rpcpassword
=cut
