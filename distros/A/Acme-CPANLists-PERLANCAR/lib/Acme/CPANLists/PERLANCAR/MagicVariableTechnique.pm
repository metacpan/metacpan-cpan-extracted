package Acme::CPANLists::PERLANCAR::MagicVariableTechnique;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.26'; # VERSION

our @Module_Lists = (
    {
        summary => 'Modules which employ magic variable technique to do stuffs',
        description => <<'_',

This is a list of modules which provide some "magic" variable which you can
get/set to perform stuffs. I personally find this technique is mostly useful to
"temporarily set" stuffs, by combining it with Perl's `local()`.

_
        entries => [
            {
                module => 'File::chdir',
                description => <<'_',

Provides `$CWD` which you can use to change directory. By doing:

    local $CWD = ...;

in a subroutine or block, you can safely change directory temporarily without
messing current directory and breaking code in other parts. Very handy and
convenient.

This is the first module I found/use where I realized the technique. Since then
I've been looking for other modules using similar technique, and have even
created a few myself.

_
            },
            {
                module => 'File::umask',
                description => <<'_',

Provides `$UMASK` to get/set umask.

_
            },
            {
                module => 'Umask::Local',
                description => <<'_',

Like <pm:File::umask>, but instead of using a tied variable, uses an object with
its `DESTROY` method restoring original umask. I find the interface a bit more
awkward.

_
                alternate_modules => ['File::umask'],
            },
            {
                module => 'Locale::Tie',
                description => <<'_',

Provides `$LANG`, `$LC_ALL`, `$LC_TIME`, and few others to let you (temporarily)
set locale settings.

_
            },
            {
                module => 'Locale::Scope',
                description => <<'_',

Like <pm:Locale::Tie>, but instead of using a tied variable, uses an object with
its `DESTROY` method restoring original settings.

_
            },
        ],
    },
);

1;
# ABSTRACT: Modules which employ magic variable technique to do stuffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::MagicVariableTechnique - Modules which employ magic variable technique to do stuffs

=head1 VERSION

This document describes version 0.26 of Acme::CPANLists::PERLANCAR::MagicVariableTechnique (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-09-08.

=head1 MODULE LISTS

=head2 Modules which employ magic variable technique to do stuffs

This is a list of modules which provide some "magic" variable which you can
get/set to perform stuffs. I personally find this technique is mostly useful to
"temporarily set" stuffs, by combining it with Perl's C<local()>.


=over

=item * L<File::chdir>

Provides C<$CWD> which you can use to change directory. By doing:

 local $CWD = ...;

in a subroutine or block, you can safely change directory temporarily without
messing current directory and breaking code in other parts. Very handy and
convenient.

This is the first module I found/use where I realized the technique. Since then
I've been looking for other modules using similar technique, and have even
created a few myself.


=item * L<File::umask>

Provides C<$UMASK> to get/set umask.


=item * L<Umask::Local>

Like L<File::umask>, but instead of using a tied variable, uses an object with
its C<DESTROY> method restoring original umask. I find the interface a bit more
awkward.


Alternate modules: L<File::umask>

=item * L<Locale::Tie>

Provides C<$LANG>, C<$LC_ALL>, C<$LC_TIME>, and few others to let you (temporarily)
set locale settings.


=item * L<Locale::Scope>

Like L<Locale::Tie>, but instead of using a tied variable, uses an object with
its C<DESTROY> method restoring original settings.


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
