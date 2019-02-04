use 5.014;  # because we use the 'state' and  'non-destructive substitution' feature (s///r)
use strict;
use warnings;

package Banal::Dist::Util; # git description: v0.004-4-g1789484
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: General purpose utility collection mainly used by C<Dist::Zilla::*::Author::TABULO>
# KEYWORDS: author utility

our $VERSION = '0.005';
# AUTHORITY


use Path::Tiny        qw(path);
use Data::Printer;                  # DEBUG aid.

use Exporter::Shiny qw( pause_config );

use namespace::autoclean;


# return username, password from ~/.pause
sub pause_config_alt  # Hmmm. We've got a similar named routine in *::Pause.pm
{
    my $file = path($ENV{HOME} // 'oops', '.pause');
    return if not -e $file;

    my ($username, $password) = map {
        my (undef, $val) = split ' ', $_; $val  # awk-style whitespace splitting
    } $file->lines;
}







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Banal::Dist::Util - General purpose utility collection mainly used by C<Dist::Zilla::*::Author::TABULO>

=head1 VERSION

version 0.005

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Dist-Util>
(or L<bug-Banal-Dist-Util@rt.cpan.org|mailto:bug-Banal-Dist-Util@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Tabulo Mohammad S Anwar

=over 4

=item *

Tabulo <dev@tabulo.net>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Tabulo <34737552+tabulon@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
