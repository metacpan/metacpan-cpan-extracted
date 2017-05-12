#!/usr/bin/perl -w

my $loaded;

use strict;

my $test = 0;
BEGIN { $| = 1; print "1..4\n"; }
END { print "not ok 1\n" unless $loaded; }

use Acme::Scurvy::Whoreson::BilgeRat;

$loaded=1;
print "ok ".(++$test)."\n";

my $insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new(language => 'pirate');
print 'not ' unless($insultgenerator->isa('Acme::Scurvy::Whoreson::BilgeRat'));
print "ok ".(++$test)."\n";

eval '$insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new(fuck => "cunt")';
print 'not ' unless($@);
print "ok ".(++$test)."\n";

$insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new();
print 'not ' unless($insultgenerator->isa('Acme::Scurvy::Whoreson::BilgeRat'));
print "ok ".(++$test)."\n";
