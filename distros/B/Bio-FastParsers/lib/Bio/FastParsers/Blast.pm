package Bio::FastParsers::Blast;
# ABSTRACT: Classes for parsing BLAST output
$Bio::FastParsers::Blast::VERSION = '0.180470';
use strict;
use warnings;

use Bio::FastParsers::Blast::Table;
use Bio::FastParsers::Blast::Xml;

1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Blast - Classes for parsing BLAST output

=head1 VERSION

version 0.180470

=head1 SYNOPSIS

    # see Bio::FastParsers::Blast::Table
    # see Bio::FastParsers::Blast::Xml

=head1 DESCRIPTION

Parsers for two BLAST output formats are available: tabular and XML.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
