package Bio::MUST::Apps::FortyTwo::RunProcessor;
# ABSTRACT: Internal class for forty-two tool
$Bio::MUST::Apps::FortyTwo::RunProcessor::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;                    # logging always enabled here

use Carp;
use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Apps::FortyTwo::AliProcessor';

with 'Bio::MUST::Apps::Roles::RunProcable',
     'Bio::MUST::Core::Roles::Taxable';


has 'run_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'phylogenomic',
);

has '+out_suffix' => (
    default  => '-42',
);


has 'query_orgs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        'count_query_orgs' => 'count',
          'all_query_orgs' => 'elements',
    },
);


# blast_args


has 'ref_brh_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'on',
);

has 'ref_bank_dir' => (
    is       => 'ro',
    isa      => 'Str',
);

has 'ref_org_mapper' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdMapper',
    coerce   => 1,
    handles  => {
        ref_bank_for => 'abbr_id_for',
    },
);

has 'ref_orgs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
    handles  => {
        'count_ref_orgs' => 'count',
          'all_ref_orgs' => 'elements',
    },
);

has 'ref_org_mul' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1.0,
);

has 'ref_score_mul' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1.0,
);


has 'tol_check' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'off',
);

has 'tol_db' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Drivers::Blast::Database',
);

# trimming_mode

# trim_max_shift

# trim_extra_margin


has 'ls_action' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'keep',
);


has 'aligner_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'blast',
);

has 'ali_patch_mode' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'off',
);

has 'ali_cover_mul' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1.1,
);


has 'tax_reports' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'on',
);

# tax_dir

has 'tax_min_hits' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1,
);

has 'tax_max_hits' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 10000,
);

has 'tax_min_ident' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 0,
);

has 'tax_min_len' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 0,
);

has 'tax_min_score' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 0,
);

has 'tax_score_mul' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 0,
);


# bank_dir

# orgs


has '_ref_blastdb_by_org' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Drivers::Blast::Database]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ref_blastdb_by_org',
    handles  => {
        ref_blastdb_for => 'get',
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_ref_blastdb_by_org {
    my $self = shift;

    # tie probably useless here but ensuring reproducible logs
    tie my %ref_blastdb_for, 'Tie::IxHash';

    for my $ref_org ($self->all_ref_orgs) {
        $ref_blastdb_for{$ref_org} = Bio::MUST::Drivers::Blast::Database->new(
            file => file(
                $self->ref_bank_dir,
                $self->ref_bank_for($ref_org)
            )
        );
    }

    return \%ref_blastdb_for;
}

## use critic


sub BUILD {
    my $self = shift;

    unless ($self->ref_brh_mode eq 'off') {
        croak 'Error: ref_bank_dir missing from config file; aborting'
            unless $self->ref_bank_dir;

        croak 'Error: ref_org_mapper missing from config file; aborting'
            unless $self->ref_org_mapper;

        croak 'Error: BLAST databases missing from ref_org_mapper; aborting!'
            if List::AllUtils::any {
                !defined $self->ref_bank_for($_)
            } $self->all_ref_orgs
        ;
    }

    # TODO: revise this but not sure this is really needed

#     if ($self->aligner eq 'off' && $self->run_mode eq 'phylogenomic') {
#         croak 'Error: cannot disable aligner with nucleotide banks; aborting!'
#             if List::AllUtils::any {
#                 $_->{bank_type} eq 'nucl'
#             } $self->all_orgs
#         ;
#     }
#
#     if ($self->aligner =~ m/exonerate|exoblast/xms) {
#         croak 'Error: cannot use exonerate with protein banks; aborting!'
#             if List::AllUtils::any {
#                 $_->{bank_type} eq 'prot'
#             } $self->all_orgs
#         ;
#     }

    for my $infile ($self->all_infiles) {
        ### [RUN] Processing ALI: $infile
        AliProcessor->new(
            run_proc => $self,
            ali      => $infile,
        );
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::FortyTwo::RunProcessor - Internal class for forty-two tool

=head1 VERSION

version 0.190820

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
