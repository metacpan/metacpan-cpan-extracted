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
	'seek|s=i',
	'volume|v=i',
	'rate|r=i',
	'list-plugins|l',
	'help|h',
	'usage|u',
        'version|V',
	'man',
       ) or $opts{usage}=1;

if ($opts{usage}) { pod2usage(-msg => 'player.pl');             }
if ($opts{help})  { pod2usage(-exitstatus => 0, -verbose => 1); }
if ($opts{man})   { pod2usage(-exitstatus => 0, -verbose => 2); }
if ($opts{version}) { print "$VERSION\n"; exit; }

use Audio::aKodePlayer;
use IO::Select;
my $select = IO::Select->new( \*STDIN );

if ($opts{'list-plugins'}) {
  print "PLUGINS:\n";
  print map { "  ".$_."\n" } Audio::aKodePlayer::listPlugins();
  print "DECODERS:\n";
  print map { "  ".$_."\n" } Audio::aKodePlayer::listDecoders();
  print "SINKS:\n";
  print map { "  ".$_."\n" } Audio::aKodePlayer::listSinks();
}

my $player = Audio::aKodePlayer->new();

sub position {
  print "Playback position: ".($player->position()/1000)." seconds of ".($player->length()/1000)."\r";
}

  $player->open('auto') || die "Cannot output any audio output sink\n"; # automatically selected output sink
  while (@ARGV) {
    my $file = shift;
    $player->load( $file ) || die "Cannot load $file\n"; # any format supported by aKode
    $player->setSampleRate($opts{rate}) if defined $opts{rate};
    $player->play();
    $player->pause();
    $player->setVolume(100*$opts{volume}) if defined $opts{volume};
    print "Software volume is at ".($player->volume()*100)."%\n";
    $player->seek($opts{seek}*1000) if $player->seekable and defined $opts{seek};
    position();
    $player->resume();
    while (!$player->eof) {
      position();
      if ($select->can_read(1)) {
	<>; $player->pause();
	print "\nPaused"." "x50,"\r";
	if ($select->can_read()) {
	  print "\nResuming"." "x50,"\n";
	  <>; $player->resume();
	}
      }
    }
    $player->wait;   # idle until the playback stops
    position();
    print "\nDone.\n";
    $player->stop;   # stop playback
    $player->unload; # release resources related to the media
  }
  $player->close;  # release resources related to the the output sink


__END__

=head1 NAME

player.pl - a simple Audio::aKodePlayer based player

=head1 SYNOPSIS

player.pl [--volume 0-100] [--seek sec] audiofile ...
or
  player.pl -u          for usage
  player.pl -h          for help
  player.pl --man       for the manual page
  player.pl --version   for version

=head1 DESCRIPTION

Stub documentation for player.pl, 
created by template.el.

=over 5

=item B<--volume|-v> volume

Play at a given software volume (in percent).

=item B<--seek|-s> seconds

Start playback from a given position in the audio.

=item B<--rate|-r> rate

Set sample rate.

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
