#!/usr/bin/env perl
# PODNAME: inst-abbr-ids.pl
# ABSTRACT: Abbreviate seq ids in FASTA files

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:seqids);
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';

# TODO: make things more souple
# perl -nle 'if ( ($prot,$gca) = m/^>(\S+).*:(GC[AF]_[^:]+)/ ) { print q{>} . $gca . q{|} . $prot } else { print }' hexa-900-p-a_prot_cplt.fa > hexa-900-p-a_prot_cplt_abbr2.fa

# regexes for capturing unique identifier component
my %regex_for = (
    ':DEF' => $DEF_ID,
    ':GI'  =>  $GI_ID,
    ':GNL' => $GNL_ID,
    ':JGI' => $JGI_ID,
    ':PAC' => $PAC_ID,
);

my $regex = $regex_for{$ARGV_id_regex} // $ARGV_id_regex;
### Using seq id regex: $regex

# build optional output dir
my $dir = q{.};
if ($ARGV_outdir) {
    $dir = dir($ARGV_outdir)->relative;
    $dir->mkpath();
}

# load optional prefix mapper file
my $prefix_mapper;
if ($ARGV_id_prefix_mapper) {
    ### Taking prefixes from: $ARGV_id_prefix_mapper
    $prefix_mapper = IdMapper->load($ARGV_id_prefix_mapper);
}

my $prefix;     # global variable that will be updated for each infile

my $abbrid_filter = sub {
    my $seq = shift;
    my $long_id = $seq->full_id;

    # abbreviate seq_id (using code from Roles::Listable::regex_mapper)
    # TODO: refactor in module
    my @ids = $long_id =~ $regex;               # capture original id(s)
    s{$NOID_CHARS}{_}xmsg for @ids;             # substitute forbidden chars
    my $abbr_id = join q{}, $prefix, @ids;

    # store allowed seqs (optonally unwrapped)
    # TODO: refactor in module
    my $width = $seq->seq_len;
    my $chunk = $ARGV_nowrap ? $width : 60;     # optionally disable wrap

    my $str = '>' . $abbr_id . "\n";            # use abbreviated seq_id
    for (my $site = 0; $site < $width; $site += $chunk) {
        $str .= $seq->edit_seq($site, $chunk) . "\n";
    }

    return $str;
};

for my $infile (@ARGV_infiles) {

    ### Processing: $infile

    # determine seq_id prefix
    $prefix = $ARGV_id_prefix // q{};           # defaults to no prefix
    if ($prefix_mapper) {                       # infile paths are ignored
        my ($filename) = fileparse($infile);
        $prefix .= $prefix_mapper->abbr_id_for($filename);
    }
    ### Prefixing seq ids with: $prefix
    $prefix .= '|';

    my $outfile = secure_outfile( file($dir, $infile), '-abbr');

    Ali->instant_store(
        $outfile, { infile => $infile, coderef => $abbrid_filter }
    );
}

__END__

=pod

=head1 NAME

inst-abbr-ids.pl - Abbreviate seq ids in FASTA files

=head1 VERSION

version 0.202310

=head1 USAGE

    inst-abbr-ids.pl <infiles> --id-regex=<str> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --id-regex=<str>

Regular expression for capturing the original seq id.

The argument value can be either a predefined regex or a custom regex given
on the command line (do not forget to escape the special chars then). The
following predefined regexes are available (assuming a leading '>'):

    - :DEF (first stretch of non-whitespace chars)
    - :GI  (number nnn in  gi|nnn|...)
    - :GNL (string xxx in gnl|yyy|xxx)
    - :JGI (number nnn in jgi|xxx|nnn or jgi|xxx|nnn|yyy)
    - :PAC (number nnn in xxx|PACid:nnn)

=for Euclid: str.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --outdir=<dir>

Optional output dir that will contain the abbreviated FASTA files (will be
created if needed) [default: none]. Otherwise, output file are in the same
directory as input files.

=for Euclid: dir.type: writable

=item --id-prefix-mapper=<file>

Path to an optional IDM file explicitly listing the infile => prefix pairs.
Useful in the context of processing multiple input files. This argument and
the next one (C<--id-prefix>) can be both specified together. In such a case,
however, a single pipe char is appended to the combined prefix.

=for Euclid: file.type: readable

=item --id-prefix=<str>

String to use as the seq id prefix (e.g., NCBI taxon id, 4-letter code)
[default: none].

=for Euclid: str.type: string

=item --[no]wrap

[Don't] wrap sequences [default: yes].

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
