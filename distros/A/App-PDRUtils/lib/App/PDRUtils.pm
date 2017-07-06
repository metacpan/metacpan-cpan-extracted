package App::PDRUtils;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use Perinci::Object;

our %Common_CLI_Attrs = (
    #config_filename => ['pdrutils.conf'],
);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Collection of utilities for perl dist repos',
};

1;
# ABSTRACT: Collection of utilities for perl dist repos

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils - Collection of utilities for perl dist repos

=head1 VERSION

This document describes version 0.10 of App::PDRUtils (from Perl distribution App-PDRUtils), released on 2017-07-03.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
perl dist repos:

=over

=item * L<pdrutil>

=item * L<pdrutil-multi>

=back

=head1 DESCRIPTION

If you have one or more CPAN (or DarkPAN) perl distribution repos on your
filesystem, then this suite of CLI utilities might be useful for you. Currently
only the combination of L<Dist::Zilla>-based Perl distributions managed by git
version control is supported.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
