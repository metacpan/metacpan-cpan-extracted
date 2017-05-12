# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Catalyst-Plugin-CRUD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN {
    use_ok('XML::Simple');
    use_ok('Class::Trigger');
    use_ok('Jcode');
    use_ok('Catalyst::Plugin::CRUD');
    use_ok('Catalyst::Controller::CRUD');
    use_ok('Catalyst::Controller::CRUD::CDBI');
    use_ok('Catalyst::Controller::CRUD::DBIC');
    use_ok('Catalyst::Helper::Model::CRUD');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

