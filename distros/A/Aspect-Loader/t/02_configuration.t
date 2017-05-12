use Test::More tests => 3;
use File::Temp;
BEGIN { use_ok('Aspect::Loader::Configuration::YAML') };
my $tmp  = new File::Temp;
my $yaml = <<__END_YAML__;
aspects:
 - library: Singleton
   call: Hoge::create
__END_YAML__

print $tmp $yaml;
$tmp->close;

my $configuration = Aspect::Loader::Configuration::YAML->new($tmp->filename);
is($configuration->get_configuration->[0]->{library},"Singleton");
is($configuration->get_configuration->[0]->{call},"Hoge::create");
