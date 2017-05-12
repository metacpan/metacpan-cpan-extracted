use strict;
use Test::More tests => 4;
use lib qw( lib ../lib );
use Authen::Htpasswd::Trac;
use Data::Dumper;
use File::Copy;

my $file     = 't/data/htpasswd';
my $tmp_file = 't/data/tmp_passwd';
my $db       = 't/data/trac.db';
my $tmp_db   = 't/data/tmp.db';

unlink($tmp_db) if -f $tmp_db;
copy($db, $tmp_db);

unlink($tmp_file) if -f $tmp_file;
copy($file, $tmp_file);

{
    my $auth = Authen::Htpasswd::Trac->new($file, { trac => $db });
    my @rs = $auth->find_user_permissions('sample', 'sample');
    is( $rs[0], 'MILESTONE_VIEW');
    is( $rs[1], 'WIKI_VIEW');
}

{
    my $auth = Authen::Htpasswd::Trac->new($tmp_file, { trac => $tmp_db });
    $auth->add_user('tester', 'test_passwd');
    $auth->add_permission('tester', 'WIKI_VIEW');
    my @rs = $auth->find_user_permissions('tester', 'test_passwd');
    is ( $rs[0], 'WIKI_VIEW' );
    $auth->remove_permission('tester', 'WIKI_VIEW');
    @rs = $auth->find_user_permissions('tester', 'test_passwd');
    is ( @rs, 0 );
}

unlink($tmp_db);
unlink($tmp_file);

