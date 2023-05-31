package CPAN::Porters;
use strict;
use warnings;

our $VERSION = '0.04';

1;


=head1 NAME

CPAN::Porters - resource for people maintaining packages of CPAN modules in various distributions

=head1 SYNOPSIS

CPAN modules can be either installed from source (downloaded directly from CPAN)
or they can be installed with the package mangement system of your distribution.

CPAN::Porters is a resource for people who are maintaining those packages in the
various distributions.

=head1 Reasoning

When developing an application we usually don't want to build our own machine. Neither
compile our own kernel. In most of the cases we won't want to compile and install
our own version of a database engine nor Apache or any other 3rd party tool.
So my assumption is that we won't want to install our CPAN dependencies either.
Again - in the standard case.

For people just using an application written in Perl it is even more important that they
should not deal with all these packages. Most of us know how much people suffer when they
need to install 10s of modules and their dependencies from CPAN. Especially for modules
with dependencies outside of CPAN.

While CPAN.pm, CPANPLUS.pm have improved a lot they still cannot deal with cases when one
of the dependencies fails to install cleanly.

In addition while we usually want to work with recent versions of modules from CPAN,
we usually don't want to get the bleeding edge. Espcially not in applications.

=head1 General resources

L<https://szabgab.com/distributions/> Statistics about CPAN modules in the various distributions

=head2 Related mailing lists

Module Authors: L<http://lists.cpan.org/showlist.cgi?name=module-authors>

Perl QA L<https://qa.perl.org> and the mailing list L<https://lists.cpan.org/showlist.cgi?name=perl-qa>

CPAN Testers L<https://testers.cpan.org/>

CPAN Discuss L<https://lists.cpan.org/showlist.cgi?name=cpan-discuss>


=head1 Guidelines for inclusion

In addition to the guidelines of each distribution on which module to include,
when to upgrade etc. we would like to setup our own guidelines to help people
decide what to include, what would be the priorites, when to upgrade a module
etc.

A few guidelines on how to select and prioritize modules:

=over 4

=item * Modules that are dependencies of another module by a different module author.

=item * Modules that require compilation

=item * Modules that require files not on CPAN

Such modules are especially difficult to install with CPAN.pm or CPANPLUS as they require
files outside the scope of CPAN. Making sure such modules and their dependencies can be
installed with the standard packaging system gets extra points.

=item * Web development frameworks

=item * Modules required by some of the big open source Perl applications.

     For a good listing see the journal entry of brian d foy
     L<http://use.perl.org/~brian_d_foy/journal/9974>

=back

Requirements for inclusion or upgrade

=over 4

=item * The module already has all its prereq in the system

=item * The module passes all its tests with its prereqs currently in the system on the system

=item * The tests of all the currently available dependent modules in the system pass with this new version

=item * A broader requirement would be that the version has no failing test reports on any other system,
       though this requirement might be too harsh and unnecessary


=back

=head1 TODO

=over 4

=item * Collect the basic information for the main distributions

=back

=head1 SEE ALSO

L<https://www.mail-archive.com/module-authors@perl.org/msg05248.html>

PIG has moved here: L<http://svn.ali.as/cpan/trunk/PIG/>

cpan2dist is a script from L<CPANPLUS>

=head1 AUTHOR

This document is maintained by Gabor Szabo <gabor@szabgab.com>

=cut

