use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY);

plan tests => 15;

my $text1 = GET_BODY '/4.html';
my $text2 = GET_BODY '/4.html?texttest=something%20else';
my $text3 = GET_BODY '/4.html?_current_form=test&_submitted=1&texttest=something%20else';
my $crypto_string = $text3;
$crypto_string =~ s/.+"_storage"\s+value="([^"]+)".+/$1/s;
my $text4 = GET_BODY '/4.html?_current_form=test2&_submitted=1&_storage=' . $crypto_string;
$crypto_string = $text4;
$crypto_string =~ s/.+"_storage"\s+value="([^"]+)".+/$1/s;
my $text5 = GET_BODY '/4.html?_current_form=test2&_submitted=1&texttest=new%20text&_storage=' . $crypto_string;
my $text6 = GET_BODY '/4.html?_current_form=test3&_submitted=1&texttest=new%20text&_storage=' . $crypto_string;
my $text7 = GET_BODY '/4.html?_current_form=test3&_submitted=1';

#1 form creation
ok ($text1 =~ /_current_form/);
#2 text input generation
ok ($text1 =~ /name="texttest"/);
#3 radiobutton set generation
ok ($text1 =~ /value="option3">Option Three/);
#4 text input default value
ok ($text1 =~ /name="texttest"[^>]+value="testing text"/s);
#5 CGI overrides default
ok ($text2 =~ /name="texttest"[^>]+value="something else"/);
#6 complex form progression
ok ($text3 =~ /test2/s);
#7 crypto storage completes
ok ($text4 =~ /name="texttest"[^>]+value="something else"/s);
#8 CGI overrides crypto storage
ok ($text5 =~ /name="texttest"[^>]+value="new text"/s);
#9 form completes
ok ($text6 =~ /Finished./s);
#10 order by key for Set
ok ($text1 =~ /option3.+option4/s);
#11 order by value for Set
ok ($text3 =~ /option4.+option3/s);
#12 Default radio buttons
ok ($text1 =~ /name="radiotest"[^>]+value="option1"[^>]+checked/s);
#13 Default selections
ok ($text1 =~ /value="option3"[^>]+selected[^>]*>Option Three<\/option>/s);
#14 Default checkboxes
ok ($text1 =~ /value="option4"[^>]+checked[^>]*>Option Four/s);
#15 Array variables are handled properly
ok ($text7 =~ /pulldown test value: \n/);
