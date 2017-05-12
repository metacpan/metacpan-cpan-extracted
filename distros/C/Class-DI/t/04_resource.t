use Test::More tests => 1;
use File::Temp;
BEGIN { use_ok('Class::DI::Resource::YAML') };
my $tmp  = new File::Temp;
my $yaml = <<__END_YAML__;
injections:
 - name: hoge
   class_name: Hoge
   injection_type: setter
   instance_type: singleton
__END_YAML__

print $tmp $yaml;
$tmp->close;

my $resource = Class::DI::Resource::YAML->new($tmp->filename);
is($resource->get_resource("hoge")->{name},"hoge");
