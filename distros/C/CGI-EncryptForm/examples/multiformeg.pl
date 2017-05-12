#!/usr/local/bin/perl

use CGI::EncryptForm;
use CGI;
use vars qw($cgi, $cfo);

$cgi = new CGI();
$cfo = new CGI::EncryptForm(secret_key => 'blah');

print $cgi->header(), $cgi->start_html(), $cgi->start_form();

if (defined $cgi->param('enc')) {
  form3();
}
elsif (defined $cgi->param('something')) {
  form2();
}
else {
  form1();
}

print $cgi->end_html(), $cgi->end_form();

sub form1 {

  print "<h1>form1</h1>",
        "Type something and we will remember it: ",
        $cgi->textfield('something'), $cgi->submit();
}

sub form2 {

  print "<h1>form2</h1>",
        $cgi->hidden(-name=>'enc', value=>$cfo->encrypt({ $cgi->Vars })),
        "Now click here and I will tell you what you typed based on ",
        "the encrypted hidden form field, which you would normally ",
        "only see if you view the HTML source. For the sake of this ",
        "demonstration the encrypted field is included below.<p>",
        $cfo->encrypt(), "<p>",
        "Before proceeding with this form I suggest you take note of ",
        "what the encrypted field looks like, then click the back ",
        "button and resubmit the previous form with the same value ",
        "again. What you will notice is the encrypted field will ",
        "change. This is because the SHA encryption algorithm is ",
        "based on a secret key and a random key. In the module we ",
        "take care of generating a unique random key for each ",
        "invocation of the encryption routine, which is why a ",
        "distinct encrypted string is produced each time.",
        "<p>",
				"<a href=\"/cgi-bin/encform_eg?enc=", $cfo->encrypt(), "\">Click here to try the URL instead of the form </a>",
				$cgi->submit(-value=>'Click here to try the form');
}

sub form3 {

  my $hashref = $cfo->decrypt($cgi->param('enc'));
  if (!defined $hashref) {
    print $cfo->error();
    return;
  }
	my $type = $ENV{'QUERY_STRING'} ? 'URL key' : 'hidden form field';
  print "<h1>form3</h1>",
        "Previously in the first form you typed:<p>",
				$hashref->{something},
        "<p>We reproduced this data by decrypting the $type",
        " called 'enc', which was passed to us from the previous ",
        "form. You may like to try and tamper with the $type ",
        "in form2, to see if you can alter the result of the ",
        "data as it originally flows from form 1 to form 3. Good luck";
}
