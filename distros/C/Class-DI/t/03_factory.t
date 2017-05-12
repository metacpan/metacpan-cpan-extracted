use Test::More tests => 1;
use Class::DI::Definition;
BEGIN { use_ok('Class::DI::Factory') };

my $factory = Class::DI::Factory->new;

my %config = (
	name => "hoge",
	class_name => "Class::DI::Definition",
	injection_type => "setter",
	instance_type => "singleton",
	properties => { 
		name => {hoge=>"hoge"},
		injection_type=>"constracter",
		instance_type => "prototype",
	},
);

my $definition = new Class::DI::Definition(\%config);

my $instance = $factory->get_instance($definition);
ok($instance->isa('Class::DI::Definition'));
ok($instance->get_injection_type,"constracter");
ok($instance->get_instance_type,"prototype");
ok($instance->get_name->{hoge},"hoge");

diag('singleton');
%config = (
	name => "hoge",
	class_name => "Class::DI::Definition",
	injection_type => "setter",
	instance_type => "singleton",
	properties => { 
		injection_type=> "setter",
		instance_type => "singleton",
	},
);

$definition = new Class::DI::Definition(\%config);
my $instance = $factory->get_instance($definition);
ok($instance->isa('Class::DI::Definition'));
ok($instance->get_injection_type,"constracter");
ok($instance->get_instance_type,"prototype");
ok($instance->get_name->{hoge},"hoge");

my %complex_config = (
	name => "hoge",
	class_name => "Class::DI::Definition",
	injection_type => "setter",
	instance_type   => "prototype",
	properties => { 
		name=>{
			class_name => "Class::DI::Definition",
			instance_type   => "prototype",
			properties => { name=>"hoge"}, 
		},
	},
);

$factory = Class::DI::Factory->new;
my $definition = new Class::DI::Definition(\%complex_config);
my $instance = $factory->get_instance($definition);
ok($instance->isa('Class::DI::Definition'));
is($instance->get_name->get_name,"hoge");


