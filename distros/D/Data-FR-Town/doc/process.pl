#!/usr/bin/perl

use strict;
use warnings;

my $INSEE_URL  = "http://www.insee.fr/fr/methodes/nomenclatures/cog/telechargement/2012/txt/comsimp2012.zip";
my $POSTAL_URL = "";

my $INSEE_FILE  = "comsimp2012.txt";
my $POSTAL_FILE = "insee.csv";

my $fin;
my %DATA;

open $fin, "<", $INSEE_FILE or die "Can't open $INSEE_FILE ($!)";

# Skip header
my $line = <$fin>;

# $line = <$fin>;
# CDC CHEFLIEU    REG DEP COM AR  CT  TNCC    ARTMAJ  NCC ARTMIN  NCCENR
# 0   0   82  01  001 2   10  5   (L')    ABERGEMENT-CLEMENCIAT   (L') Abergement-Clémenciat
# 0   0   82  01  002 1   01  5   (L')    ABERGEMENT-DE-VAREY (L') Abergement-de-Varey
# 0   1   82  01  004 1   01  1       AMBERIEU-EN-BUGEY       Ambérieu-en-Bugey

while ( $line = <$fin> ) {
    chomp $line;
    if ( $line =~ /^\d+\s+\d+\s+\d{2}\s+(?<dep>\d{2,3})\s+(?<commune>\d{2,3})\s+\d{0,1}\s*\d{2}\s+\d\s+(?<complexe>.+)$/ ) {
        my $insee = $+{dep} . $+{commune};
        $DATA{insee}{$insee}{name} = $+{name};
        $DATA{insee}{$insee}{dep}  = $+{dep};
        $DATA{insee}{$insee}{source}++;
        $DATA{insee}{$insee}{origin}{"INSEE"} = 1;

        my $complexe = $+{complexe};
        if ( $complexe =~ /\s*(\(\S+\))\s+(\S+)\s+\((\S+)\)\s+(\S+)/ ) {
            $DATA{insee}{$insee}{article} = "$3";
            $DATA{insee}{$insee}{cname}   = "$2";
            $DATA{insee}{$insee}{name}    = "$4";
        } elsif ( $complexe =~ /^\s*(\S+)\s+(\S+)/ ) {
            $DATA{insee}{$insee}{article} = "";
            $DATA{insee}{$insee}{cname}   = "$1";
            $DATA{insee}{$insee}{name}    = "$2";
        } else {
            die "$line\ncomplexe=($complexe)\n";
        }

        if ( $DATA{insee}{$insee}{name} =~ /(.+)\s+(.+)/i ) {
            if ( uc($2) eq $1 ) {
                $DATA{insee}{$insee}{name} = $1;
            }
        }

    }
}

open $fin, "<", $POSTAL_FILE or die "Can't open $POSTAL_FILE ($!)";

# Skip header
$line = <$fin>;

# Commune;Codepos;Departement;INSEE

while ( $line = <$fin> ) {
    chomp $line;
    my ( $c, $zip, $dep, $insee ) = split ';', $line;
    $insee = sprintf( "%05d", $insee );
    $DATA{insee}{$insee}{zip}     = $zip;
    $DATA{insee}{$insee}{depname} = $dep;
    $DATA{insee}{$insee}{source}++;
    $DATA{insee}{$insee}{origin}{"POSTAL"} = 1;
}

for my $i ( keys %{ $DATA{'insee'} } ) {

    my %d = %{ $DATA{insee}{$i} };
    next unless $d{origin}{"INSEE"};

    print $i, ";", $d{article}, ";", $d{name}, ";", $d{cname}, ";", $d{zip}, ";", $d{dep}, ";", $d{depname}, ";", $d{origin}{"POSTAL"}, $/;

}

