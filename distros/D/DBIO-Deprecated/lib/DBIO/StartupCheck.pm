package DBIO::StartupCheck;
# ABSTRACT: REMOVED -- no replacement, see DBIO::Deprecated

use strict;
use warnings;

# Deliberately explicit $VERSION -- unlike normal DBIO sub-modules, which
# carry none (only the dist's main module does, bumped by dzil). This
# tombstone needs its own hard-coded, higher $VERSION so PAUSE indexes THIS
# module as canonical for the name: PAUSE resolves each module name to
# whichever shipped distribution carries the highest $VERSION, and DBIO
# core's last CPAN release to ship this module was 0.900000. Do NOT "clean
# this up" to match the no-$VERSION sub-module convention -- doing so hands
# the PAUSE index entry back to the stale, superseded release.
our $VERSION = '0.900001';

# "Removed, no successor" tombstone: unlike a rename, there is nothing to
# redirect to -- say so plainly instead of pointing at a replacement module.
die __PACKAGE__ . " has been removed. It only checked for a Red Hat/Fedora"
  . " system-perl bug from ~2008 (bless/overload performance regression),"
  . " long fixed upstream; DBIO no longer ships this check. There is no"
  . " replacement module -- simply remove the 'use DBIO::StartupCheck;'"
  . " line from your code.\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::StartupCheck - REMOVED -- no replacement, see DBIO::Deprecated

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

This module has been removed from DBIO core, not renamed -- there is no
replacement. It used to check for, and warn about, a bug on Red Hat and
Fedora systems using their system perl build (a C<bless>/C<overload> patch
that caused a 2x-100x performance penalty on perl 5.8.8-10 and later). That
bug was fixed upstream by all current Red Hat/Fedora distributions long ago;
the check had become permanently dead weight, incorrectly flagging fixed perl
builds. DBIO core dropped it outright.

This module is a CPAN redirect stub, part of L<DBIO::Deprecated>. It carries
no implementation and B<dies unconditionally> as soon as it is loaded. Unlike
most tombstones in this distribution, it does not point at a replacement
module -- there is none. It exists only so that C<cpanm DBIO::StartupCheck>
-- or a cpanfile / code that still references the old name -- surfaces a
clear explanation instead of silently installing the stale, superseded
C<DBIO> 0.900000 release that still carries this name.

Simply remove any C<use DBIO::StartupCheck;> line from your code; DBIO core
no longer needs or performs this check.

=head1 NAME

DBIO::StartupCheck - REMOVED, no replacement

=head1 SEE ALSO

L<DBIO>, L<DBIO::Deprecated>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
