# $Id: Dependency.pm,v 1.8 2007/12/13 15:16:03 drhyde Exp $
#!perl -w
package CPAN::FindDependencies::Dependency;

use strict;

use vars qw($VERSION);

$VERSION = '2.1';

=head1 NAME

CPAN::FindDependencies::Dependency - object representing a module dependency

=head1 SYNOPSIS

    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' (dist: '.$dep->distribution().', mod ver: '.$dep->version().")\n";
    }

=head1 METHODS

The following read-only accessors are available.  You will note that
there is no public constructor and no mutators.  Objects will be
created by the CPAN::FindDependencies module.

=cut

sub _new {
    my($class, %opts) = @_;
    bless \%opts, $class;
}

=head2 name

The name of the module

=cut

sub name { $_[0]->{cpanmodule} }

=head2 distribution

The name of the distribution containing the module

=cut

sub distribution {
    $_[0]->{p}->package($_[0]->name())->distribution()->prefix();
}

=head2 version

The minimum required version (if specified) of the module

=cut

sub version {
  $_[0]->{version}
}

=head2 depth

How deeply nested this module is in the dependency tree

=cut

sub depth { return $_[0]->{depth} }

=head2 warning

If any warnings were generated while processing the module (even
if suppressed), this will return them.

=cut

sub warning { return $_[0]->{warning} }

=head1 BUGS/LIMITATIONS

None known

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in my git repo and
will pass once I've fixed the bug

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPAN-FindDependencies.git>

=head1 SEE ALSO

L<CPAN::FindDepdendencies>

L<CPAN>

L<http://deps.cpantesters.org/>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
