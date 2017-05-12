#!/usr/bin/perl
use Ante::Deluvian::Dialog;
use Data::Dumper;
use IO::File;

my ($FALSE, $TRUE) = (0, 1);
my $isWin  = $FALSE;
my $pltFrm = $^O;
if ($pltFrm =~ /win32/i) {
  $pltFrm = "MSWIN";
  $isWin  = $TRUE;
  binmode(STDOUT, ":encoding(cp437)");  # für die korrekte Darstellung deutscher Umlaute
}
else {
  $pltFrm = "UNIX";
}
my $ed = Ante::Deluvian::Dialog->new(
          platform  => $pltFrm,
          drawframe => $TRUE,
          title     => "Fenster-Überschrift",
          header    => "Das ist der sog. Kopf",
          prompt    => "Bitte wählen Sie:",
          # record    => 1,
        );

# print "Fenstergröße: $ed->{'cols'} Spalten und $ed->{'rows'} Zeilen ...\n";
$ed->_getinput();
# print Dumper $ed;
my $fdir  = $ed->dselect();
print "Selektiert wurde das Verzeichnis $fdir ...\n";
# my $fname = $ed->fselect("E:/");
my $fname = $ed->fselect();
print "Selektiert wurde die Datei $fname ...\n";
my @aLst = ( "A" .. "Z", "a" .. "z" );
my @aRes = $ed->listbox(\@aLst, undef, select => "single");
# my @aRes = $ed->listbox(\@aLst, undef, select => "multi");
foreach my $elm (@aRes) {
  print "RES: $elm\n";
}
my $rd = $ed->radiolist([
								[ "Radioliste", 1, ],
								[ "rot",  "RED", 0 ],
								[ "grün", "GRN", 1 ],
								[ "blau", "BLU", 0 ],
								[ "gelb", "YLW", 0 ],
							 ]);
$ed->alert([
	"Press <RETURN> to continue ...",
	"Achtung! Hierbei handelt es sich",
	"um eine Alert-Box (siehe unten) ...",
	"Die Radioliste ergab $rd",
]);

if (-T $fname) {
  my $inpf = IO::File->new($fname);
  $ed->textbox($inpf);
}
else {
  $ed->textbox($fname);
}

exit();
