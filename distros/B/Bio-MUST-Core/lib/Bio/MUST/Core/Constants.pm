package Bio::MUST::Core::Constants;
# ABSTRACT: Distribution-wide constants for Bio::MUST::Core
$Bio::MUST::Core::Constants::VERSION = '0.251810';
use strict;
use warnings;

use Const::Fast;

use Exporter::Easy (
    OK   => [ qw(:seqtypes :gaps :ncbi :seqids :files) ],
    TAGS => [
        seqtypes => [ qw($PROTLIKE $RNALIKE $NONPUREDNA) ],
        gaps     => [ qw($GAP    $PROTMISS $DNAMISS
                              $GAPPROTMISS $GAPDNAMISS $FRAMESHIFT) ],
        ncbi     => [ qw($NCBIPART $NCBIACC  $NCBIDBABBR
                         $NCBIPKEY $PKEYONLY $NCBIGCA $GCAONLY) ],
        seqids   => [ qw($NOID_CHARS $NEW_TAG $TAIL_42
                         $DEF_ID $GI_ID $LCL_ID $GNL_ID $JGI_ID $PAC_ID) ],
        files    => [ qw($EMPTY_LINE $COMMENT_LINE $DEF_LINE
                         $DIM_LINE $PHY_LINE
                         $STK_COMMENT $STK_SEQ $END_LINE
                         $COUNT_LINE $ALI_SUFFIX) ],
        dirs     => [ qw(%SUFFICES_FOR) ],
    ],
);


# regexes for determining sequence type
const our $PROTLIKE      => qr{[EFILPQefilpq]}xms;
const our $RNALIKE       => qr{[Uu]}xms;
const our $NONPUREDNA    => qr{[^ACGTacgt]}xms;

# regexes for gap and missing symbols
# see also Bio::MUST::Core::Types for "more" gaps
# Note the 2-step definition of char classes for maximal regex speed
const my  $GAPCHCL       => q{\*\-\ };
const my  $PROTMISSCHCL  => q{\?Xx};
const my  $DNAMISSCHCL   => q{\?XxNn};
const my  $PROTAMBIGCHCL => q{BJOUZbjouz};  # O/U actually are not ambiguous...
const my  $DNAAMBIGCHCL  => q{BDHKMRSVWYbdhkmrsvwy};

const our $GAP           => qr{[$GAPCHCL]}xms;
const our $PROTMISS      => qr{[$PROTMISSCHCL$PROTAMBIGCHCL]}xms;
const our $DNAMISS       => qr{[$DNAMISSCHCL$DNAAMBIGCHCL]}xms;

const our $GAPPROTMISS   => qr{[$GAPCHCL$PROTMISSCHCL$PROTAMBIGCHCL]}xms;
const our $GAPDNAMISS    => qr{[$GAPCHCL$DNAMISSCHCL$DNAAMBIGCHCL]}xms;

const our $FRAMESHIFT    => 'x';

# regexes for NCBI id components
const our $NCBIPART      => qr{[^\|\s]+}xms;
const our $NCBIACC       => qr{[A-Z0-9\.\_]+}xms;
const our $NCBIDBABBR    => qr{[a-z]{2,}}xms;
const our $NCBIPKEY      => qr{[1-9]\d*}xms;

const our $PKEYONLY      => qr{\A $NCBIPKEY \z}xms;

# http://www.ncbi.nlm.nih.gov/assembly/model/
# The assembly accession starts with a three letter prefix, GCA for GenBank
# assemblies and GCF for RefSeq assemblies. This is followed by an underscore
# and 9 digits. A version is then added to the accession. For example, the
# assembly accession for the GenBank version of the current public human
# reference assembly ( GRCh37.p2 ) is GCA_000001405.3.

const our $NCBIGCA       => qr{GC[AF]_\d{9} \. \d+}xms;
const our $GCAONLY       => qr{\A $NCBIGCA \z}xms;

# regexes for parsing seq_ids
const our $NOID_CHARS    => qr{[,;:]}xms;
const our $NEW_TAG       => qr{\#NEW\#}xms;
const our $TAIL_42       => qr{(?: \.H\d+\.\d+ | \.E\.bf | \.E\.lc) $NEW_TAG? \z}xms;
const our $DEF_ID        => qr{\A (\S+) }xms;
const our $GI_ID         => qr{\A  gi \| ($NCBIPKEY) }xms;
const our $LCL_ID        => qr{\A lcl \| (\S+) }xms;
const our $GNL_ID        => qr{\A gnl \|  $NCBIPART \| ($NCBIPART) }xms;
const our $JGI_ID        => qr{\A jgi \|  $NCBIPART \| (\d+)       }xms;
const our $PAC_ID        => qr{\| PACid: (\d+) }xms;

# regexes for parsing files

# common
const our $EMPTY_LINE    => qr{\A \s* \z}xms;
const our $COMMENT_LINE  => qr{\A (\#)\s*(.*)}xms;

# FASTA-like
const our $DEF_LINE      => qr{\A >(.*)}xms;

# PHYLIP-related
const our $DIM_LINE      => qr{\A \s*(\d+)\s+(\d+)\s* \z}xms;
const our $PHY_LINE      => qr{\A (?:(\S+)\s)? \s* (.*) }xms;

# STOCKHOLM-related
const our $STK_COMMENT   => qr{\A (\#=GF)\s*(.*)}xms;
const our $STK_SEQ       => qr{\A (\S+)\s+(.*)}xms;
const our $END_LINE      => qr{\A //}xms;

# MUST-related
const our $COUNT_LINE    => qr{\A (\d+) \z}xms;
const our $ALI_SUFFIX    => qr{\.ali \z}xmsi;

# regexes for traversing directories
# Note: hash values correspond to -name arg in File::Find::Rule constructor

const our %SUFFICES_FOR => (
    Ali  => qr{\. (?: ali|fasta|fas|fa|faa|fna ) \z}xmsi,
    Tree => qr{\. (?: arb|nexus|nex|treefile|tree|tre ) \z}xmsi,
);

1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Constants - Distribution-wide constants for Bio::MUST::Core

=head1 VERSION

version 0.251810

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
