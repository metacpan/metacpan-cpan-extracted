package Acme::PERLANCAR::Dummy::MetaCPAN::HTML;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-26'; # DATE
our $DIST = 'Acme-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.011'; # VERSION

1;
# ABSTRACT: Testing which HTML elements/attributes are allowed by MetaCPAN website

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Dummy::MetaCPAN::HTML - Testing which HTML elements/attributes are allowed by MetaCPAN website

=head1 VERSION

This document describes version 0.011 of Acme::PERLANCAR::Dummy::MetaCPAN::HTML (from Perl distribution Acme-PERLANCAR-Dummy), released on 2021-07-26.

=head1 DESCRIPTION

The filtering is performed by C<MetaCPAN::Web::RenderUtil>'s C<filter_html>
using L<HTML::Restrict> in the
L<metacpan-web|https://github.com/metacpan/metacpan-web> repository.

=head1 TABLES

=for html <table border=1>
<thead>
<tr><th>Year</th><th>Comedy</th><th>Drama</th><th>Variety</th><th>Lead Comedy Actor</th><th>Lead Drama Actor</th><th>Lead Comedy Actress</th><th>Lead Drama Actress</th></tr>
</thead>
<tbody>
<tr><td>1962</td><td>The Bob Newhart Show (NBC)</td><td rowspan=3>The Defenders (CBS)</td><td>The Garry Moore Show (CBS)</td><td rowspan=2 colspan=2>E. G. Marshall, The Defenders (CBS)</td><td rowspan=2 colspan=2>Shirley Booth, Hazel (NBC)</td></tr>
<tr><td>1963</td><td rowspan=2>The Dick Van Dyke Show (CBS)</td><td>The Andy Williams Show (NBC)</td></tr>
<tr><td>1964</td><td>The Danny Kaye Show (CBS)</td><td colspan=2>Dick Van Dyke, The Dick Van Dyke Show (CBS)</td><td colspan=2>Mary Tyler Moore, The Dick Van Dyke Show (CBS)</td></tr>
<tr><td>1965</td><td colspan=3>four winners (Outstanding Program Achievements in Entertainment)</td><td colspan=4>five winners (Outstanding Program Achievements in Entertainment)</td></tr>
<tr><td>1966</td><td>The Dick Van Dyke Show (CBS)</td><td>The Fugitive (ABC)</td><td>The Andy Williams Show (NBC)</td><td>Dick Van Dyke, The Dick Van Dyke Show (CBS)</td><td>Bill Cosby, I Spy (CBS)</td><td>Mary Tyler Moore, The Dick Van Dyke Show (CBS)</td><td>Barbara Stanwyck, The Big Valley (CBS)</td></tr>
</tbody>
</table>

Tables are allowed, including C<table>, C<tr>, C<td>, and C<th> elements. Style
attributes are stripped. Most attributes are also stripped, but colspan/rowspan
and table's border are among the allowed.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib/MetaCPAN/Web/RenderUtil.pm> in L<https://github.com/metacpan/metacpan-web>
repository.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
