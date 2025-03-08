use strict;
use warnings;

use Test::More;

my $class = 'App::ipinfo';
my $method = 'default_template';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, 'new', $method;

	my $app = $class->new;
	isa_ok $app, $class;
	can_ok $app, 'new', $method;
	};

subtest 'default template' => sub {
	my $app = $class->new;
	isa_ok $app, $class;

	is $app->template, $app->$method(), 'template is the default template';
	};

subtest 'supplied template' => sub {
	my $template = '%k';

	my $app = $class->new( template => $template );
	isa_ok $app, $class;

	isnt $template, $app->$method(), 'test template is not the same as the default template';
	is $app->template, $template, 'app template is the default template';
	};

done_testing();
