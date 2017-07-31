package Acme::CPANLists::PERLANCAR::Avoided;

our $DATE = '2017-07-28'; # DATE
our $VERSION = '0.25'; # VERSION

our @Module_Lists = (
    {
        summary => "Modules I'm currently avoiding",
        description => <<'_',

This is a list of modules I'm currently avoiding to use in my code, for some
reason. Most of the modules wered used in my code in the past.

Using a <pm:Dist::Zilla> plugin
<pm:Dist::Zilla::Plugin::Acme::CPANLists::Blacklist>, you can make sure that
during building, your distribution does not specify a prerequisite to any of the
modules listed here. (You should make your own blacklist though).

_
        entries => [
            {
                module => 'Log::Any',
                summary => 'Startup overhead',
                description => <<'_',

After the 1.x version, I no longer prefer <pm:Log::Any> and have developed an
alternative called <pm:Log::ger>.

_
                alternate_modules => ['Log::ger'],
            },
            {
                module => 'Log::Any::IfLOG',
                summary => 'Retired workaround',
                alternate_modules => ['Log::ger'],
            },
            {
                module => 'File::Flock',
                summary => 'Too many deps',
                description => <<'_',

I used to use <pm:File::Flock> due to its simple interface. However, this module
depends on things like <pm:AnyEvent>, <pm:Data::Structure::Util>,
<pm:File::Slurp>, et al, all of which seem unnecessary. Nowadays I'm opting to
use <pm:File::Flock::Retry>, or just plain `flock()`.

_
                alternate_modules => ['File::Flock::Retry'],
            },
            {
                module => 'File::Slurp',
                summary => 'Buggy',
                alternate_modules => ['File::Slurper'],
            },
            {
                module => 'File::Slurp::Tiny',
                summary => 'Use the newer File::Slurper instead',
                alternate_modules => ['File::Slurper'],
            },
            {
                module => 'Exporter::Lite',
                summary => 'Unnecessary, use Exporter instead',
                description => <<'_',

I used to use this module because I didn't know that <pm:Exporter> (since perl
5.8.3, 2004) can also be used without subclassing, i.e. instead of:

    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = (...);

you can also use it like this:

    use Exporter qw(import);
    our @EXPORT = (...);

Hence, this module (first released in 2001) is no longer necessary. Besides,
this module has a worse startup overhead than <pm:Exporter> *and* has less
features. So there is absolutely no reason to use it.

_
                alternate_modules => ['Exporter'],
            },
            {
                module => 'JSON',
                summary => 'Somewhat broken',
                description => <<'_',

JSON.pm is a discouraged module now, due to its somewhat broken backend handling
and lack of support for <pm:Cpanel::JSON::XS>. consider switching to
<pm:JSON::MaybeXS> or perhaps just <pm:JSON::PP>.

_
                alternate_modules => ['JSON::MaybeXS', 'JSON::PP', 'Cpanel::JSON::XS'],
            },
            {
                module => 'JSON::XS',
                summary => '',
                description => <<'_',

<pm:Cpanel::JSON::XS> is the fork of <pm:JSON::XS> that fixes some bugs and adds
some features, mainly so it's more compatible with <pm:JSON::PP>. See the
documentation of <pm:Cpanel::JSON::XS> for more details on those.

_
                alternate_modules => ['Cpanel::JSON::XS'],
            },
            {
                module => 'Module::Path',
                summary => '',
                description => <<'_',

It's a nice little concept and module, and often useful. But the decision like
defaulting to doing abs_path()
(https://rt.cpan.org/Public/Bug/Display.html?id=100979), which complicates the
module, makes its behavior different than Perl's require(), as well as opens the
can of worms of ugly filesytem details, has prompted me to release an
alternative. Module::Path::More also has the options to find .pod and/or .pmc
file, and find all matches instead of the first.

_
                alternate_modules => ['Module::Path::More'],
            },
        ],
    },
);

1;
# ABSTRACT: Modules I'm currently avoiding

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Avoided - Modules I'm currently avoiding

=head1 VERSION

This document describes version 0.25 of Acme::CPANLists::PERLANCAR::Avoided (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-07-28.

=head1 MODULE LISTS

=head2 Modules I'm currently avoiding

This is a list of modules I'm currently avoiding to use in my code, for some
reason. Most of the modules wered used in my code in the past.

Using a L<Dist::Zilla> plugin
L<Dist::Zilla::Plugin::Acme::CPANLists::Blacklist>, you can make sure that
during building, your distribution does not specify a prerequisite to any of the
modules listed here. (You should make your own blacklist though).


=over

=item * L<Log::Any> - Startup overhead

After the 1.x version, I no longer prefer L<Log::Any> and have developed an
alternative called L<Log::ger>.


Alternate modules: L<Log::ger>

=item * L<Log::Any::IfLOG> - Retired workaround

Alternate modules: L<Log::ger>

=item * L<File::Flock> - Too many deps

I used to use L<File::Flock> due to its simple interface. However, this module
depends on things like L<AnyEvent>, L<Data::Structure::Util>,
L<File::Slurp>, et al, all of which seem unnecessary. Nowadays I'm opting to
use L<File::Flock::Retry>, or just plain C<flock()>.


Alternate modules: L<File::Flock::Retry>

=item * L<File::Slurp> - Buggy

Alternate modules: L<File::Slurper>

=item * L<File::Slurp::Tiny> - Use the newer File::Slurper instead

Alternate modules: L<File::Slurper>

=item * L<Exporter::Lite> - Unnecessary, use Exporter instead

I used to use this module because I didn't know that L<Exporter> (since perl
5.8.3, 2004) can also be used without subclassing, i.e. instead of:

 use Exporter;
 our @ISA = qw(Exporter);
 our @EXPORT = (...);

you can also use it like this:

 use Exporter qw(import);
 our @EXPORT = (...);

Hence, this module (first released in 2001) is no longer necessary. Besides,
this module has a worse startup overhead than L<Exporter> I<and> has less
features. So there is absolutely no reason to use it.


Alternate modules: L<Exporter>

=item * L<JSON> - Somewhat broken

JSON.pm is a discouraged module now, due to its somewhat broken backend handling
and lack of support for L<Cpanel::JSON::XS>. consider switching to
L<JSON::MaybeXS> or perhaps just L<JSON::PP>.


Alternate modules: L<JSON::MaybeXS>, L<JSON::PP>, L<Cpanel::JSON::XS>

=item * L<JSON::XS>

L<Cpanel::JSON::XS> is the fork of L<JSON::XS> that fixes some bugs and adds
some features, mainly so it's more compatible with L<JSON::PP>. See the
documentation of L<Cpanel::JSON::XS> for more details on those.


Alternate modules: L<Cpanel::JSON::XS>

=item * L<Module::Path>

It's a nice little concept and module, and often useful. But the decision like
defaulting to doing abs_path()
(https://rt.cpan.org/Public/Bug/Display.html?id=100979), which complicates the
module, makes its behavior different than Perl's require(), as well as opens the
can of worms of ugly filesytem details, has prompted me to release an
alternative. Module::Path::More also has the options to find .pod and/or .pmc
file, and find all matches instead of the first.


Alternate modules: L<Module::Path::More>

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
