package BioX::Workflow::WriteMeta;

use Moose::Role;

=head1 BioX::Workflow::WriteMeta

Debug information containing metadata per rule.

Useful for tracking the evolution of an analysis

=head2 Variables

=head3 verbose

Output some more things

=cut

has 'verbose' => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 1,
    clearer   => 'clear_verbose',
    predicate => 'has_verbose',
);

=head3 wait

Print "wait" at the end of each rule

This is useful for running with the HPC::Runner libraries.

=cut

has 'wait' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
    documentation =>
        q(Print 'wait' at the end of each rule. If you are running as a plain bash script you probably don't need this.),
    clearer   => 'clear_wait',
    predicate => 'has_wait',
);

=head2 Subroutines

=cut

sub write_workflow_meta {
    my $self = shift;
    my $type = shift;

    return unless $self->verbose;

    if ( $type eq "start" ) {
        print "$self->{comment_char}\n";
        print "$self->{comment_char} Starting Workflow\n";
        print "$self->{comment_char}\n";
        print "$self->{comment_char}\n";
        print "$self->{comment_char} Global Variables:\n";

        my @keys = $self->global_attr->get_keys();

        foreach my $k (@keys) {
            next unless $k;
            my ($v) = $self->global_attr->get_values($k);
            print "$self->{comment_char}\t$k: " . $v . "\n";
        }
        print "$self->{comment_char}\n";
    }
    elsif ( $type eq "end" ) {
        print "$self->{comment_char}\n";
        print "$self->{comment_char} Ending Workflow\n";
        print "$self->{comment_char}\n";
    }
}

=head2 write_rule_meta

=cut

sub write_rule_meta {
    my ( $self, $meta ) = @_;

    print "\n$self->{comment_char}\n";

    if ( $meta eq "after_meta" ) {
        print "$self->{comment_char} Ending $self->{key}\n";
    }

    print "$self->{comment_char}\n\n";

    return unless $meta eq "before_meta";
    print "$self->{comment_char} Starting $self->{key}\n";
    print "$self->{comment_char}\n\n";

    return unless $self->verbose;

    print "\n\n$self->{comment_char}\n";
    print "$self->{comment_char} Variables \n";
    print "$self->{comment_char} Indir: " . $self->indir . "\n";
    print "$self->{comment_char} Outdir: " . $self->outdir . "\n";

    if ( exists $self->local_rule->{ $self->key }->{local} ) {

        print "$self->{comment_char} Local Variables:\n";

        my @keys = $self->local_attr->get_keys();

        foreach my $k (@keys) {
            my ($v) = $self->local_attr->get_values($k);
            print "$self->{comment_char}\t$k: " . $v . "\n";
        }
    }

    $self->write_sample_meta if $self->resample;

    print "$self->{comment_char}\n\n";
}

1;
