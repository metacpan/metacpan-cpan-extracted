BEGIN {print "1..9\n";}
END { print "not ok 1\n" unless $::loaded; };

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

use Apache::Session::DBMS;

$loaded = 1;
print "ok 1\n";

my $tt=2;

my %session;
my $session;

my $session_id;
ok $tt++, $session = tie %session, "Apache::Session::DBMS";

$session_id = $session{ '_session_id' };

ok $tt++, $session{ 'test' } = 'value';
ok $tt++, $session{ 'test' } eq 'value';

my $baz = [ qw[tom dick harry] ];
ok $tt++, $session{ 'baz' } = $baz;
ok $tt++, $session{ 'baz' }->[0] eq 'tom';

undef $session;
untie %session;
undef %session;

#exit;

# read it back
ok $tt++, $session = tie %session, "Apache::Session::DBMS", $session_id;

ok $tt++, $session{ 'baz' }->[0] eq 'tom';

tied(%session)->delete;

undef $session;
untie %session;
undef %session;

eval {
	$session = tie %session, "Apache::Session::DBMS", $session_id;
	};
ok $tt++, $@;
