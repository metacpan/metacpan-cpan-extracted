package Bio::MUST::Apps::OmpaPa;
# ABSTRACT: Main class for ompa-pa tool
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Apps::OmpaPa::VERSION = '0.251770';
use strict;
use warnings;

use Bio::FastParsers;
use Bio::MUST::Core;
use Bio::MUST::Drivers;

use Bio::MUST::Apps::OmpaPa::Blast;
use Bio::MUST::Apps::OmpaPa::Hmmer;
use Bio::MUST::Apps::OmpaPa::Parameters;

1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::OmpaPa - Main class for ompa-pa tool

=head1 VERSION

version 0.251770

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
