use Module::Build;
my $build = Module::Build->new(
	module_name	=> 'Algorithm::Pair::Swiss',
	license		=> 'perl',
	requires	=> {
	        		'perl'		=> '5.6.0',
			   },
        build_requires	=> {
				'Test::More'     => 0,
			   },		
	add_to_cleanup	=> [ 'Algorithm-Pair-Swiss-*.tar.gz' ],
);

if(exists $build->args->{snapshot}) {
	my ($revision) = `svn info` =~ /^Revision: (\d+)$/gms;
	$build->{properties}->{dist_version} .= '_'.$revision;
}

$build->create_build_script; 
