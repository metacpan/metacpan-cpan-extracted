package App::PDRUtils::Cmd;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;

our %mod_args = (
    module => {
        schema => 'str*',
        req => 1,
        pos => 0,
    },
);

our %mod_ver_args = (
    module_version => {
        schema => ['str*', match=>qr/\Av?\d{1,3}(\.\d{1,3}){0,2}\z/], # XXX perlmod_ver?
        req => 1,
        pos => 1,
    },
);

our %opt_mod_ver_args = (
    module_version => {
        schema => ['str*', match=>qr/\Av?\d{1,3}(\.\d{1,3}){0,2}\z/], # XXX perlmod_ver?
        default => "0",
        pos => 1,
    },
);

our %by_ver_args = (
    by => {
        schema => ['str*', match=>qr/\Av?\d{1,3}(\.\d{1,3}){0,2}\z/],
        req => 1,
        pos => 1,
    },
);

sub _has_prereq {
    my ($iod, $mod) = @_;
    for my $section ($iod->list_sections) {
        # like in lint-prereqs
        $section =~ m!\A(
                          osprereqs \s*/\s* .+ |
                          osprereqs(::\w+)+ |
                          prereqs (?: \s*/\s* (?<prereqs_phase_rel>\w+))? |
                          extras \s*/\s* lint[_-]prereqs \s*/\s* (assume-(?:provided|used))
                      )\z!ix or next;
        for my $param ($iod->list_keys($section)) {
            return 1 if $param eq $mod;
        }
    }
    0;
}

1;
# ABSTRACT: Common stuffs for App::PDRUtils::*Cmd::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::Cmd - Common stuffs for App::PDRUtils::*Cmd::*

=head1 VERSION

This document describes version 0.10 of App::PDRUtils::Cmd (from Perl distribution App-PDRUtils), released on 2017-07-03.

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
