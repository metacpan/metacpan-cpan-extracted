#!/usr/bin/perl -w
use strict;

my $VERSION = '0.11';

#----------------------------------------------------------------------------

=head1 NAME

addresses.pl - helper script to map tester addresses to real people.

=head1 SYNOPSIS

  perl addresses.pl \
        [--verbose|v] --config|c=<file> \
        ( [--help|h] \
        | [--update=<file>] \
        | [--reindex] [--lastid=<num>] \
        | [--clean] \
        | [--backup] \
        | [--mailrc|m=<file>] [--month=<string>] [--match] ) \
        [--logfile=<file>] [--logclean=(0|1)]

=head1 DESCRIPTION

Using the cpanstats database, this program can be used to update, reindex,
backup and search the tester address tables. 

When searching, the program tries to match unmatched tester addresses to either
a cpan author or an already known tester. For the remaining addresses, an 
attempt at pattern matching is made to try and identify similar addresses in 
the hope they can be manually identified.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use CPAN::Testers::Data::Addresses;

# -------------------------------------
# Program

my $ctda = CPAN::Testers::Data::Addresses->new();
$ctda->process();

# -------------------------------------

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Data-Addresses

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Statistics>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2013 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
