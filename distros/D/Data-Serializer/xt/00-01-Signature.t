use lib "./t";             # to pick up a ExtUtils::TBone
use ExtUtils::TBone;

##
## This is a placeholder test - When I get around to making a signature, I'll test it here
##
my $T = typical ExtUtils::TBone;                 # standard log
$T->begin('0');
$T->msg("This is a palceholder for when this module actually has a signature");  # message for the log

#my $T = typical ExtUtils::TBone;                 # standard log
#
#my $mod_sig = (eval { require Module::Signature; 1 });
#unless ($mod_sig) {
#        $T->begin('0 # Skipped:  Module::Signature not installed');
#        exit;
#}
#unless (-e 'SIGNATURE') {
#        $T->begin('0 # Skipped:  No signature!');
#        exit;
#}
#
#$T->begin('1');
#$T->msg("Comparing Signature");  # message for the log
#$T->ok_eq(Module::Signature::verify(),Module::Signature::SIGNATURE_OK(), 'Signature');


#use Test::More tests => 1;
#
#SKIP: {
#    skip( 'No signature!', 1 ) unless -e 'SIGNATURE';
#    if (eval { require Module::Signature; 1 }) {
#        ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
#            => "Valid signature" );
#    }
#    else {
#        diag("Next time around, consider install Module::Signature,\n".
#             "so you can verify the integrity of this distribution.\n");
#        skip("Module::Signature not installed", 1)
#    }
#}

__END__
