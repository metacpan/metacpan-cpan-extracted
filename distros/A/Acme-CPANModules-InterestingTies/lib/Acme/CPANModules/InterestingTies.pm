package Acme::CPANModules::InterestingTies;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-InterestingTies'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of interesting uses of the tie() interface",
    description => <<'MARKDOWN',

The perl's tie interface allows you to create "magical" scalar, array, hash, or
filehandle. When you read or set the value of these variables, various things
can be triggered.

This <pm:Acme::CPANModules> list catalogs some of the interesting uses of the
tie() interface.

MARKDOWN
    entries => [

        {
            module => 'Acme::Tie::Formatted',
            description => <<'MARKDOWN',

This module allows you to do `sprintf()` by accessing a hash key, e.g.:

    print $format{17, "%03x"};

will output:

    011

The nice thing about this is that the `$format{...}` term can be put inside
double quote, although you have to use a different quote inside the quote, e.g.:

    print "The value is: $format{17, '%03x'}";
    print qq(The value is: $format{17, "%03x"});

The module advertises the functionality as "printf inside print", although the
author chose to accept a different argument order than printf. Instead of:

    FORMAT, LIST

the FORMAT is put at the end:

    LIST, FORMAT

MARKDOWN
        },

        {
            module => 'Regexp::Common',
            description => <<'MARKDOWN',

This module contains a collection of regular expression patterns. To access the
patterns, you can use the tied hash %RE, e.g.:

    $RE{quoted}
    $RE{num}{real}

You can also give arguments to customize the generated pattern:

    $RE{delimited}{-delim=>'/'}]

The advantage, again, is being able to be used inside a regular expression
pattern.

Note that the module also offers subroutine-based interface. I also created an
alternative module called <pm:Regexp::Pattern> which opts for the non-magical
subroutine-based interface and offers smaller startup overhead.

MARKDOWN
        },

    ],
};

1;
# ABSTRACT: List of interesting uses of the tie() interface

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::InterestingTies - List of interesting uses of the tie() interface

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::InterestingTies (from Perl distribution Acme-CPANModules-InterestingTies), released on 2023-10-31.

=head1 DESCRIPTION

The perl's tie interface allows you to create "magical" scalar, array, hash, or
filehandle. When you read or set the value of these variables, various things
can be triggered.

This L<Acme::CPANModules> list catalogs some of the interesting uses of the
tie() interface.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Acme::Tie::Formatted>

Author: L<MCMAHON|https://metacpan.org/author/MCMAHON>

This module allows you to do C<sprintf()> by accessing a hash key, e.g.:

 print $format{17, "%03x"};

will output:

 011

The nice thing about this is that the C<$format{...}> term can be put inside
double quote, although you have to use a different quote inside the quote, e.g.:

 print "The value is: $format{17, '%03x'}";
 print qq(The value is: $format{17, "%03x"});

The module advertises the functionality as "printf inside print", although the
author chose to accept a different argument order than printf. Instead of:

 FORMAT, LIST

the FORMAT is put at the end:

 LIST, FORMAT


=item L<Regexp::Common>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

This module contains a collection of regular expression patterns. To access the
patterns, you can use the tied hash %RE, e.g.:

 $RE{quoted}
 $RE{num}{real}

You can also give arguments to customize the generated pattern:

 $RE{delimited}{-delim=>'/'}]

The advantage, again, is being able to be used inside a regular expression
pattern.

Note that the module also offers subroutine-based interface. I also created an
alternative module called L<Regexp::Pattern> which opts for the non-magical
subroutine-based interface and offers smaller startup overhead.


=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n InterestingTies

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries InterestingTies | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=InterestingTies -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::InterestingTies -E'say $_->{module} for @{ $Acme::CPANModules::InterestingTies::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-InterestingTies>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-InterestingTies>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-InterestingTies>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
