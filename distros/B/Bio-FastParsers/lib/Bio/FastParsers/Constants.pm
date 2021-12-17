package Bio::FastParsers::Constants;
# ABSTRACT: Distribution-wide constants for Bio::FastParsers
$Bio::FastParsers::Constants::VERSION = '0.213510';
use strict;
use warnings;

use Const::Fast;

use Exporter::Easy (
    OK   => [ qw(:files) ],
    TAGS => [
        files    => [ qw($EMPTY_LINE $COMMENT_LINE) ],
    ],
);

# regexes for parsing files

# common
const our $EMPTY_LINE   => qr{\A\s*\z}xms;
const our $COMMENT_LINE => qr{\A(\#)\s*(.*)}xms;

1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Constants - Distribution-wide constants for Bio::FastParsers

=head1 VERSION

version 0.213510

=head1 DESCRIPTION

Nothing to see here.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
