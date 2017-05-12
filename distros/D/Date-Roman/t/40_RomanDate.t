use Test::More tests => 2;

$ENV{PATH} = "./blib/script/:" . $ENV{PATH};


is(`RomanDate 19 7 1961`,"a.d. XIV Kal. Aug. MMDCCXIV AUC\n");
is(`RomanDate --args words=complete --args auc=abbrev 19 7 1961`,
   "ante diem XIV Kalendas Augustas MMDCCXIV AUC\n");
