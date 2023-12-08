package End::PrintBytesIn;

use 5.010001;
use strict;
use warnings;

use Number::Format::Metric;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.073'; # VERSION

END {
    printf "Total downloaded data: %sb\n",
        Number::Format::Metric::format_metric($LWP::Protocol::Patch::CountBytesIn::bytes_in // 0);
}

1;
# ABSTRACT: Show LWP::Protocol::Patch::CountBytesIn::bytes_in

__END__

=pod

=encoding UTF-8

=head1 NAME

End::PrintBytesIn - Show LWP::Protocol::Patch::CountBytesIn::bytes_in

=head1 VERSION

This document describes version 1.073 of End::PrintBytesIn (from Perl distribution App-lcpan), released on 2023-07-09.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 SEE ALSO

L<LWP::Protocol::Patch::CountBytesIn>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
