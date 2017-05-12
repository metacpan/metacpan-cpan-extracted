package CGI::WebToolkit::Modules::StringUtils;

sub stringify
{
	my ($wtk, $data, $type) = @_;
	
	my $formatters = {
		'date' =>
			sub {
				my ($time) = @_;
				my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
					= localtime($time);
				return ($year + 1900).'/'.($mon + 1).'/'.($mday);
			},
		'language' =>
			sub {
				my ($lang) = @_;
				my ($one, $two) = split /\_/, $lang;
				return $one.' ('.$two.')';
			},
		#'currency' =>
		#	sub {
		#		return '(not implemented)';
		#	},
		# ...
	};
	
	return
		(exists $formatters->{$type} ?
			$formatters->{$type}->($data) :
				''.$data);
}

1;
