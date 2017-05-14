package Bio::Gonzales::Seq::Filter::ProteinCleaner;
use Bio::Gonzales::Util qw/flatten/;

use Mouse;

use warnings;
use strict;

use 5.010;

our $VERSION = '0.0546'; # VERSION

has no_desc     => ( is => 'rw', default => 1 );
has uncommon_aa => ( is => 'rw', default => 1 );
has end_terminal    => ( is => 'rw', default => 1 );
has terminal    => ( is => 'rw', default => 1 );

sub clean {
    my ( $self, @seq_objs ) = @_;
    my @seqs = flatten(@seq_objs);
    for my $s (@seqs) {

        my $seq = $s->seq;

        $seq =~ tr/*//d if ( $self->terminal );
        $seq =~ s/\*$// if ( $self->end_terminal );
        $seq =~ s/[^*SFTNKYEVZQMCLAOWXPBHDIRGsftnkyevzqmclaowxpbhdirg]/X/ if ( $self->uncommon_aa );
        $s->seq($seq);
        $s->desc('') if ( $self->no_desc );
    }
    return \@seqs;
}

sub BUILD {
    warn "DEPRECATED, use Bio::Gonzales::Seq::Filter";
}

1;

__END__

=head1 NAME

Bio::Gonzales::Seq::Filter::ProteinCleaner - clean protein sequences

=head1 SYNOPSIS

    my $pc = Bio::Gonzales::Seq::Filter::ProteinCleaner->new(no_desc => 1, uncommon_aa => 1, terminal => 1);
    my $seqs = $pc->clean(@seqs)

=head1 DESCRIPTION

Remove or replace strings from protein sequences that usually confuse 3rd party software

=head1 METHODS

=over 4

=item B<< $seqs = $pc->clean(@seqs) >>

Clean the sequences C<@seqs>. Works on the objects.

=back

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
