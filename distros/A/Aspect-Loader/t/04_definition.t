use Test::More;
use File::Temp;
BEGIN { use_ok('Aspect::Loader::Definition') };


my $definition = Aspect::Loader::Definition->new({library=>"Singleton",call=>"Hoge::create"});
is($definition->get_library,"Singleton");
is($definition->get_call,"Hoge::create");
is($definition->get_class_name,"Hoge");

$definition = Aspect::Loader::Definition->new({library=>"Singleton",call=>"Hoge::Fuga::create"});
is($definition->get_library,"Singleton");
is($definition->get_call,"Hoge::Fuga::create");
is($definition->get_class_name,"Hoge::Fuga");

$definition = Aspect::Loader::Definition->new({library=>"Singleton",call=>"Hoge::Fuga::create",class_name=>"Hoge"});
is($definition->get_library,"Singleton");
is($definition->get_call,"Hoge::Fuga::create");
is($definition->get_class_name,"Hoge");
done_testing;
