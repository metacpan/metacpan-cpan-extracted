use Module::Build;

my $class = Module::Build->subclass(
	 class => 'CGI::Session::PureSQL::Builder',
	   code => q{
	 	sub ACTION_dist {
			my $self = shift;
			use Pod::Text;
			my $parser = Pod::Text->new;
			$parser->parse_from_file('./lib/CGI/Session/Driver/pure_sql.pm', 'README');
			$self->SUPER::ACTION_dist;
	 	}
	},
);


$class->new(
     create_makefile_pl => 'traditional',
     module_name     => 'CGI::Session::Driver::pure_sql',
      license         => 'perl',
	  requires => {
		  'CGI::Session'  => 4.13,
		  'SQL::Abstract' => 0,
		  'Date::Calc'	  => 0,
	  },
    )->create_build_script;
