package App::lcpan::CmdBundle::sah;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.01'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::sah - lcpan subcommands related to Data::Sah

=head1 VERSION

This document describes version 0.01 of App::lcpan::CmdBundle::sah (from Perl distribution App-lcpan-CmdBundle-sah), released on 2017-01-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List Data::Sah types available on CPAN
 % lcpan sah-types

 # List Data::Sah compilers available on CPAN
 % lcpan sah-compilers

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan sah-compilers|App::lcpan::Cmd::sah_compilers>

=item * L<lcpan sah-types|App::lcpan::Cmd::sah_types>

=back

This distribution packages several lcpan subcommands related to
L<Data::Sah>. More subcommands will be added in future releases.

Some ideas:

For each compiler, show list of (un)supported types (the ones it has (doesn't
have) the handler for).

List supported translation languages (Data::Sah::Lang::*).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
