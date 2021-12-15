package Data::Sah::Coerce::perl::To_datenotime::From_float::epoch_always;

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::To_date::From_float::epoch_always';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.052'; # VERSION

1;
# ABSTRACT: Coerce date from number (assumed to be epoch)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_datenotime::From_float::epoch_always - Coerce date from number (assumed to be epoch)

=head1 VERSION

This document describes version 0.052 of Data::Sah::Coerce::perl::To_datenotime::From_float::epoch_always (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["datenotime",{"x.perl.coerce_rules"=>["From_float::epoch_always"]}]

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_datenotime::From_float::epoch>

L<Data::Sah::Coerce::perl::To_datenotime::From_str::iso8601>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
