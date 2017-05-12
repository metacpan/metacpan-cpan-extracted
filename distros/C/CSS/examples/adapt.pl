use CSS;
use Data::Dumper;

print(('='x60)."\n");

my $css_l = new CSS({'parser' => 'CSS::Parse::Lite'});
$css_l->read_file("t/css_simple");
print $css_l->output();

print(('='x60)."\n");

my $css_l = new CSS({'parser' => 'CSS::Parse::Lite', 'adaptor' => 'CSS::Adaptor::Pretty'});
$css_l->read_file("t/css_simple");
print $css_l->output();

print(('='x60)."\n");

my $css_l = new CSS({'parser' => 'CSS::Parse::Lite', 'adaptor' => 'CSS::Adaptor::Debug'});
$css_l->read_file("t/css_simple");
print $css_l->output();

print(('='x60)."\n");
