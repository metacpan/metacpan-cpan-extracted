package Bio::FastParsers;
# ABSTRACT: classes for parsing bioinformatics program output
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::VERSION = '0.173510';
use strict;
use warnings;

use Bio::FastParsers::Blast;
use Bio::FastParsers::CdHit;
use Bio::FastParsers::Hmmer;

1;

__END__

=pod

=head1 NAME

Bio::FastParsers - classes for parsing bioinformatics program output

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Arnaud DI FRANCO

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
