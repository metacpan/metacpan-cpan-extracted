package Bio::MUST::Drivers::CdHit;
# ABSTRACT: Bio::MUST driver for running the cd-hit program
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Drivers::CdHit::VERSION = '0.180270';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use IPC::System::Simple qw(system);
use Path::Class qw(file);
use Tie::IxHash;

use Smart::Comments '###';

use Bio::MUST::Core;
extends 'Bio::MUST::Core::Ali::Temporary';

use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::FastParsers::CdHit';


has '_cluster_seq_ids' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Bio::MUST::Core::SeqId]]',
    init_arg => undef,
    writer   => '_set_cluster_seq_ids',
    handles  => {
        all_cluster_names   => 'keys',
        all_cluster_seq_ids => 'values',
        seq_ids_for         => 'get',
    },
);

has '_representatives' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_representatives',
    handles  => {
          all_representatives        =>   'all_seqs',
        count_representatives        => 'count_seqs',
          get_representative_with_id =>   'get_seq_with_id',    # useless?
    },
);

has '_representative_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Core::Seq]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_representative_for',
    handles  => {
        all_member_names   => 'keys',
        representative_for => 'get',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_representative_for {
    my $self = shift;

    my %representative_for;
    for my $repr ( $self->all_cluster_names ) {
        for my $id ( @{ $self->seq_ids_for($repr) } ) {
            $representative_for{ $id->full_id }
                = $self->get_representative_with_id($repr);
        }
    }

    return \%representative_for;
}

## use critic

sub BUILD {
    my $self = shift;

    # setup output files
    my $infile   = $self->filename;
    my $basename = $infile . '.cdhit';
    my $outfile  = $basename . '.out';
    my $outfile_clstr  = $basename . '.out.clstr';

    # TODO: add options if wanted

    # create cd-hit command
    my $pgm = 'cd-hit';
    my $cmd = "$pgm -i $infile -o $outfile > /dev/null 2> /dev/null";

    # try to robustly execute cd-hit
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "Cannot execute $pgm command; returning without contigs!";
        return;
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # parse output file
    my $parser = CdHit->new(file => $outfile_clstr);
    my $mapper = $self->mapper;

    # restore original ids for cluster members...
    tie my %cluster_seq_ids, 'Tie::IxHash';
    for my $abbr_id ( $parser->all_representatives ) {
        my @member_ids = map {
            SeqId->new( full_id => $mapper->long_id_for($_) )
        } @{ $parser->members_for($abbr_id) // [] };
        $cluster_seq_ids{ $mapper->long_id_for($abbr_id) } = \@member_ids;
    }

    # ... and store cluster members
    $self->_set_cluster_seq_ids(\%cluster_seq_ids);

    # read and store representative seqs...
    my $representatives = Ali->load($outfile);
    $representatives->dont_guess;
    $representatives->restore_ids($mapper);     # ... restoring original ids
    $self->_set_representatives($representatives);

    # unlink temp files
    file($_)->remove for $outfile, $outfile_clstr;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::CdHit - Bio::MUST driver for running the cd-hit program

=head1 VERSION

version 0.180270

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
