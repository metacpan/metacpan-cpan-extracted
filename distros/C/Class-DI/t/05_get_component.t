use Test::More tests => 7;
use File::Temp;
BEGIN { use_ok('Class::DI') };
my $tmp  = new File::Temp;
my $yaml = <<__END_YAML__;
injections:
 - name: hoge
   class_name: Class::DI::Definition
   injection_type: setter
   instance_type: prototype
   properties:
     name: hoge
 - name: fuga
   class_name: Class::DI::Definition
   injection_type: setter
   instance_type: singleton
   properties:
     name: fuga
 - name: hogehoge
   class_name: Class::DI::Definition
   injection_type: constructer
   instance_type: singleton
   properties:
     name: fugafuga
 - name: nested
   class_name: Class::DI::Definition
   injection_type: constructer
   instance_type: singleton
   properties:
     name: 
       name: child
       class_name: Class::DI::Definition
       injection_type: constructer
       instance_type: singleton
       properties:
         name: child

__END_YAML__

print $tmp $yaml;
$tmp->close;

my $di = Class::DI->yaml_container($tmp->filename);
is($di->get_component("hoge")->get_name,"hoge");
is($di->get_component("fuga")->get_name,"fuga");
is($di->get_component("hogehoge")->get_name,"fugafuga");
is($di->get_component("nested")->get_name->get_name,"child");

my $instance = $di->get_component("hoge")->set_name("hogehoge");;
is($di->get_component("hoge")->get_name,"hoge");

$instance = $di->get_component("fuga")->set_name("hogehoge");;
is($di->get_component("fuga")->get_name,"hogehoge");

