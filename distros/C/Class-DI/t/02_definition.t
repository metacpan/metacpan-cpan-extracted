use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok('Class::DI::Definition') };
my %config = (
	name => "hoge",
	class_name => "Hoge",
	injection_type => "setter",
	instance_type => "setter",
	properties => { 
		hoge1=>"hoge",
		hoge2=>[1,2,3],
		hoge3=>{hoge=>"hoge"},
	},
);

my $definition = new Class::DI::Definition(\%config);
is($definition->get_name,"hoge");
is($definition->get_class_name,"Hoge");
is($definition->get_injection_type,"setter");
is($definition->get_instance_type,"setter");
is_deeply($definition->get_properties,{
		hoge1=>"hoge",
		hoge2=>[1,2,3],
		hoge3=>{hoge=>"hoge"},
});

my %complex_config = (
	name => "hoge",
	class_name => "Hoge",
	injection_type => "setter",
	instance_type => "setter",
	properties => { 
		hoge1=>{
			class_name => "Fuga",
			properties => { "hoge"=>"hoge"}, 
		},
		hoge2=>[
			{hoge=>"hoge"},
			{
				class_name => "Fuga",
				properties => { "hoge"=>"hoge"}, 
			},
		],
		hoge3=>{
			hoge=>{
				class_name => "Fuga",
				properties => { "hoge"=>"hoge"}, 
			},
		},
	},
);


$definition = new Class::DI::Definition(\%complex_config);
is_deeply($definition->get_properties,{
		hoge1=>new Class::DI::Definition({
			class_name => "Fuga",
			properties => { "hoge"=>"hoge"}, 
		}),
		hoge2=>[
			{hoge=>"hoge"},
			new Class::DI::Definition({
				class_name => "Fuga",
				properties => { "hoge"=>"hoge"}, 
			}),
		],
		hoge3=>{
			hoge=>new Class::DI::Definition({
				class_name => "Fuga",
				properties => { "hoge"=>"hoge"}, 
			}),
		},
});

