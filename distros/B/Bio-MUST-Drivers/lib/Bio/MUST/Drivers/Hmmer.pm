package Bio::MUST::Drivers::Hmmer;
# ABSTRACT: Bio::MUST driver for running HMMER3
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
$Bio::MUST::Drivers::Hmmer::VERSION = '0.191910';
use strict;
use warnings;

use Bio::MUST::Drivers::Hmmer::Model;
use Bio::MUST::Drivers::Hmmer::Model::Database;
use Bio::MUST::Drivers::Hmmer::Model::Temporary;

1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Hmmer - Bio::MUST driver for running HMMER3

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Arnaud DI FRANCO Loic MEUNIER

=over 4

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Loic MEUNIER <loic.meunier@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
