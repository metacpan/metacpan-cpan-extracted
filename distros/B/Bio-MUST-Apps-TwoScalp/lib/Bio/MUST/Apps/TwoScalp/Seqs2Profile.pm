package Bio::MUST::Apps::TwoScalp::Seqs2Profile;
# ABSTRACT: internal class for two-scalp tool
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@doct.uliege.be>
$Bio::MUST::Apps::TwoScalp::Seqs2Profile::VERSION = '0.231010';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use List::AllUtils qw(part);

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:gaps);
use Bio::MUST::Core::Utils qw(secure_outfile);

use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Drivers::Blast::Database::Temporary';
use aliased 'Bio::MUST::Drivers::Mafft';
use aliased 'Bio::MUST::Drivers::ClustalO';
use aliased 'Bio::MUST::Apps::SlaveAligner::Local';
use aliased 'Bio::MUST::Core::IdList';


has 'file1' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
);

has 'file2' => (
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
    handles  => qr{.*}xms,
);

has 'options' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);


sub BUILD {
    my $self = shift;

    my $ali1 = $self->file1;
    my $ali2 = $self->file2;
    my $opt  = $self->options;

    my ($filename1, $id_mapper1) = $ali1->temp_fasta( {id_prefix => 'file1-'} );
    my ($filename2, $id_mapper2) = $ali2->temp_fasta( {id_prefix => 'file2-'} );

    my %mapper = ( ali1 => $id_mapper1, ali2 => $id_mapper2 );

    my $mafft = Mafft->new( file => $filename1 );       # add an option to use clustalo if wanted ?
    my $ali_out = $mafft->seqs2profile($filename2, $opt);

    $ali_out->restore_ids($mapper{ali1});
    $ali_out->restore_ids($mapper{ali2});

    $self->_set_ali($ali_out);

    return;
}
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::TwoScalp::Seqs2Profile - internal class for two-scalp tool

=head1 VERSION

version 0.231010

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
