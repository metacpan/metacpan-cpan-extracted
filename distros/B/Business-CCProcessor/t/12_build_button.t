#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 9;
use Test::HTML::Lint;
use WWW::Mechanize;
# my $agent = WWW::Mechanize->new();
use lib qw{t};
use MyMech;
my $agent = MyMech->new();

use lib qw{lib};
use Business::CCProcessor;

SKIP:
{
    eval 'use Test::HTML::Tidy';
    skip('This test requires Test::HTML::Tidy, which is not available.',1) if $@;
    my $tidy = HTML::Tidy->new();
    # $tidy->ignore( 'type' => 'TIDY_WARNING' );
    $tidy->ignore( 'text' => [ qr/<input> attribute "id"/, qr/<table> lacks "summary"/ ] );
}
my $cc = Business::CCProcessor->new();
isa_ok($cc,'Business::CCProcessor', "Constructor returned correct object.");

my ($form,$fields,%fields,$method,%data,$key);
my ($processor_settings,$html);
my $credit_card_owner = populate_credit_card_owner();

foreach $method ('dia','paypal','verisign'){
  $processor_settings = populate_processor_settings($method);
  %data = (
    'processor_settings' => $processor_settings,
     'credit_card_owner' => $credit_card_owner,
      );

    $html =<<EOHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>Testing \$cc->$method() method</title>
</head>
<body>
EOHTML

    $html .= $cc->button_factory(\%data);
    # $html .= $form->render();
    $html .=<<EOHTML;
</body></html>
EOHTML

    html_ok($html,"This test rendered well formed html for \$cc->$method().");
SKIP:
{
    eval 'use Test::HTML::Tidy';
    if ($@) {
      skip('This test requires Test::HTML::Tidy, which is not available.',1) 
    }; 
    my $tidy = HTML::Tidy->new();
    $tidy->clean( $html );
}

SKIP:
{
    eval 'use Test::HTML::Tidy';
    if (defined($@)) {
      skip('This test requires Test::HTML::Tidy, which is not available.',1) 
    } else {
      skip("The html generated is not html_tidy compliant, yet.",1);
    }
    html_tidy_ok($html);
}

    open('FH','>',"test-$method.html");
    print FH $html;
    close(FH);

    if($method eq 'verisign'){
    # } elsif(1 == 0){
      $agent->add_header( 'HTTP_REFERER' => 'http://cagreens.org/donate/' );
      $agent->get('http://www.greens.org');
      $agent->update_html($html);
#      diag("Next, we submit the form.");
#      $agent->submit_form(
#               form_name => 'ProceedToCCProcessor',
#               button    => '_submit'
#           );
#      diag("Now we test the results.");
SKIP:
{
        local $TODO = "Tests of verisgn method not yet working.";
        skip("Tests of verisgn method not yet working.",2);
        like($agent->content(),qr/Cards Accepted - Visa - MasterCard - /,'Successfully found credit card processor.');
        like($agent->content(),qr/Green Party of California/,'  .  .  .  and it seems to be the correct credit card processor.');
}
    }

}


# $agent->get('/home/hesco/sb/Business-CCProcessor/test-verisign.html');

1;

sub populate_processor_settings {
  my ($method) = @_;

  my(%processor_settings);

  if($method eq 'dia'){

    %processor_settings = (
         'processor' => 'dia',
            'action' => '', # <-- url of web form posted to
   'donate_page_KEY' => '1239', # <-- provider account specific page ID
      'button_label' => 'Donate Online with DiA!', #<-- what to call the button
        );

  } elsif($method eq 'paypal'){

    %processor_settings = (
              'processor' => 'paypal',
                 'action' => '', # <-- url of web form posted to
               'business' => 'GGPTreasurer@gmail.com', # <-- email address registered with paypal
              'item_name' => 'Donation to the Georgia Green Party', # <-- description of transaction
             'return_url' => 'http://www.accgreens.org/gpga/thankyou.php', # <-- url on your site to return to
      'cancel_return_url' => 'http://www.accgreens.org/gpga/supporters.cgi', # <-- url on your site to error out to
          'currency_code' => 'USD', # <-- EUR, USD, CAD etc.
           'button_label' => 'Donate Online with Paypal!', #<-- what to call the button
               );

  } elsif($method eq 'verisign'){

    %processor_settings = (
                    'processor' => 'verisign',
                       'action' => '', # <-- url of web form posted to
                        'login' => 'calgreens', # <-- account id
                  'description' => 'Donation to Green Party of California', # <-- description of transaction
                 'button_label' => 'Donate Now', # <-- what to call the button
                 # 'button_label' => 'Donate Online with VeriSign', # <-- what to call the button
               );

  } else {

    my $errors .= 'Cannot return settings for an undefined credit card processor';
    %processor_settings = ( 'errors' => $errors );
    print STDERR $errors,'\n';

  }

  return \%processor_settings;
}

sub populate_credit_card_owner {
  my %credit_card_owner = (
                     'fname' => 'Testy',
                     'lname' => 'Tester',
                     'addr1' => '123 Main Street',
                     'addr2' => '',
                      'city' => 'Decatur',
                     'state' => 'GA',
               'postal_code' => '30033',
                 'comments1' => 'some comments',
                 'comments2' => 'some more comments',
                     'phone' => '770-755-1543',
                     'email' => 'hesco@campaignfoundations.com',
                  'employer' => 'boss',
                'occupation' => 'work',
                    'amount' => '1.00',
                     'notes' => 'some notes',
               );
  return \%credit_card_owner;
}

