use Module::Build;
my $build = Module::Build->new(

    module_name        => 'Bio::AGP::LowLevel',
    dist_author	       => ['Robert Buels <rmb32@cornell.edu>', 'Sheena Scroggins <sheena.scroggins@gmail.com>'],
    dist_version       => '0.02',
    license            => 'perl',
    dist_abstract      => 'low-level functions for working with Accessioned Golden Path (AGP) files',
    create_readme      => 1, 
    meta_merge         => {
        resources =>
          { repository => 'http://github.com/sheenams/Bio-AGP', },
    },


    requires           => {
        'perl'                  => '5.8.0',
        'Carp'                  => 0,

	'File::Basename'	=> 0,
	'List::Util'		=> 0,

    },
    build_requires => {
        
	'FindBin'		=> 0,
	'File::Basename'	=> 0,
	'File::Spec'		=> 0,
	'File::Temp' 		=> 0,
    },
);
$build->create_build_script;

