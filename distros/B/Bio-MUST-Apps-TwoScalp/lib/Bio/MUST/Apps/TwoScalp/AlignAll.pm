package Bio::MUST::Apps::TwoScalp::AlignAll;
# ABSTRACT: internal class for two-scalp tool
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@doct.uliege.be>
$Bio::MUST::Apps::TwoScalp::AlignAll::VERSION = '0.211710';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Bio::MUST::Core;
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Drivers::Mafft';


has 'file' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
);

has 'ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_ali',
#   handles  => qr{.*}xms,     # DO NOT WORK... WHY??
    handles  => [ qw( all_seqs all_seq_ids dont_guess restore_ids
        store_fasta temp_fasta count_seqs has_uniq_ids ) ],
);

has 'options' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);


sub BUILD {
    my $self = shift;

    my $ali1 = $self->file;
    my $opt  = $self->options;

    my ($filename1, $id_mapper1) = $ali1->temp_fasta( {id_prefix => 'file1-'} );

    my $mafft = Mafft->new( file => $filename1 );
    my $ali_out = $mafft->align_all($opt);

    $ali_out->restore_ids($id_mapper1);

    $self->_set_ali($ali_out);

    return;
}
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::TwoScalp::AlignAll - internal class for two-scalp tool

=head1 VERSION

version 0.211710

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Valerian LUPO

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Valerian LUPO <valerian.lupo@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
