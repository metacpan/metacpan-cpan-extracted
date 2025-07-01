#!/usr/bin/env perl
# PODNAME: tree2list.pl
# ABSTRACT: Generate id lists from tree tips

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Tree';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $tree = Tree->load($infile);
    my $list = $ARGV_sort ? $tree->alphabetical_list : $tree->std_list;
    my $outfile = change_suffix($infile, '.idl');
    $list->store($outfile);
}

__END__

=pod

=head1 NAME

tree2list.pl - Generate id lists from tree tips

=head1 VERSION

version 0.251810

=head1 USAGE

    tree2list.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input TRE files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --sort

Sort sequence ids [default: no].

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
