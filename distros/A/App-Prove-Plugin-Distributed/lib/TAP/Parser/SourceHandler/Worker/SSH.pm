package TAP::Parser::SourceHandler::Worker::SSH;

use strict;
use Getopt::Long;
use Carp;
use vars (qw($VERSION @ISA));

use TAP::Parser::IteratorFactory       ();
use TAP::Parser::SourceHandler::Worker ();
@ISA = 'TAP::Parser::SourceHandler::Worker';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::Worker::SSH - Stream TAP from an L<IO::Handle> or a GLOB.

=head1 VERSION

Version 0.03

=cut

$VERSION = '0.03';

use constant iterator_class => 'TAP::Parser::Iterator::Worker::SSH';

=head3 C<@hosts>

Class static variable to keep track of hosts. 

=cut 

my @hosts;

=head3 C<get_active_workers>
  
  my @active_workers = $class->get_active_workers;

Returns list of active workers.

=cut

sub get_active_workers {
    my $class = shift;

    my @workers = $class->SUPER::get_active_workers;

    return unless (@workers);
    my @active;
    require Net::Ping;
    my $ping = Net::Ping->new();
    for my $worker (@workers) {
        if ( $worker->{host} ) {
            my $status = $ping->ping( $worker->{host} );
            unless ($status) {
                $worker = undef;
                next;
            }
        }
        push @active, $worker if ($worker);
    }
    $ping->close();
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
    croak 'parent failed to load options.' unless($class->SUPER::load_options(@_));
    {
        local @ARGV = @$args;
        Getopt::Long::Configure(qw(no_ignore_case bundling pass_through));

        # Don't add coderefs to GetOptions
        GetOptions( 'hosts=s' => \$app->{hosts}, )
          or croak('Unable to continue');
        @hosts = split /,/, $app->{hosts} if ( $app->{hosts} );
        unless (@hosts) {
            croak(
'No host found. At least one host need to be specified with --hosts option.'
            );
        }
    }
    return 1;
}

=head3 C<get_next_host>
  
Get next hosts.

  my @hosts = $class->get_next_host();

Returns hostname.

=cut

sub get_next_host {
    return unless (@hosts);
    my $host = shift @hosts;
    push @hosts, $host;
    return $host;
}

END {
    for my $worker ( __PACKAGE__->workers ) {
        next unless ( $worker && $worker->{host} );

        #LSF: How to kill the ssh process.
    }
}

1;

__END__

##############################################################################
