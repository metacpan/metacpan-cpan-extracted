#!perl
use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '../lib');
binmode(STDOUT, ":utf8");

use Acme::HidamariSketch;

my $hidamari = Acme::HidamariSketch->new;
my @characters = $hidamari->characters;

# みんなの情報が見たい放題
foreach my $character (@characters) {
    printf "-----------------------\n";
    my $name     = $character->{name_ja}  ? $character->{name_ja}  : "undef";
    my $birthday = $character->{birthday} ? $character->{birthday} : "undef";
    my $sign     = $character->{sign}     ? $character->{sign}     : "undef";
    my $color    = $character->{color}    ? $character->{color}    : "undef";
    printf "name:        " . $name     . "\n";
    printf "birthday:    " . $birthday . "\n";
    printf "sign:        " . $sign     . "\n";
    printf "color:       " . $color    . "\n";
    printf "room_number:\n{\n";
    my $room_number = $character->{room_number};
    for my $year (qw/before first second third/) {
        if (defined $room_number->{$year}) {
            printf '  ' . $year . ': ' . $room_number->{$year} . "\n";
        }
        else {
            printf '  ' . $year . ": undef\n";
        };
    }
    printf "}\n";
}

