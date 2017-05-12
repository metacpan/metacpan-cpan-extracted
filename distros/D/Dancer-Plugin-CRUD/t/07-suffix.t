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

plan tests => 1;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    $Dancer::Plugin::CRUD::SUFFIX = 'ID';

    set serialzier => 'JSON';

    resource 'User' => (
        prefixID => sub {
            get qr'/foo' => sub { { UserID => captures->{'UserID'} } }
        },
    );

}

use Dancer::Test;

my $r = dancer_response( GET => '/User/123/foo' );
is_deeply $r->{content}, { UserID => 123 }, "UserID is correct";

