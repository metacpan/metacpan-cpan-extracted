use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

# Dancer::Test had a bug in version previous 1.3059_01 that prevent this test
# from running correctly.
my $dancer_version = eval "\$Dancer::VERSION";
$dancer_version =~ s/_//g;
plan skip_all =>
  "Dancer 1.3059_01 is needed for this test (you have $dancer_version)"
  if $dancer_version < 1.305901;

plan tests => 2;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    set serialzier => 'JSON';

    resource 'user(s)' => (
        'prefix' => sub {
            get qr'/foo' => sub { [qw[ bar ]] }
        },
        'prefix_id' => sub {
            get qr'/foo' => sub { { user_id => captures->{'user_id'} } }
        },
    );

}

use Dancer::Test;

my $r = dancer_response( GET => '/users/foo' );
is_deeply $r->{content}, [qw[ bar ]], "path is correct";

$r = dancer_response( GET => '/user/123/foo' );
is_deeply $r->{content}, { user_id => 123 }, "path and user_id is correct";

