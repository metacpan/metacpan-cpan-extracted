use Module::Build;
my $class = Module::Build->subclass(
     class => 'My::Builder',
     code => q{
        sub ACTION_dist {
            my $self = shift;
            `perldoc -t lib/CGI/Application/Plugin/ValidateRM.pm>README`;
            $self->SUPER::ACTION_dist;
        }
    },
);


$class->new(
	module_name => 'CGI::Application::Plugin::ValidateRM',
	license => 'perl',
	requires => {
		'CGI::Application'    => 3.0,
		'Data::FormValidator' => 3.70, # for boolean overloading. 
		'HTML::FillInForm'	  => 1.07, # Fixes test-suite failure
	},
    create_makefile_pl => 'traditional',
	sign=>0,
	meta_merge     => {
	  resources => {
	    repository  => 'https://github.com/fany/CGI-Application-Plugin-ValidateRM',
	  }
	},
)->create_build_script;

