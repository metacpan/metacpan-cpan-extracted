# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Audio::Mixer;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print STDERR "Opening mixer...  ";
$ret = Audio::Mixer::init_mixer();
print STDERR $ret ? "FAILED.\n" : "Ok.\n";

print STDERR "Getting the volume... ";
my @old = Audio::Mixer::get_cval('vol');
print STDERR join(', ', @old)." Ok.\nSetting to 50... ";
Audio::Mixer::set_cval('vol', 50);
my @ret = Audio::Mixer::get_cval('vol');
print STDERR ($ret[0] == 50 && $ret[1] == 50) ? "Ok.\nResetting back... " :
    "FAILED.\nTrying to reset back... ";
Audio::Mixer::set_cval('vol', $old[0], $old[1]);
@ret = Audio::Mixer::get_cval('vol');
print STDERR ($ret[0] == $old[0] && $ret[1] == $old[1]) ?
    "Ok.\n" : "FAILED.\n";

#my $ret = Mixer::get_cval('vol');
#printf "get_cval() vol=0x%x\n", $ret;

#$ret = Mixer::set_cval('vol', 50);
#print "set_cval returns $ret\n";

#@ret = Mixer::get_cval('vol');
#print "get_cval() vol=".join(', ', @ret)."\n";
#$ret = Mixer::get_cval('vol');
#printf "get_cval() vol=0x%x\n", $ret;


#$ret = Mixer::get_param_val('vol');
#printf "get_param_val() vol=0x%x\n", $ret;

#$ret = Mixer::set_param_val('vol', 20, 50);
#print "set_param_val returns $ret\n";

#$ret = Mixer::get_param_val('vol');
#printf "get_param_val() vol=0x%x\n", $ret;

#@ret = Mixer::get_mixer_params();
#print "== ".join(',', @ret)." ==\n";

