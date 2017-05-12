use Test::More;
my @missing = grep { ! eval "require $_; 1" } qw/CGI::Session/;
plan skip_all => "requires @missing" if scalar @missing;
plan tests => 4;


my $session = new CGI::Session("driver:bitbucket", undef, {Log=>1});

ok( $session );

$session->param("hello", "world");
ok( $session->param("hello") eq "world" );
ok( $session->flush );

eval {
	$session->delete;
};

ok( !$@ );

__END__

use Test::More;
BEGIN { use_ok('CGI::Session') };

print "hello\n";
__END__

BEGIN { require_ok('CGI::Session'); warn "ok=$ok\n"; plan skip_all => 'Missing CGI::Sesssion --'.$ok }


