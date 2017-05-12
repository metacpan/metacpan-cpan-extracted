shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
use Module::Build;

my $class = Module::Build->subclass(
	 class => 'Data::Shark::Builder',
	 code => q{
	 	sub ACTION_dist {
			my $self = shift;
			`perldoc -t lib/Data/Shark.pm>README`;
			$self->SUPER::ACTION_dist;
	 	}

        sub ACTION_cover {
            my $self = shift;
            $self->depends_on('build');

            system qw( cover -delete );

            # sometimes we get failing tests, which makes Test::Harness
            # die.  catch that
            eval {
                local $ENV{PERL5OPT} = "-MDevel::Cover=-summary,0";
                $self->ACTION_test(@_);
            };
            system qw( cover -report html );
        }
 	},
);


$class->new(
    # Makefile.PL is maintained manually now because the 5.8 requirement wasn't getting
    # translated automatically. 
    # create_makefile_pl  => 'traditional', 
    dist_author         => 'Jack <walzbill@gmail.com>',
	module_name => 'Data::Shark',
	license => 'perl',
	requires => {
         'DBI'            =>  1.40,
         'Cache::Cache'   =>  1.00,
         'SQL::Abstract'  =>  1.50,
	},
    build_requires        => {
    },
)->create_build_script;

