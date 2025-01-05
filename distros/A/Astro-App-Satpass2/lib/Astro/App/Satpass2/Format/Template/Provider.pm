package Astro::App::Satpass2::Format::Template::Provider;

use 5.008;

use strict;
use warnings;

use parent qw{ Template::Provider };

use Astro::App::Satpass2::Utils qw{ :os @CARP_NOT };

our $VERSION = '0.055';

use constant ENCODING	=> OS_IS_WINDOWS ?
    ':crlf:encoding(utf-8)' :
    ':encoding(utf-8)';

# Cribbed **ALMOST** verbatim from Template::Provider. The only
# difference is the binmode() call, which applies I/O layers as
# convenient.
## no critic (UnusedPrivateSubroutines,UnusedVarsStricter,ProhibitBarewordFileHandles,ProhibitInterpolationOfLiterals)

sub _template_content {
    my ($self, $path) = @_;

    return (undef, "No path specified to fetch content from ")
        unless $path;

    my $data;
    my $mod_date;
    my $error;

    local *FH;
    if(-d $path) {
        $error = "$path: not a file";
    }
    elsif (open(FH, "<", $path)) {
        local $/;
        binmode(FH, ENCODING);
        $data = <FH>;
        $mod_date = (stat($path))[9];
        close(FH);
    }
    else {
        $error = "$path: $!";
    }

    return wantarray
        ? ( $data, $error, $mod_date )
        : $data;
}

## use critic

1;

__END__

=head1 NAME

Astro::App::Satpass2::Format::Template::Provider - Custom Template-Toolkit provider

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DESCRIPTION

This module is B<private> to the C<Astro-App-Satpass2> distribution, and
can be changed or revoked at any time. Documentation is for the
convenience of the author, and does not constitute a commitment of any
sort.)

This Perl module is a subclass of
L<Template::Provider|Template::Provider>. Its purpose is to provide
encoding to template files.

The original reads templates in binmode, which caused problems when
testing under C<MSWin32>. At this point I have decided to solve the
template input problem by specifying an explicit
C<:crlf:encoding(utf-8)> under Windows, and C<:encoding(utf-8)>
otherwise.

=head1 METHODS

This class overrides parent method C<_template_content()>.

=head1 SEE ALSO

L<Template::Provider|Template::Provider>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-App-Satpass2>,
L<https://github.com/trwyant/perl-Astro-App-Satpass2/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024-2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
