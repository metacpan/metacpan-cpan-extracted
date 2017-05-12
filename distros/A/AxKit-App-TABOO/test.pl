# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use AxKit::App::TABOO;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use AxKit::App::TABOO::Provider::News;
ok(1); 

use AxKit::App::TABOO::Provider::NewsList;
ok(1); 

use AxKit::App::TABOO::Data;
ok(1); 

use AxKit::App::TABOO::Data::Category;
ok(1); 

use AxKit::App::TABOO::Data::User;
ok(1); 

#use AxKit::App::TABOO::Data::Comment;
#ok(1); 


use AxKit::App::TABOO::Data::Story;
ok(1); 


use AxKit::App::TABOO::Data::Plurals::Stories;
ok(1); 

use AxKit::App::TABOO::Data::Plurals::Categories;
ok(1); 


