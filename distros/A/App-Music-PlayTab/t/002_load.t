#! perl

use strict;
use warnings;
use Test::More;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";

$::__EMBEDDED__ = 1;

my $test;

++$test; use_ok("App::Music::PlayTab");
++$test; use_ok("App::Music::PlayTab::Chord");
++$test; use_ok("App::Music::PlayTab::LyChord");
++$test; use_ok("App::Music::PlayTab::Note");
++$test; use_ok("App::Music::PlayTab::NoteMap");
++$test; use_ok("App::Music::PlayTab::Output");
++$test; use_ok("App::Music::PlayTab::Output::Dump");
++$test; use_ok("App::Music::PlayTab::Output::PDF");
++$test; use_ok("App::Music::PlayTab::Output::PostScript");
++$test; use_ok("App::Music::PlayTab::Output::PostScript::Preamble");
++$test; use_ok("App::Music::PlayTab::Version");

diag( "Testing App::Music::ChordPro $App::Music::PlayTab::VERSION, Perl $], $^X" );

done_testing($test);


