use Module::Build;
# See perldoc Module::Build for details of how this works

my $class = Module::Build->subclass(
	 class => 'Data::FormValidator::Builder',
	 code => q{
	 	sub ACTION_dist {
			my $self = shift;
			`perldoc -t lib/Data/FormValidator/Util/HTML.pm>README`;
			$self->SUPER::ACTION_dist;
	 	}
    }
);

$class->new(
    module_name     => 'Data::FormValidator::Util::HTML',
    license         => 'perl',
    create_makefile_pl => 'traditional',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    requires => {
        'HTML::TokeParser::Simple' => 0,
        'Params::Validate'         => 0,
    },
)->create_build_script;

