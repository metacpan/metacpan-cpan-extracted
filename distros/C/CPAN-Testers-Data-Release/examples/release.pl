#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.03';

$|++;

#----------------------------------------------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use CPAN::Testers::Data::Release;

#----------------------------------------------------------------------------
# The Application Programming Interface

my $obj = CPAN::Testers::Data::Release->new();
$obj->process();

__END__

#----------------------------------------------------------------------------

=head1 NAME

release.pl - creates, updates and/or backs up the uploads database.

=head1 SYNOPSIS

  perl release.pl --config=<file> [--clean] [ -h | -v ]

=head1 DESCRIPTION

This program contains the code that extracts the data from the release_summary
table in the cpanstats database. The data extracted represents the data 
relating to the public releases of Perl, i.e. no patches and official releases 
only.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<CPAN::Testers::Data::Generate>
L<CPAN::Testers::Data::Uploads>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2012 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
