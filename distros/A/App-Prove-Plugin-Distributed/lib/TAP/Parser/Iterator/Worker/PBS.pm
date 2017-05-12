package TAP::Parser::Iterator::Worker::PBS;
use strict;
use PBS::Client;

use TAP::Parser::Iterator::Worker           ();
use TAP::Parser::SourceHandler::Worker::PBS ();

use vars qw($VERSION @ISA);
@ISA = 'TAP::Parser::Iterator::Worker';

# new() implementation supplied by TAP::Object

sub _initialize {
    my ( $self, $args ) = @_;
    return unless ( $args->{spec} );
    $self->{spec}      = $args->{spec};
    $self->{start_up}  = $args->{start_up};
    $self->{tear_down} = $args->{tear_down};
    $self->{error_log} = $args->{error_log};
    $self->{switches}  = $args->{switches};
    $self->{detach}    = $args->{detach};
    $self->{test_args} = $args->{test_args};

$DB::single= 1;
    my %pbs_args = TAP::Parser::SourceHandler::Worker::PBS->get_args;
    my $server   = delete $pbs_args{server};
    my $client   = PBS::Client->new( $server ? ( server => $server ) : () );

    for ( keys %pbs_args ) {
        delete $pbs_args{$_} unless ( defined $pbs_args{$_} );
    }

    # Specify the job
    my $job = PBS::Client::Job->new(
        cmd => $self->initialize_worker_command,
        %pbs_args
    );

    my @job_ids = $client->qsub($job);

    if (@job_ids) {
        $self->{pbs_job_id} = $job_ids[0];
    }
    else {
        print STDERR "failed to start an PBS job.\n";
        return;
    }
    return $self;
}

=head1 NAME

TAP::Parser::Iterator::Worker::PBS - Iterator for PBS worker TAP sources

=head1 VERSION

Version 0.05

=cut

$VERSION = '0.05';

1;

__END__

##############################################################################
