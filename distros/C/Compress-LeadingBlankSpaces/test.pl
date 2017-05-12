# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 25 };
use Compress::LeadingBlankSpaces;
ok(1); # module is available ok.

my $dirty = "           header test\n";
my $clean = "header test\n";

# 2: Initiation group
my $compress_obj = Compress::LeadingBlankSpaces->new();
ok($compress_obj); # new() works 
my $status = $compress_obj->format_status();
# printf ("initial status = %s => ",$status);
ok ($status eq -1); # initial status is set properly
$status = $compress_obj->format_status(15);
ok ($status eq 15); # status is changed properly
$status = $compress_obj->format_status(-1);
my $temp = $compress_obj->squeeze_string($dirty);
ok ($temp eq $clean); # squeeze_string() works when (status == -1)

# 6: pure simple PRE
my $tag_pre = '<PRE>'."\n"; # pure simple
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$temp = $compress_obj->squeeze_string($dirty);
# printf ("'%s'",$temp);
ok ($temp eq $dirty); # squeeze_string() should not squeeze PRE
my $tag_pre_end = '</PRE>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre_end);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status is changed properly

# 9: PRE with parameters after a blank space on the same line
$tag_pre = '<PRE something>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 10: PRE with parameters after a tab on the same line
$tag_pre = '<PRE	something>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 11:
$tag_pre = '<PRE'."\n"; # the rest is on the next line...
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 12: new tag
$tag_pre = '<PRESCRIPT'."\n"; # 
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status should not change

# 13: It was a bug -- the capitalization was broken... 04/17/2004 fixed
$tag_pre = '<pre the following>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 14:
$tag_pre = '<TEXTAREA>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$tag_pre_end = '</TEXTAREA>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre_end);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status is changed properly

# 16:
$tag_pre = '<TEXTAREA something>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 17:
$tag_pre = '<textarea the following>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$tag_pre_end = '</textarea>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre_end);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status is changed properly
$tag_pre = '<textarea	followed with tab>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);
$tag_pre = '<textarea'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$status = $compress_obj->format_status(-1);

# 21:
$tag_pre = '<CODE>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$tag_pre_end = '</CODE>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre_end);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status is changed properly

# 23:
$tag_pre = '<code the following>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status >= 0); # status is changed properly
$tag_pre_end = '</code>'."\n";
$temp = $compress_obj->squeeze_string($tag_pre_end);
$status = $compress_obj->format_status();
# printf ("status = %s\n",$status);
ok ($status < 0); # status is changed properly

# 25:
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

