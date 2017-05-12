my ($data) = @args;

my $data_defaults = {
	'content' => '',
	'lang'    => lang(),
};
my $params = CGI::WebToolkit::__parse_params( $data, $data_defaults );

# try to translate phrase
return _($params->{'content'}, $params->{'lang'});
