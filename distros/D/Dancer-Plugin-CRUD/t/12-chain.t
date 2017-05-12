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

#plan tests => 1;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    set serialzier => 'JSON';

    my $sub = sub {
        header 'x-foo' => var 'foo';
        header 'x-bar' => var 'bar';
    };

    resource foo => chain => sub      { var 'foo' => 'foof' },
      chain_id   => sub   { var 'foo' => 'foof(' . shift() . ')' },
      index      => $sub,
      read       => $sub,
      create     => $sub,
      update     => $sub,
      delete     => $sub,
      patch      => $sub,
      prefix_id  => sub {
        resource bar => chain => sub { var 'bar' => 'barf' },
          chain_id => sub { var 'bar' => 'barf(' . shift() . ')' },
          index    => $sub,
          read     => $sub,
          create   => $sub,
          update   => $sub,
          delete   => $sub,
          patch    => $sub,
          ;
      },
      ;

    get '/' => $sub;
}

use Dancer::Test;

my $R;

sub header_includes($%) {
    my $testname = shift;
    local %_ = @_;
    while ( my ( $H, $V ) = each %_ ) {
        if ( defined $V ) {
            if (
                ok(
                    exists( $R->{headers}->{ lc($H) } ),
                    "$testname, header $H exists"
                )
              )
            {
                is(
                    $R->{headers}->{ lc($H) } => $V,
                    "$testname, header value $H"
                );
            }
        }
        else {
            unless (
                ok(
                    not( exists( $R->{headers}->{ lc($H) } ) ),
                    "$testname, header $H not exists"
                )
              )
            {
                diag( "$testname, header $H contains: "
                      . $R->{headers}->{ lc($H) } );
            }
        }
    }
}

my %var1 = (
    'x-foo' => undef,
    'x-bar' => undef,
);

my %var2 = (
    'x-foo' => 'foof',
    'x-bar' => undef,
);

my %var3 = (
    'x-foo' => 'foof',
    'x-bar' => 'barf',
);

my %var4 = (
    'x-foo' => 'foof(123)',
    'x-bar' => undef,
);

my %var5 = (
    'x-foo' => 'foof(123)',
    'x-bar' => 'barf',
);

my %var6 = (
    'x-foo' => 'foof(123)',
    'x-bar' => 'barf(456)',
);

$R = dancer_response( 'GET', '/' );
is( $R->{status} => 200, 'root ok' );
header_includes( 'GET       /', %var1 );

$R = dancer_response( 'GET', '/foo' );
is( $R->{status} => 200, 'index ok' );
header_includes( 'GET       /foo', %var2 );

$R = dancer_response( 'POST', '/foo' );
is( $R->{status} => 201, 'create ok' );
header_includes( 'POST      /foo', %var2 );

$R = dancer_response( 'GET', '/foo/123' );
is( $R->{status} => 200, 'read ok' );
header_includes( 'GET       /foo/123', %var4 );

$R = dancer_response( 'PUT', '/foo/123' );
is( $R->{status} => 202, 'update ok' );
header_includes( 'PUT       /foo/123', %var4 );

$R = dancer_response( 'DELETE', '/foo/123' );
is( $R->{status} => 202, 'delete ok' );
header_includes( 'DELETE    /foo/123', %var4 );

$R = dancer_response( 'PATCH', '/foo/123' );
is( $R->{status} => 200, 'patch ok' );
header_includes( 'PATCH     /foo/123', %var4 );

$R = dancer_response( 'GET', '/foo/123/bar' );
is( $R->{status} => 200, 'index ok' );
header_includes( 'GET       /foo/123/bar', %var5 );

$R = dancer_response( 'POST', '/foo/123/bar' );
is( $R->{status} => 201, 'create ok' );
header_includes( 'POST      /foo/123/bar', %var5 );

$R = dancer_response( 'GET', '/foo/123/bar/456' );
is( $R->{status} => 200, 'read ok' );
header_includes( 'GET       /foo/123/bar/456', %var6 );

$R = dancer_response( 'PUT', '/foo/123/bar/456' );
is( $R->{status} => 202, 'update ok' );
header_includes( 'PUT       /foo/123/bar/456', %var6 );

$R = dancer_response( 'DELETE', '/foo/123/bar/456' );
is( $R->{status} => 202, 'delete ok' );
header_includes( 'DELETE    /foo/123/bar/456', %var6 );

$R = dancer_response( 'PATCH', '/foo/123/bar/456' );
is( $R->{status} => 200, 'patch ok' );
header_includes( 'PATCH     /foo/123/bar/456', %var6 );

done_testing;
