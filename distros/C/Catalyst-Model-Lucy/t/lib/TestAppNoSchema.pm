package # hide from PAUSE
    TestAppNoSchema;
 
use strict;
use warnings;
use FindBin;
use File::Spec;
 
use Catalyst;
 
__PACKAGE__->config(
    name        => 'TestApp',
    'Model::Lucy' => {
         index_path     => File::Spec->catfile($FindBin::Bin,'test_index'),
         num_wanted     => 20,
         language       => 'en',
    },
);
 
__PACKAGE__->setup;
 
1;
