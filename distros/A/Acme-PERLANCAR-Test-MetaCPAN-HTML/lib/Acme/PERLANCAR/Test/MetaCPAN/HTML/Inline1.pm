package Acme::PERLANCAR::Test::MetaCPAN::HTML::Inline1;

our $DATE = '2019-01-22'; # DATE
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Test inline HTML

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Test::MetaCPAN::HTML::Inline1 - Test inline HTML

=head1 VERSION

This document describes version 0.005 of Acme::PERLANCAR::Test::MetaCPAN::HTML::Inline1 (from Perl distribution Acme-PERLANCAR-Test-MetaCPAN-HTML), released on 2019-01-22.

=for html <!-- begin comment --><table border><tr><td>1</td><td>2</td></tr></table><!-- end comment -->

=for html <!-- begin comment --><script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" /></script><!-- end comment -->

=for html <!-- begin comment --><script>alert("hello");</script><!-- end comment -->

=for html <!-- begin comment --><p>A normal paragraph</p><!-- end comment -->

=for html <!-- begin comment --><style> </style><!-- end comment -->

=for html <div id=#one> inside div </div>

=for html <div class=one> inside div2 </div>

=for html <p style="color: red">A red paragraph</p>

=for html <pre class="line-numbers">foo</pre>

=for html <pre id="source" class="line-numbers">line 1
line 2
line 3
</pre>

=head1 NOTES

Tables allowed.

HTML comments stripped.

<script>, <style> stripped.

<div> allowed but attributes stripped.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Test-MetaCPAN-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Test-MetaCPAN-HTML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Test-MetaCPAN-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
