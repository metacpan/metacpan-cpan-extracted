#!/usr/bin/env perl
# PODNAME: extract-mcl-out.pl
# ABSTRACT: Extract orthogroups (FASTA files) from MCL clusters

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:files);
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali::Stash';
use aliased 'Bio::MUST::Core::IdList';


my $db = Stash->load($ARGV_database);

for my $infile (@ARGV_infiles) {

    ### Processing: $infile

    # create directory named after filename
    my ($filename) = fileparse($infile, qr{\.[^.]*}xms);
    my $dir = dir($filename)->relative;
    $dir->mkpath();

    # TODO: move this part to some object returning a ordered hash of IdList

    open my $in, '<', $infile;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and other comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;

        # extract id list for current group
        my ($group, @ids) = split /\s+/xms, $line;
        $group =~ s/:\z//xms;           # remove trailing colon (:)
        my $list = IdList->new( ids => \@ids );

        # assemble Ali and store it as FASTA file
        my $ali = $list->reordered_ali($db);
        $ali->dont_guess;
        my $outfile = file($dir, change_suffix($group, '.fasta') )->stringify;
        $ali->store_fasta($outfile);
    }
}

__END__

=pod

=head1 NAME

extract-mcl-out.pl - Extract orthogroups (FASTA files) from MCL clusters

=head1 VERSION

version 0.210170

=head1 USAGE

    extract-mcl-out.pl <infiles> --database=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input group definition files [repeatable argument]. Input file format
follows OrthoMCL <groups.txt> (or OrthoFinder <OrthologousGroups.txt>) format.
Each file will be turned into a new subdirectory populated with FASTA files
corresponding to all the group definition of the input file.

=for Euclid: infiles.type: readable
    repeatable

=item --database=<file>

Path to the FASTA file containing the sequence database.

=for Euclid: file.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
