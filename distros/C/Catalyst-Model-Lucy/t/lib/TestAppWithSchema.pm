package # hide from PAUSE
    TestAppWithSchema;
 
use strict;
use warnings;
use FindBin;
use File::Spec;
 
use Catalyst;
 
__PACKAGE__->config(
    name        => 'TestApp',
    'Model::Lucy' => {
         index_path     => File::Spec->catfile($FindBin::Bin,'index'),
         num_wanted     => 20,
         language       => 'en',
         create_index   => 1,   # We create it from nothing
         truncate_index => 1,   # If exists we truncate
         schema_params  => [
                               { name => 'title' },
                               { name => 'desc' }
                           ]
    },
);
 
__PACKAGE__->setup;
 
1;
