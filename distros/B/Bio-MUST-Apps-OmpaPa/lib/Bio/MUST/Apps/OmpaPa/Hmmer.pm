package Bio::MUST::Apps::OmpaPa::Hmmer;
# ABSTRACT: internal class for tabular HMMER parser
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Apps::OmpaPa::Hmmer::VERSION = '0.251770';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use List::AllUtils qw(mesh);

extends 'Bio::FastParsers::Hmmer::DomTable';
with 'Bio::MUST::Apps::OmpaPa::Roles::Parsable';


sub collect_hits {
    my $self = shift;

    my @hits;

    # parse HMMER report
    while (my $hit = $self->next_hit) {

        if ($hit->rank == 1) {

            # collect useful hit attributes
            push @hits, {
                'acc'       => $hit->target_name,
                'dsc'       => $hit->target_description // 'none',
                'exp'       => $hit->evalue,
                'bit'       => $hit->score,
                'qlen'      => $hit->qlen,
                'len'       => $hit->tlen,
                'hmm_from'  => $hit->hmm_from,
                'hmm_to'    => $hit->hmm_to,
            };
        }
    }

    return \@hits;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::OmpaPa::Hmmer - internal class for tabular HMMER parser

=head1 VERSION

version 0.251770

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
