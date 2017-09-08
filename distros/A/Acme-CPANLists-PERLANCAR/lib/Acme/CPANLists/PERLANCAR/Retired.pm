package Acme::CPANLists::PERLANCAR::Retired;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.26'; # VERSION

our @Module_Lists = (
    # list: Retired modules
    {
        summary => 'Retired modules',
        description => <<'_',

This is a list of some of the modules which I wrote but have now been retired
and purged from CPAN, for various reasons but mostly because they are no longer
necessary. I've purged/retired more modules than these (mostly failed
experiments) but they are not worth mentioning here because nobody else seems to
have used them.

Note that you can always get these retired modules from BackPAN or GitHub (I
don't purge most of the repos) if needed.

_
        entries => [
            {
                module => 'Data::Schema',
                description => <<'_',

I wrote <pm:Data::Sah> which superseded this module since 2012.

_
                alternate_modules => ['Data::Sah'],
            },
            {
                module => 'Carp::Always::Dump',
                description => <<'_',

This module is like <pm:Carp::Always>, but dumps complex arguments instead of
just printing `ARRAY(0x22f8160)` or something like that.

Superseded by <pm:Devel::Confess>, which can do color
(<pm:Carp::Always::Color>), dumps (<pm:Carp::Always::Dump>), as well as a few
other tricks, all in a single package.

_
                alternate_modules => ['Devel::Confess'],
            },
            {
                module => 'Passwd::Unix::Alt',
                description => <<'_',

I first wrote <pm:Passwd::Unix::Alt> (a fork of <pm:Passwd::Unix>) to support
shadow passwd/group files, but later abandoned this fork due to a couple of
fundamental issues and later wrote a clean-slate attempt
<pm:Unix::Passwd::File>.

_
                alternate_modules => ['Unix::Passwd::File'],
            },
            {
                module => 'Module::List::WithPath',
                description => <<'_',

Superseded by <pm:PERLANCAR::Module::List>.

_
                alternate_modules => ['PERLANCAR::Module::List'],
            },
            {
                module => 'App::CreateSparseFile',
                description => <<'_',

I didn't know about the `fallocate` command.

_
                'x.date' => '2017-07-18',
            },
            {
                module => 'Log::Any::App',
                description => <<'_',

I've written <pm:Log::ger::App> to be its successor.

_
                'x.date' => '2017-09-08',
            },
        ],
    },
);

1;
# ABSTRACT: Retired modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Retired - Retired modules

=head1 VERSION

This document describes version 0.26 of Acme::CPANLists::PERLANCAR::Retired (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-09-08.

=head1 MODULE LISTS

=head2 Retired modules

This is a list of some of the modules which I wrote but have now been retired
and purged from CPAN, for various reasons but mostly because they are no longer
necessary. I've purged/retired more modules than these (mostly failed
experiments) but they are not worth mentioning here because nobody else seems to
have used them.

Note that you can always get these retired modules from BackPAN or GitHub (I
don't purge most of the repos) if needed.


=over

=item * L<Data::Schema>

I wrote L<Data::Sah> which superseded this module since 2012.


Alternate modules: L<Data::Sah>

=item * L<Carp::Always::Dump>

This module is like L<Carp::Always>, but dumps complex arguments instead of
just printing C<ARRAY(0x22f8160)> or something like that.

Superseded by L<Devel::Confess>, which can do color
(L<Carp::Always::Color>), dumps (L<Carp::Always::Dump>), as well as a few
other tricks, all in a single package.


Alternate modules: L<Devel::Confess>

=item * L<Passwd::Unix::Alt>

I first wrote L<Passwd::Unix::Alt> (a fork of L<Passwd::Unix>) to support
shadow passwd/group files, but later abandoned this fork due to a couple of
fundamental issues and later wrote a clean-slate attempt
L<Unix::Passwd::File>.


Alternate modules: L<Unix::Passwd::File>

=item * L<Module::List::WithPath>

Superseded by L<PERLANCAR::Module::List>.


Alternate modules: L<PERLANCAR::Module::List>

=item * L<App::CreateSparseFile>

I didn't know about the C<fallocate> command.


=item * L<Log::Any::App>

I've written L<Log::ger::App> to be its successor.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
