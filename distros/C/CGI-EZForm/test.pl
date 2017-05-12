#!/usr/local/bin/perl -w
#
# test script for CGI module
#

use CGI::EZForm;

# Create somewhere to put the form data
$form = new CGI::EZForm;

# Pre-set some form values
# Direct method ...
$form->{station} = 'JJJ';
# OOP method ...
$form->set(account => '654321', code => '911');

print "Content-type: text/html\r\n\r\n";

# Do standard HTTP stuff
$form->receive;

print "\n<pre>Data received is:\n\n";
$form->dump;
print "\n\n";

# Now let's print a form ...

print
    $form->form_start(action => '/cgi-bin/test.pl', name=>'myForm'),
    $form->draw(type => 'hidden', name => 'code'),
    $form->draw(type => 'text', name => 'account',
	label => 'Account number', size => 30),
    $form->draw(name => 'name', label => 'Your name'),
    $form->draw(type => 'checkbox', name => 'spam',
	label => 'Send me spam?',
	caption => '<small>click here to receive junk mail</small>'),
    $form->draw(type => 'radio', name => 'station',
	label => 'What\'s your favourite radio station?',
	values => ['JJJ', 'MMM'],
	captions => ['Triple-J', 'Triple-M']),
    $form->draw(type => 'select', name => 'choice', label => 'Choose',
	multiple => 1,
	selected => ['one', 'three'],
	options => ['First', 'Second', 'Third'],
	values => ['one', 'two', 'three']),
    $form->draw(type => 'submit', name => 'Send'),
    $form->draw(type => 'reset'),
    $form->form_end;

exit;

