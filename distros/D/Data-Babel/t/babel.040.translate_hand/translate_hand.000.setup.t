########################################
# setup database
########################################
use t::lib;
use t::utilBabel;
use translate_hand;
use Test::More;
use Data::Babel;
use strict;

init('setup');

# create Babel directly from config files
my $name='test';
$babel=new Data::Babel
  (name=>$name,
   idtypes=>$OPTIONS->idtype_ini,masters=>$OPTIONS->master_ini,maptables=>$OPTIONS->maptable_ini);
check_babel_sanity('new');

# setup the database
map {my $name=$_; load_maptable($babel,$name,$data->$name->data)} @{$OPTIONS->maptables};
map {my $name="${_}_master"; load_master($babel,$name,$data->$name->data)} @{$OPTIONS->explicits};
$babel->load_implicit_masters;
load_ur($babel,'ur');
check_database_sanity();

done_testing();

