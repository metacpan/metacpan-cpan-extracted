#!/usr/bin/env perl
# PODNAME: tree2tpl.pl
# ABSTRACT: Convert trees to TPL files

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
    my $outfile = change_suffix($infile, '.tpl');
    $tree->store_tpl($outfile);
}

__END__

=pod

=head1 NAME

tree2tpl.pl - Convert trees to TPL files

=head1 VERSION

version 0.251810

=head1 USAGE

    tree2tpl.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input TRE files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

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

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
