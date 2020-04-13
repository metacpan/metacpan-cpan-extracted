package End::PrintBytesIn;

our $DATE = '2020-04-11'; # DATE
our $VERSION = '1.049'; # VERSION

use 5.010001;
use strict;
use warnings;

use Number::Format::Metric;

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

This document describes version 1.049 of End::PrintBytesIn (from Perl distribution App-lcpan), released on 2020-04-11.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::Protocol::Patch::CountBytesIn>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
