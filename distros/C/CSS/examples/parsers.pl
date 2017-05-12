use CSS;
use Data::Dumper;

my $css_l = new CSS({'parser' => 'CSS::Parse::Lite'});
$css_l->read_file("t/css_simple");
serialize($css_l);

my $css_h = new CSS({'parser' => 'CSS::Parse::Heavy'});
$css_h->read_file("t/css_simple");
serialize($css_h);

my $css_c = new CSS({'parser' => 'CSS::Parse::Compiled'});
$css_c->read_file("t/css_simple");
serialize($css_c);

sub serialize{
	my ($obj) = @_;

	for my $style (@{$obj->{styles}}){
		print join ', ', map {$_->{name}} @{$style->{selectors}};
		print " { ";
		print join ' ', map {$_->{property}.': '.(join '', map{$_->{value}}@{$_->{values}}).';'} @{$style->{properties}};
		print " }\n";
	}
	print "\n";
}
