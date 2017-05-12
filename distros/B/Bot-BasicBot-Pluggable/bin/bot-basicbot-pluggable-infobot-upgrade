#!/usr/bin/perl
use warnings;
use strict;
use Storable qw(retrieve nstore);
use File::Copy qw( cp );

unless (-e "Infobot.storable") {
  die "I can't see Infobot.storable in ./\n";
}

if (-e "Infobot.storable.backup") {
  die "There's already a backup of Infobot.storable in ./\n";
}

cp("Infobot.storable", "Infobot.storable.backup")
  or die "Can't back up Infobot.storable: $!\n";

unless (-s "Infobot.storable" == -s "Infobot.storable.backup") {
  die "Infobot.storable backup isn't the same size!\n"
}

my $data = retrieve("Infobot.storable")
  or die "Can't load Infobot.storable for some reason\n";

my $new;
warn "converting...\n";
for my $factoid (keys %{  $data->{infobot}  }) {
  $new->{ "infobot_$factoid" } = delete $data->{infobot}{$factoid};
}

nstore($new, "Infobot.storable");
warn "Saved new Infobot.storable\n";
