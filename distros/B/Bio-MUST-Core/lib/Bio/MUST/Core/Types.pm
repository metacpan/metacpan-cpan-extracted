package Bio::MUST::Core::Types;
# ABSTRACT: Distribution-wide Moose types for Bio::MUST::Core
$Bio::MUST::Core::Types::VERSION = '0.251810';
use Moose::Util::TypeConstraints;

use autodie;
use feature qw(say);

use Path::Class qw(dir file);

# declare types without loading corresponding classes
class_type('Bio::MUST::Core::Ali');
class_type('Bio::MUST::Core::Ali::Stash');
class_type('Bio::MUST::Core::IdList');
class_type('Bio::MUST::Core::IdMapper');
class_type('Bio::MUST::Core::SeqId');

# TODO: consider MooseX::Types

# http://www.ebi.ac.uk/2can/tutorials/aa.html

# A Ala   Alanine
# R Arg   Arginine
# N Asn   Asparagine
# D Asp   Aspartic acid
# C Cys   Cysteine
# Q Gln   Glutamine
# E Glu   Glutamic acid
# G Gly   Glycine
# H His   Histidine
# J Xle   Leucine or Isoleucine
# L Leu   Leucine
# I ILe   Isoleucine
# K Lys   Lysine
# M Met   Methionine
# F Phe   Phenylalanine
# P Pro   Proline
# O Pyl   Pyrrolysine
# U Sec   Selenocysteine
# S Ser   Serine
# T Thr   Threonine
# W Trp   Tryptophan
# Y Tyr   Tyrosine
# V Val   Valine
# B Asx   Aspartic acid or Asparagine
# Z Glx   Glutamic acid or Glutamine
# X Xaa   Any amino acid

# IUB Meaning Complement
# A   A       T
# C   C       G
# G   G       C
# T/U T       A
# M   A/C     K
# R   A/G     Y
# W   A/T     W
# S   C/G     S
# Y   C/T     R
# K   G/T     M
# V   A/C/G   B
# H   A/C/T   D
# D   A/G/T   H
# B   C/G/T   V
# X/N A/C/G/T X


# auto-build SeqId instance from bare string
# useful when the SeqId class is used as an attribute in another class
# TODO: check whether it is the best practice
coerce 'Bio::MUST::Core::SeqId'
    => from 'Str'
    => via { Bio::MUST::Core::SeqId->new(full_id => $_) }
;

# auto-build ArrayRef[full_id] from ArrayRef[SeqId] or ArrayRef[Seq]
# useful for IdList and IdMapper objects
subtype 'Bio::MUST::Core::Types::full_ids'
    => as 'ArrayRef[Str]';

coerce 'Bio::MUST::Core::Types::full_ids'
    => from 'ArrayRef[Bio::MUST::Core::SeqId]'
    => via { [ map { $_->full_id } @{$_} ] }

    => from 'ArrayRef[Bio::MUST::Core::Seq]'
    => via { [ map { $_->full_id } @{$_} ] }
;

# quite tolerant subtype designed to preserve original casing
# however FASTA '-' symbols are converted to ALI '*' (and MACSE's '!' to 'x')
# during coercion whereas spaces and '?' are left untouched
# Note: \A are \z are absolutely required for converting hard-wrapped seqs
subtype 'Bio::MUST::Core::Types::Seq'
    => as 'Str'
    => where { m{\A [\*\ A-Za-z\?]* \z}xms }
    => message { 'Only IUPAC codes and gaps [*-<space>?] are allowed.' }
;

coerce 'Bio::MUST::Core::Types::Seq'
    => from 'Str'
    => via { tr|-!\n|*x|dr }        # convert FASTA on the fly
;                                   # ('-' => '*', '!' => 'x' and delete \n)

# subtype for a stringified NCBI Taxonomy lineage
subtype 'Bio::MUST::Core::Types::Lineage'
    => as 'Str'
    => where { tr/;// || m/\A cellular \s organisms/xms || m/\A Viruses/xms
        || m/\A other \s sequences/xms || m/\A unclassified \s sequences/xms }
;

class_type('Path::Class::Dir');
class_type('Path::Class::File');
class_type('File::Temp');

# auto-build Ali/Stash from various source types...
# useful in Bio::MUST::Drivers modules

coerce 'Bio::MUST::Core::Ali'
    => from 'Bio::MUST::Core::Ali::Stash'
    => via { Bio::MUST::Core::Ali->new( seqs => $_->seqs, guessing => 1 ) }

    => from 'ArrayRef[Bio::MUST::Core::Seq]'
    => via { Bio::MUST::Core::Ali->new( seqs => $_,       guessing => 1 ) }

    => from 'Path::Class::File'
    => via { Bio::MUST::Core::Ali->load( $_->stringify ) }

    => from 'Str'
    => via { Bio::MUST::Core::Ali->load( $_ ) }
;

coerce 'Bio::MUST::Core::Ali::Stash'
    => from 'Path::Class::File'
    => via { Bio::MUST::Core::Ali::Stash->load( $_->stringify ) }

    => from 'Str'
    => via { Bio::MUST::Core::Ali::Stash->load( $_ ) }
;

coerce 'Bio::MUST::Core::IdList'
    => from 'ArrayRef[Str]'
    => via { Bio::MUST::Core::IdList->new( ids => $_ ) }

    => from 'ArrayRef[Bio::MUST::Core::SeqId]'
    => via { Bio::MUST::Core::IdList->new(
        ids => [ map { $_->full_id } @{$_} ]
    ) }

    => from 'ArrayRef[Bio::MUST::Core::Seq]'
    => via { Bio::MUST::Core::IdList->new(
        ids => [ map { $_->full_id } @{$_} ]
    ) }

    => from 'Path::Class::File'
    => via { Bio::MUST::Core::IdList->load( $_->stringify ) }

    => from 'Str'
    => via { Bio::MUST::Core::IdList->load( $_ ) }
;

# TODO: add coercion for IdMapper from HashRef[SeqId], HashRef[Seq]?

coerce 'Bio::MUST::Core::IdMapper'
    => from 'HashRef[Str]'
    => via { Bio::MUST::Core::IdMapper->new(
        long_ids => [   keys %{$_} ],
        abbr_ids => [ values %{$_} ],
    ) }

    => from 'Path::Class::File'
    => via { Bio::MUST::Core::IdMapper->load( $_->stringify ) }

    => from 'Str'
    => via { Bio::MUST::Core::IdMapper->load( $_ ) }
;

# TODO: add tests for these coercions? templatize code?

# subtype for 'dir' attributes
subtype 'Bio::MUST::Core::Types::Dir'
    => as 'Path::Class::Dir'
;

# avoid the need for 'isa' unions such as 'Str|Path::Class::Dir'...
# ... and allow fixing '~/' paths on the fly (through glob)
coerce 'Bio::MUST::Core::Types::Dir'
    => from 'Str'
    => via { dir( glob $_ ) }
;

# === in part borrowed from Bio::FastParsers to avoid dependency

# subtype for 'file' attributes
subtype 'Bio::MUST::Core::Types::File'
    => as 'Path::Class::File'
;

# avoid the need for 'isa' unions such as 'Str|Path::Class::File'...
# ... and allow fixing '~/' paths on the fly (through glob)
# ... and allow delegating to Path::Class::File methods (e.g., remove)
coerce 'Bio::MUST::Core::Types::File'
    => from 'File::Temp'                    # useful for Drivers
    => via { file( $_->filename ) }

    => from 'Str'
    => via { file( glob $_ ) }
;

# ===

no Moose::Util::TypeConstraints;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Types - Distribution-wide Moose types for Bio::MUST::Core

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
