#!/usr/bin/env perl
# PODNAME: extract-ali.pl
# ABSTRACT: Extract sequences from a FASTA database file based on id lists

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali::Stash';
use aliased 'Bio::MUST::Core::IdList';


my %args;
$args{truncate_ids} = 1 if $ARGV_truncate_ids;

# load database
my $db = Stash->load($ARGV_database, \%args);

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $list = IdList->load($infile);

    # assemble Ali and store it as FASTA file
    my $ali = $ARGV_reorder ? $list->reordered_ali($db)
            :                 $list->filtered_ali($db)
    ;
    $ali->dont_guess;
    my $outfile = change_suffix($infile, '.ali');
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

extract-ali.pl - Extract sequences from a FASTA database file based on id lists

=head1 VERSION

version 0.251810

=head1 USAGE

    extract-ali.pl <infiles> --database=<file> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input IDL files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --database=<file>

Path to the FASTA file containing the sequence database.

=for Euclid: file.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --truncate-ids

Truncate database ids on first whitespace before extraction [default: no].

=item --reorder

Reorder sequences following list [default: no].

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
