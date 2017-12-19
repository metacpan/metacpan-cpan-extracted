package Bio::FastParsers::Hmmer;
# ABSTRACT: classes for parsing HMMER output
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::VERSION = '0.173510';
use strict;
use warnings;

use Bio::FastParsers::Hmmer::Standard;
use Bio::FastParsers::Hmmer::Table;
use Bio::FastParsers::Hmmer::DomTable;
use Bio::FastParsers::Hmmer::Model;

1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer - classes for parsing HMMER output

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Arnaud DI FRANCO

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
