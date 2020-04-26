package Code::TidyAll::Plugin::SortLines;

use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.78';

sub transform_source {
    my ( $self, $source ) = @_;

    return join( "\n", sort( grep {/\S/} split( /\n/, $source ) ) ) . "\n";
}

1;

# ABSTRACT: Sort the lines in a file

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::SortLines - Sort the lines in a file

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   # In configuration:

   [SortLines]
   select = .ispell* **/.gitignore

=head1 DESCRIPTION

Sorts the lines of a file; whitespace lines are discarded. Useful for files
containing one entry per line, such as C<.svnignore>, C<.gitignore>, and
C<.ispell*>.

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
