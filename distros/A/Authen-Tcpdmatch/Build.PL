use Module::Build;
my $b= Module::Build->new(
	module_name        => 'Authen-Tcpdmatch',
	dist_version_from  => 'lib/Authen/Tcpdmatch/Tcpdmatch.pm',
	dist_author        => 'Ioannis Tambouras <ioannis@yahoo.com>',
	requires           => {  perl                =>  '5.006',
				'Parse::RecDescent'  =>      0,
				'Attribute::Handlers'=>      0,
				'NetAddr::IP'        => '3.14',
				#'Parse::Lex'        =>      0,
				#'Parse::Yapp'       =>      0,
			      },
	recommends         => { 'Test::More'         =>      0,
                                'Test::Pod::Coverage'=> '1.06',
                                #'Test::Distribution' => '1.22',
                              },
	license            => 'gpl',
	#create_makefile_pl => 'traditional',
	#create_readme      => 1,
);

$b->create_build_script;
#$b->dispatch( 'manifest' );
