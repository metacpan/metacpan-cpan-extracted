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

    set serialzier => 'JSON';

    resource foo => prefix_id => sub {
        resource bar => read => sub {
            return { foo => captures->{'foo_id'}, bar => captures->{'bar_id'} };
          }
    };

}

use Dancer::Test;

my $r = dancer_response( GET => '/foo/123/bar/456' );
is_deeply $r->{content}, { foo => 123, bar => 456 }, "UserID is correct";

