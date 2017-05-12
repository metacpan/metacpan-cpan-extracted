package Alien::SamTools;
our $AUTHORITY = 'cpan:HARTZELL';
$Alien::SamTools::VERSION = '0.002';
# ABSTRACT: Fetch/build/stash the SamTools headers and libs.


use strict;
use warnings;

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SamTools - Fetch/build/stash the SamTools headers and libs.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

By way of an example, the following change to the C<Build.PL> file in the
C<Bio-SamTools-1.39> distribution provides it with the information it needs to
find the headers and library that Alien::SamTools installed.

    ===================================================================
    RCS file: Build.PL,v
    retrieving revision 1.1
    diff -r1.1 Build.PL
    4a5
    > use Module::Load::Conditional qw(can_load);
    69a71,76
    > sub _samtools {
    >     $ENV{SAMTOOLS} ||
    >     ( can_load(modules => {'Alien::SamTools' => undef, 'File::ShareDir' => undef}) &&
    >       File::ShareDir::dist_dir('Alien-SamTools'));
    > }
    >
    73c80
    <     if (my $samtools = $ENV{SAMTOOLS}) {
    ---
    >     if (my $samtools = _samtools()) {

=head1 DESCRIPTION

Download, build, and install the SamTools C headers and libraries into a
well-known location, C<File::ShareDir::dist_dir('Alien-SamTools')>, from whence
other packages can make use of them.

It currently installs L<samtools-0.1.19.tar.bz2|http://colocrossing.dl.sourceforge.net/project/samtools/samtools/0.1.19/samtools-0.1.19.tar.bz2>.

=head1 AUTHOR

George Hartzell

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Genentech.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
