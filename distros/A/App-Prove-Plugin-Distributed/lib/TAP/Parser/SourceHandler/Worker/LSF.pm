package TAP::Parser::SourceHandler::Worker::LSF;

use strict;
use vars (qw($VERSION @ISA));

use TAP::Parser::IteratorFactory       ();
use TAP::Parser::SourceHandler::Worker ();
@ISA = 'TAP::Parser::SourceHandler::Worker';

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head1 NAME

TAP::Parser::SourceHandler::Worker::LSF - Stream TAP from an L<IO::Handle> or a GLOB.

=head1 VERSION

Version 0.01

=cut

$VERSION = '0.01';

use constant iterator_class => 'TAP::Parser::Iterator::Worker::LSF';

=head3 C<get_active_workers>
  
  my @active_workers = $class->get_active_workers;

Returns list of active workers.

=cut

sub get_active_workers {
    my $class = shift;

    my @workers = $class->SUPER::get_active_workers;

    return unless (@workers);
    my @active;
    for my $worker (@workers) {
        if ( $worker->{lsf_job_id} ) {
            my @info = `bjobs $worker->{lsf_job_id}`;
            unless ( $info[1] && $info[1] =~ /\s+(RUN|PEND)\s+/ ) {
                $worker = undef;
                next;
            }
        }
        push @active, $worker if ($worker);
    }
    return @active;
}

END {
    for my $worker ( __PACKAGE__->workers ) {
        next unless ( $worker && $worker->{lsf_job_id} );
        my $command = 'bkill ' . $worker->{lsf_job_id};
        print join "\n", map { '#' . $_ } split /\n/, `$command`;
        print "\n";
    }
}

1;

__END__

##############################################################################
