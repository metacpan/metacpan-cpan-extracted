use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Downloader',
    license             => 'perl',
    dist_author         => 'Brian Duggan <brian.duggan@nasa.gov>',
    dist_version_from   => 'lib/Data/Downloader.pm',
    dist_abstract       => 'Download data and maintain a cache of files and links',
    build_requires      => {
	'File::Compare'              => 0,
	'FindBin'                    => 0,
	'IO::File'                   => 0,
	'Parallel::ForkManager'      => 0,
    'File::Slurp'                => 0,
    },
    requires            => {
	'DBD::SQLite'                => '1.33',
	'DBIx::Simple'               => '1.32',
	'Digest::MD5::File'          => 0,
	'Fcntl'                      => 0,
	'File::Basename'             => 0,
	'File::Path'                 => 0,
	'File::Spec'                 => 0,
	'File::stat'                 => 0,
	'File::Temp'                 => 0,
	'Filesys::Df'                => 0,
	'if'                         => 0,
	'Lingua::EN::Inflect'        => 0,
	'List::MoreUtils'            => 0,
	'Log::Log4perl'              => '1.23', # LL::Commandline fails otherwise
	'Log::Log4perl::CommandLine' => 0,
	'Number::Format'             => 0,
	'Params::Validate'           => 0,
	'Pod::Usage::CommandLine'    => 0,
	'Rose::DateTime'             => 0,
	'Rose::DB'                   => 0, 
	'Rose::DB::Object'           => 0,
	'Scalar::Util'               => 0,
	'Smart::Comments'            => 0,
	'SQL::Abstract'              => 0,
	'String::Template'           => '0.06',
	'Sub::Exporter'              => 0,
	'Time::HiRes'                => 0,
	'XML::LibXML'                => 0,
	'YAML::XS'                   => 0,
    },
    add_to_cleanup     => [ 'Data-Downloader-*','t/dado_test/*', 't/*.yml',
			    't/urn.dd.txt' ],
    create_makefile_pl => 'traditional',
);

$builder->html_css('docs.css');

$builder->create_build_script();
