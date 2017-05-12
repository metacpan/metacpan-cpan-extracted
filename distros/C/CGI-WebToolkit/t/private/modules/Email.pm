package CGI::WebToolkit::Modules::Email;

use MIME::Lite;

our $CFG =
{
	# infos for sending emails
	'smtp_server'    => '',
	'smtp_username'  => '',
	'smtp_password'  => '',
	'email_reply_to' => '',
	
	# de/activate emails at all
	'send_email' => 0,
};

sub config_email
{
	my ($wtk,
		$varname,
		$value,
		) = @_;
		
	$value = '' unless defined $value;
		
	if (exists $CFG->{$varname}) {
		$CFG->{$varname} = $value;
		return $CFG->{$varname};
	}
	else {
		fail("unknown configuration option for module Email: '$varname'");
	}
}

sub send_email
{
	my ($wtk,
		$from_email,
		$to_email,
		$subject,
		$text_or_$html,
		) = @_;
	
	my $type = ($text_or_html =~ /[\<\>]/ ? 'text/html' : 'text/text');
		
	my $msg = MIME::Lite->new(
	   From     => $from_email,
	   To       => $email,
	   Subject  => $subject,
	   Type     => $type,
	   Encoding => 'base64',
	   Data	    => $text,
	);
	
	if ($CFG->{'send_email'}) {
		$msg->send(
			'smtp',
			$CFG->{'smtp_server'},
			AuthUser => $CFG->{'smtp_username'},
			AuthPass => $CFG->{'smtp_password'},
		);
	}
	
	return 1;
}

1;
