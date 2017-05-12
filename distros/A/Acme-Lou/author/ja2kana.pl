use strict;
use utf8;
use Fatal qw(open close);
use FindBin qw($Bin);
use Encode;

my %en2kana;
open my $en2kana, '<:encoding(utf8)', "$Bin/lou-en2kana.csv";
while (<$en2kana>) {
    chomp;
    next unless $_;
    next if /^#/;
    my ($en, $kana) = split ',';
    $en2kana{lc $en} = $kana;
}

my %skip_word = map { $_ => 1 } qw(
    now say new be come see is as
    one two three four five
    six seven eight nine ten
    law raw row whole weigh
    hurt hut firm fare flesh
    youth lack role waste worth
    few pray health sex
);

warn "make $Bin/lou-ja2kana.csv...\n";
open my $ja2kana, '>:encoding(utf8)', "$Bin/lou-ja2kana.csv";

print {$ja2kana} <<'HEADER';
# lou-ja2kana.csv
# Copyright 2007 Naoki Tomita <tomita@cpan.org>
# License: GPL
#
# This dictionary is based on the following resource.
# - lou-en2kana.csv (Acme::Lou)
# - edict
#   Copyright (C) 2006 The Electronic Dictionary Research 
#   and Development Group, Monash University.

HEADER
;

open my $edict, '<:encoding(euc-jp)', "$Bin/edict";
LINE: while (<$edict>) {
    chomp;
    next if $. == 1;
    $_ = lc $_;
    
    #next if / \(1\) /; 
    
    s/\([^\)]+\)//g;
    s/\[[^\]]+\]//g;
    s#\s+/#/#g;
    s#/\s+#/#g;
    
    s#/to #/#g;
    s#/be #/#g;
    s#/the #/#g;
    s#/current/present/#/current/#; 
    s#/all/everyone#/everyone#;
    s#/man/person/#/human/#;
    s#/say/tell/state/##;
     
    s#/[\d\s\W]+/#/#g;
    s#//#/#g;
    s#/$##;
    
    my @en = split '/';
    my $ja = shift @en;

#     next if length $ja <= 1;
    next if $ja =~ /^\p{InKatakana}+$/;
    next if $ja !~ /\p{InHiragana}|\p{InCJKUnifiedIdeographs}/;
    
    next if $ja eq 'いく';
    next if $ja eq 'そう';
    next if $ja eq 'くる';
    next if $ja eq '来る';
    next if $ja eq 'みる';
    next if $ja eq 'いる';
    next if $ja eq 'あの';
    next if $ja eq 'その';
    
    PHRASE: for my $en (@en) {
        next if $skip_word{$en};
        next if $en =~ /,/;

        if ($en2kana{$en}) {
            print {$ja2kana} "$ja,$en2kana{$en}\n"; 
            next LINE;
        }
         
        my @words = split / /, $en;
        
        next PHRASE if @words > 3;
        
        for (@words) {
            next PHRASE unless exists $en2kana{$_};
            $_ = $en2kana{$_};
        }
        
        printf {$ja2kana} "%s,%s\n", $ja, join(" ", @words);
        next LINE; 
    }
}
