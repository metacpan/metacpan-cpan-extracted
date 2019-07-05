package Calendar::DatesRoles::PublicInterface::Basic;

use Role::Tiny;

requires 'get_min_year';
requires 'get_max_year';
requires 'get_entries';

1;
# ABSTRACT: Basic public interface of Calendar::Dates

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::DatesRoles::PublicInterface::Basic - Basic public interface of Calendar::Dates

=head1 VERSION

This document describes version 0.2.3 of Calendar::DatesRoles::PublicInterface::Basic (from Perl distribution Calendar-Dates), released on 2019-06-22.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates>

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
