use Module::Build;
my $build = Module::Build->new
(
	#sign	=>	1,
	module_name => 'Data::Serializer',
	dist_author => 'Neil Neely (neil@neely.cx)',
	license  => 'perl',
	create_makefile_pl => 'passthrough',
	build_class	=>	'Module::Build',
	meta_merge => {
    resources => {
            bugtracker =>  'https://github.com/neilneely/Data-Serializer/issues',
            homepage   =>  'http://metacpan.org/release/Data-Serializer',
            repository =>  'git://github.com/neilneely/Data-Serializer.git',
        },
	},
	requires => {
		'Exporter'	=> 0,
		'AutoLoader'	=> 0,
		'IO::File' => 0,
		'Digest::SHA' => 0,
		'Data::Dumper' => 2.08,
	},
	build_requires => {
		#'AutoSplit'	=> 0,
		'IO::File' => 0,
		'Test::More' => 0,
		'File::Spec' => 0,
	},
	recommends => { 
		'Crypt::CBC'		=> 0,
		'Crypt::Blowfish'	=> 0,
                'Data::Denter'		=> 0,
                'Data::Taxi'		=> 0,
                'Storable'		=> 0,
                'FreezeThaw'		=> 0,
                'Config::General'	=> 0,
                'YAML'			=> 0,
                'YAML::Syck'		=> 0,
                'PHP::Serialization'	=> 0,
                'JSON'			=> 0,
                'JSON::XS'		=> 0,
                'JSON::Syck'		=> 0,
                'XML::Simple'		=> 0,
                'XML::Dumper'		=> 0,
                'Bencode'		=> 0,
                'Convert::Bencode'	=> 0,
                'Convert::Bencode_XS'	=> 0,
                'Compress::Zlib'	=> 0,
                'Compress::PPMd'	=> 0,
                'MIME::Base64'		=> 0,
		},
	#autosplit => 'lib/Data/Serializer.pm',

);
$build->create_build_script;

