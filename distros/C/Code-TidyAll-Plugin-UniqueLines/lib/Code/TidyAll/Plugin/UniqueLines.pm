use strict;
use warnings;

use 5.006;

package Code::TidyAll::Plugin::UniqueLines;
$Code::TidyAll::Plugin::UniqueLines::VERSION = '0.000003';
use Moo;
extends 'Code::TidyAll::Plugin';

use List::Util 1.45 qw( uniq );

sub transform_source {
    my ( $self, $source ) = @_;

    return join( "\n", uniq( grep { /\S/ } split( /\n/, $source ) ) ) . "\n";
}

1;

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::UniqueLines - Remove duplicate lines from a file

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

   # In configuration:

   [UniqueLines]
   select = .ispell* **/.gitignore

=head1 DESCRIPTION

Discards duplicate lines from a file.  Useful for files containing one entry
per line, such as C<.svnignore>, C<.gitignore>, and C<.ispell*>.

=head1 ACKNOWLEDGEMENTS

This code was essentially pilfered from L<Code::TidyAll::Plugin::SortLines>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Remove duplicate lines from a file

