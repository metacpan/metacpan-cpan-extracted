use CSS;
use Data::Dumper;

my $css_l = new CSS({
	'parser'	=> 'CSS::Parse::Lite',
	'adaptor'	=> 'CSS::Adaptor::Fake',
});
$css_l->read_file("t/css_simple");
print Dumper($css_l);
