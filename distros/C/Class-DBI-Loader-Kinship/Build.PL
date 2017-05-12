use Module::Build;


my $b= Module::Build->new(
	module_name        => 'Class::DBI::Loader::Kinship',
	dist_author        => 'Ioannis Tambouras <ioannis@cpan.org>',
	requires           => {  perl                 => '5.006',
				'Class::DBI::Loader'  =>    0 ,
				'Class::DBI::Pg'      =>    0 ,
			      },
	recommends         => { 'Test::Pod'           => '1.20',
                                'Test::Pod::Coverage' => '1.06',
                              # 'Test::Distribution'  => '1.22',
	                      },
	license            => 'perl',
	#create_makefile_pl=> 'traditional',
	create_readme     => 1,
);


$b->create_build_script;
#$b->manifest;
