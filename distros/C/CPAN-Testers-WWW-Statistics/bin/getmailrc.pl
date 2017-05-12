#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '0.03';

#----------------------------------------------------------------------------

=head1 NAME

getmailrc.pl - downloads 01mailrc.txt.gz from CPAN.

=head1 SYNOPSIS

  perl getmailrc.pl

=head1 DESCRIPTION

Downloads the latest copy of the authors index file from CPAN, and extracts
the text file from the archive.

=cut

# -------------------------------------
# Library Modules

use File::Basename;
use WWW::Mechanize;
use Archive::Extract;

# -------------------------------------
# Program

my $mech = WWW::Mechanize->new();
my $source = 'http://www.cpan.org/authors/01mailrc.txt.gz';
my $target = basename($source);

chdir('data');
$mech->mirror($source,$target);
my $ae = Archive::Extract->new( archive => $target );
unless($ae->extract) {
    die 'Failed to extract the archive [$target]';
}

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Statistics

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
