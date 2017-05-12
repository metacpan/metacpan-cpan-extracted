BEGIN {print "1..13\n";}
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

my $session_id = 'dbms://localhost/users/sessions';
ok $tt++, $session = tie %session, "Apache::Session::DBMS", $session_id;

ok $tt++, not exists $session{ '_session_id' };

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

# again
my $session1;
my %session1;
ok $tt++, $session1 = tie %session1, "Apache::Session::DBMS", $session_id, {
	'Handle' => tied(%session)
	};

ok $tt++, $session1{ 'baz' }->[0] eq 'tom';

#tied(%session1)->delete; #requires upto 'allow drop from 127.0.0.1' into /RDFStore/etc/dbms.conf

undef $session1;
untie %session1;
undef %session1;

undef $session;
untie %session;
undef %session;

# and again
$session_id =~ s|users|/////users////////|;
$session_id =~ s|sessions|/////sessions////////|;
ok $tt++, $session = tie %session, "Apache::Session::DBMS", $session_id;

ok $tt++, $session{ 'baz' }->[0] eq 'tom';

undef $session;
untie %session;
undef %session;
