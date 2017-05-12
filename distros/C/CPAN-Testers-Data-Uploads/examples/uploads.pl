#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);

$VERSION = '0.02';

$|++;

#----------------------------------------------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use CPAN::Testers::Data::Uploads;

#----------------------------------------------------------------------------
# The Application Programming Interface

my $obj = CPAN::Testers::Data::Uploads->new();
$obj->process();

__END__

#----------------------------------------------------------------------------

=head1 NAME

uploads.pl - creates, updates and/or backs up the uploads database.

=head1 SYNOPSIS

  perl uploads.pl --config=<file> (-generate | -update | -backup | -h | -v)

=head1 DESCRIPTION

This program allows the user to create, update and backup the uploads database,
either as separate commands, or a combination of all three. The process order
will always be CREATE->UPDATE->BACKUP, regardless of the order the options
appear on the command line.

The Uploads database contains basic information about the history of CPAN. It
records the release dates of everything that is uploaded to CPAN, both within
a BACKPAN repository, a current CPAN repository and the latest uploads posted
by PAUSE, which may not have yet reached the CPAN mirrors.

A simple schema for the MySQL database is below:

  CREATE TABLE `uploads` (
    `type`      varchar(10)     NOT NULL,
    `author`    varchar(32)     NOT NULL,
    `dist`      varchar(100)    NOT NULL,
    `version`   varchar(100)    NOT NULL,
    `filename`  varchar(255)    NOT NULL,
    `released`  int(16)         NOT NULL,
    PRIMARY KEY  (`author`,`dist`,`version`)
  ) ENGINE=MyISAM;

The 'type' field can be one of three values, 'backpan', 'cpan' or 'upload',
which incates whether the release has been archived to BACKPAN, currently on
CPAN or has recently been uploaded and may not have reached the CPAN mirrors
yet.

The 'author', 'dist', 'version' and 'filename' fields contain the breakdown of
the distribution component parts used to locate the distribution. Although in
most cases the filename could be considered a primary key, it is possible that
two or more authors could upload a distribution with the same name.

The 'released' field holds the date of the distribution release as the number
of seconds since the epoch. This is extremely useful for sorting distributions
based on their release date rather than the version string. Due to many authors
having different version schemes, this is perhaps the only reliable method with
which to sort distribution releases.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<CPAN::WWW::Testers>,
L<CPAN::Testers::WWW::Statistics>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2010 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
