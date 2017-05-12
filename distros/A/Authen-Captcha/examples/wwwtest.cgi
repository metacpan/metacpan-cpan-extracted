#!/usr/bin/perl

use strict;
use CGI qw(:standard);
use Authen::Captcha;

my $output_dir = "/var/www/html/captcha";
my $www_output_dir = "/captcha";
my $db_dir = "/var/www/captchadb";
my $num_of_characters = 5;

my $captcha = Authen::Captcha->new(
                      output_folder	=> $output_dir,
                      data_folder	=> $db_dir
                      );

&main;

sub main
{
	# import any get or post variables into the Q namespace
	&load_cgi_variables();

	if ($Q::code && $Q::crypt)
	{
		&check_code($Q::code, $Q::crypt);
	} else {
		&default;
	}
}

sub default
{
	my $md5sum = $captcha->generate_code($num_of_characters);
	print header;
	print "<HTML><HEAD></HEAD><BODY><FORM METHOD=post>
	<INPUT TYPE=hidden name=crypt value=\"$md5sum\">
	Please enter the characters in the image below: <INPUT TYPE=text name=code>
	<BR>
	<IMG SRC=\"$www_output_dir/$md5sum.png\"><BR>
	<INPUT TYPE=submit>
	</FORM></BODY></HTML>\n";
}

sub check_code
{
	my ($code,$md5sum) = @_;
	my $results = $captcha->check_code($code,$md5sum);

	# $results will be one of:
	my %result = (
		1	=> 'Passed',
		0	=> 'Code not checked (file error)',
		-1	=> 'Failed: code expired',
		-2	=> 'Failed: invalid code (not in database)',
		-3	=> 'Failed: invalid code (code does not match crypt)',
		);

	print header;
	print "<HTML><HEAD></HEAD><BODY>Result was:<BR>\n";
	print "$results : $result{$results}\n";
	print "</BODY></HTML>\n";
}

sub load_cgi_variables
{
	my $cgi = new CGI;
	$cgi->import_names('Q');
}
