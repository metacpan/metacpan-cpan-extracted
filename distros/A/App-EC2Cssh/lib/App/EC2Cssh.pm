package App::EC2Cssh;
$App::EC2Cssh::VERSION = '0.007';
use Moose;

=head1 NAME

App::EC2Cssh - Package for ec2-cssh CLI application

=head1 SYNOSPSIS

See L<ec2-cssh>

=cut

use autodie qw/:all/;
use Cwd;
use File::Spec;
use IO::Socket::SSL;
use Net::Amazon::EC2;
use Safe;
use Text::Template;

use IO::Pipe;
use AnyEvent;

use Log::Any qw/$log/;

# Config stuff.
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);
has 'config_file' => ( is => 'ro' , isa => 'Maybe[Str]');
has 'config_files' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);

# Run options stuff
has 'set' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'demux_command' => ( is => 'ro', isa => 'Maybe[Str]', required => 0, predicate => 'has_demux_command' );

# Operational stuff.
has 'ec2' => ( is => 'ro', isa => 'Net::Amazon::EC2', lazy_build => 1);


sub _build_config{
    my ($self) = @_;
    my $config = {};
    foreach my $file (reverse  @{$self->config_files()} ){
        $log->info("Loading $file..");
        my $file_config =  do $file;

        my $ec2_config = { %{ $config->{ec2_config} || {} } , %{ $file_config->{ec2_config} || {} } };
        my $ec2_sets   = { %{ $config->{ec2_sets} || {} } , %{ $file_config->{ec2_sets} || {} } };
        $config = { %{$config} , %{$file_config} , 'ec2_config' => $ec2_config , ec2_sets => $ec2_sets };
    }

    $log->info("Available sets: " .( join(', ', sort keys %{$config->{ec2_sets}})));
    return $config;
}

sub _build_config_files{
    my ($self) = @_;
    my @candidates = (
        ( $self->config_file() ? $self->config_file() : () ),
        File::Spec->catfile( getcwd() , '.ec2cssh.conf' ),
        File::Spec->catfile( $ENV{HOME} , '.ec2cssh.conf' ),
        File::Spec->catfile( '/' , 'etc' , 'ec2ssh.conf' )
      );
    my @files = ();
    foreach my $candidate ( @candidates ){
        if( -r $candidate ){
            $log->info("Found config file '$candidate'");
            push @files , $candidate;
        }
    }
    unless( @files ){
        die "Cannot find any config files amongst ".join(', ' , @candidates )."\n";
    }
    return \@files;
}

sub _build_ec2{
    my ($self) = @_;

    # Hack so we never verify Amazon's host. Whilst still keeping HTTPS
    IO::Socket::SSL::set_defaults( SSL_verify_callback => sub{ return 1; } );
    my $ec2 =  Net::Amazon::EC2->new({ %{ $self->config()->{ec2_config} || die "No ec2_config in config\n" } , ssl => 1 } );
    return $ec2;
}

sub main{
    my ($self) = @_;

    my @hosts;
    my %hostnames = ();
    $log->info("Listing instances for set='".$self->set()."'");

    my $set_config = {};
    if( $self->set() ){
        $set_config = $self->config()->{ec2_sets}->{$self->set()} || die "No ec2_set '".$self->set()."' defined in config\n";
    }

    my $reservation_infos = $self->ec2->describe_instances( %{ $set_config } ) ;
    foreach my $ri ( @$reservation_infos ){
        my $instances = $ri->instances_set();
        foreach my $instance ( @$instances ){
            my $host =  $instance->dns_name();
            unless( $host ){
                $log->warn("Instance ".$instance->instance_id()." does not have a dns_name. Skipping");
                next;
            }
            $log->debug("Adding host $host");
            push @hosts  , $host;

            if( my $tagset = $instance->tag_set() ){
                foreach my $tag ( @$tagset ){
                    $log->trace("Host has tag: ".$tag->key().':'.( $tag->value() // 'UNDEF' ));
                    if( $tag->key() eq 'Name' ){
                        $log->debug("Host $host name is ".$tag->value());
                        $hostnames{$host} = $tag->value();
                    }
                }
            }
        }
    }

    $log->info("Got ".scalar( @hosts )." hosts");
    if( $self->has_demux_command() ){
        return $self->do_demux_command( \@hosts , \%hostnames );
    }

    # No demux command, just carry on using the configured command for multiple hosts.
    my $tmpl = Text::Template->new( TYPE => 'STRING',
                                    SOURCE => $self->config()->{command} || die "Missing command in config\n"
                                );
    unless( $tmpl->compile() ){
        die "Cannot compile template from '".$self->config()->{command}."' ERROR:".$Text::Template::ERROR."\n";
    }

    my $command = $tmpl->fill_in( SAFE => Safe->new(),
                                  HASH => {
                                      hosts => \@hosts,
                                      hostnames => \%hostnames,
                                  }
                              );
    $log->info("Will do '".substr($command, 0, 80)."..'");
    if( $log->is_debug() ){
        $log->debug($command);
    }
    my $sys_return = system( $command );
    $log->info("Done (returned $sys_return)");
    return $sys_return;
}

$| = 1;

sub do_demux_command{
    my ($self, $hosts, $hostnames) = @_;

    $log->info("Will do ".$self->demux_command()." on each of the hosts");

    my $tmpl = Text::Template->new( TYPE => 'STRING',
                                    SOURCE => $self->demux_command() );

    my @finished = ();
    foreach my $host ( @$hosts ){
        my $hostname = $hostnames->{$host};
        my $command = $tmpl->fill_in( HASH => { host => $host , hostname => $hostname } );
        $log->debug("Will do ".$command);
        my $io_h = IO::Pipe->new()->reader( $command );
        my $w;
        my $toprint = $hostname || $host;
        my $finished = AnyEvent->condvar();
        push @finished , $finished;
        $w = AnyEvent->io( fh => $io_h,
                           poll => 'r',
                           cb => sub{
                               my $line = <$io_h>;
                               unless( $line ){
                                   undef $w;
                                   $finished->send();
                                   return;
                               }
                               print "$toprint: ".$line;
                           });
    }

    map{ $_->recv() } @finished;
    return 0;
}

__PACKAGE__->meta->make_immutable();
