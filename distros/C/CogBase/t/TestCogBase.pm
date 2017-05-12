package t::TestCogBase;
use Test::Base -base;

use CogBase::Database;
use CogBase;
use File::Path qw(rmtree);

our @EXPORT = qw(create_database);

{
    no warnings 'once';
    open $CogBase::TEST_COGBASE_IDS, 't/test-cogids'
      or die "Can't open t/test-cogids for input";
}

sub create_database {
    my $db_path = shift;
    rmtree($db_path);
    CogBase::Database->create($db_path);
}
