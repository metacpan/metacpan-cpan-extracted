#!/usr/bin/env perl
# player.pl     pajas@ufal.mff.cuni.cz     2007/07/20 15:26:41

our $VERSION="0.1";

use warnings;
use strict;
$|=1;

use Getopt::Long;
use Pod::Usage;
Getopt::Long::Configure ("bundling");
my %opts;
GetOptions(\%opts,
#	'debug|D',
#	'quiet|q',
	'help|h',
	'usage|u',
        'version|V',
	'man',
       ) or $opts{usage}=1;

if ($opts{usage}) {
  pod2usage(-msg => 'player.pl');
}
if ($opts{help}) {
  pod2usage(-exitstatus => 0, -verbose => 1);
}
if ($opts{man}) {
  pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version}) {
  print "$VERSION\n";
  exit;
}

use Audio::aKodePlayer;

my ($file,$seek,$speed)=@ARGV;

my $player = Audio::aKodePlayer->new;
print "status: ",$player->state,"\n";
$player->open('oss') || die "open sink failed\n";
$player->load($file)  || die "loading failed\n";
if (defined $speed) {
#  $player->setResamplerPlugin('fast') || warn("setting resampler failed\n");
#  $player->setSpeed($speed);
  $player->setVolume($speed);
}
$player->play;
$player->seek(($seek||0)*1000) || warn("seek failed\n");
sleep 1;
print "detaching\n";
$player->detach();
$player->stop;
while (1) {
  print $player->position/1000 . " of ". $player->length/1000 . " sec\n";
  $player->wait();
  sleep 1;
}
$player->stop;
$player->unload;
$player->close;


__END__

=head1 NAME

player.pl

=head1 SYNOPSIS

player.pl 
or
  player.pl -u          for usage
  player.pl -h          for help
  player.pl --man       for the manual page
  player.pl --version   for version

=head1 DESCRIPTION

Stub documentation for player.pl, 
created by template.el.

=over 5

=item B<--usage|-u>

Print a brief help message on usage and exits.

=item B<--help|-h>

Prints the help page and exits.

=item B<--man>

Displays the help as manual page.

=item B<--version>

Print program version.

=back

=head1 AUTHOR

Petr Pajas, E<lt>pajas@sup.ms.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Petr Pajas

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
