#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '0.04';

#----------------------------------------------------------------------------

=head1 NAME

uploads-mailer.pl - Verify CPAN uploads and mails reports

=head1 SYNOPSIS

  perl uploads-mailer.pl [--log=<file>] [--out=<file>] [--last=<file>]

=head1 DESCRIPTION

Reads the uploads log and generates the emails for bad uploads to authors.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib);
use CPAN::Testers::Data::Uploads::Mailer;

# -------------------------------------
# Program

my $mailer = CPAN::Testers::Data::Uploads::Mailer->new();
$mailer->process();

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

F<http://www.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2010-2013 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
