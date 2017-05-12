# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# --- if the tests are failing, try to comment out the following line
BEGIN { delete $ENV{PERL_DL_NONLAZY}; };

use Test;
BEGIN { plan tests => 12 };
use Bio::Emboss qw(:all);

ok(1); # If we made it this far, we're ok.

$seqasis = "MMSARGDFLNYALSLMRSHNDEHSDVLPVLDVCSLKHVAYVFQALIYWIK" .
           "AMNQQTTLDTPQLERKRTRELLELGIDNEDSEHENDDDTSQSATLNDKDD",

embInitPerl("seqret", [ "asis::$seqasis", qw(-stdout -auto)]); 

ok(1);

$seqall = ajAcdGetSeqall("sequence"); 
ok(defined $seqall);
ok(ref ($seqall), "Bio::Emboss::Seqall");

$seqout = ajAcdGetSeqoutall("outseq"); 
ok(defined $seqout);
ok(ref ($seqout), "Bio::Emboss::Seqout");

$firstonly = ajAcdGetBool ("firstonly");
ok(defined $firstonly);


$seqobj = ajSeqNew();
ok(defined $seqobj);
ok(ref ($seqobj), "Bio::Emboss::Seq");

$seqobj->ajSeqAssignSeqC($seqasis);
ok ($seqobj->ajSeqIsProt());

$seqobj2 = ajSeqNew();

$seqall->ajSeqallNext($seqobj2);

ok($seqobj->ajSeqGetLen(), $seqobj2->ajSeqGetLen());

ok ($seqobj->ajSeqGetSeqC(), $seqobj2->ajSeqGetSeqC());


