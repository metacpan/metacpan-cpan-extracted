use strictures 2;

package t::tests;

use Import::Into;
use HTTP::Headers::Fancy;
use Exporter ();
use Test::Most qw(!pass);
use Plack::Test;
use HTTP::Request::Common ();
use Time::HiRes qw(gettimeofday tv_interval);
use HTTP::Date qw(str2time time2str);

our @EXPORT = qw(
  OPTIONS
  approx
  approx_httpdate
  boot
  debug
  debug_headers
  deserialize
  dotest
  headers
  measure
  request
  testf
  testfs
  testh
  time2str
);

sub import {
    my $target = scalar caller;
    strictures->import::into($target);
    Test::Most->import::into($target);
    Plack::Test->import::into($target);
    goto &Exporter::import;
}

sub approx {
    my ( $val, $range ) = @_;
    $range //= 0;
    my $min = $val - abs( $range + 1 );
    my $max = $val + abs( $range + 1 );
    return sub {
        my $got  = shift;
        my $test = sprintf( "%d <= %d <= %d",
            ( $min - $val ),
            ( $got - $val ),
            ( $max - $val ) );
        if ( ( $min <= $got ) and ( $got <= $max ) ) {
            return pass($test);
        }
        else {
            return fail($test);
        }
      }
}

sub approx_httpdate {
    my $sub = approx(@_);
    return sub {
        @_ = ( str2time +shift );
        goto &$sub;
      }
}

sub testf {
    my $F = shift;
    my %H = @_;
    my $H = { HTTP::Headers::Fancy::split_field_hash($F) };
    subtest 'HTTP keyword check' => sub {
        reset(%H);
        while ( my ( $K, $V ) = each %H ) {
            if ( defined $V ) {
                ok( exists( $H->{$K} ), "keyword $K exists" ) or next;
                if ( ref $V eq 'Regexp' ) {
                    like( $H->{$K}, $V, "keyword $K matches" );
                }
                elsif ( ref $V eq 'CODE' ) {
                    ok( $V->( $H->{$K} ), "keyword $K ok" );
                }
                else {
                    is( $H->{$K}, $V, "keyword $K equals" );
                }
            }
            else {
                ok not( exists $H->{$K} ), "keyword $K missing";
            }
        }
    };
}

sub testfs {
    my %H = @_;
    return sub {
        return testf( +shift, %H );
      }
}

sub testh {
    my $R = shift;
    my %H = @_;
    my $H = HTTP::Headers::Fancy::decode_hash( $R->headers );
    subtest 'HTTP header check' => sub {
        reset(%H);
        while ( my ( $K, $V ) = each %H ) {
            if ( defined $V ) {
                ok( exists( $H->{$K} ), "header $K exists" ) or next;
                if ( ref $V eq 'Regexp' ) {
                    like( $H->{$K}, $V, "header $K matches" );
                }
                elsif ( ref $V eq 'CODE' ) {
                    ok( $V->( $H->{$K} ), "header $K ok" );
                }
                else {
                    is( $H->{$K}, $V, "header $K equals" );
                }
            }
            else {
                ok not( exists $H->{$K} ), "header $K missing";
            }
        }
    };
}

sub measure {
    my $code  = shift;
    my $start = [gettimeofday];
    $code->(@_);
    return tv_interval($start);
}

sub headers {
    my %H = @_;
    $H{CacheControl} =
      scalar HTTP::Headers::Fancy::build_field_hash( %{ $H{CacheControl} } )
      if ref $H{CacheControl};
    return ( HTTP::Headers::Fancy::encode_hash(%H) );
}

sub boot {
    my $class = shift;
    return Plack::Test->create( $class->to_app );
}

sub deserialize {
    my $R = shift;
    my $VAR1;
    eval $R->content;
    die $@ if $@;
    return $VAR1;
}

sub dotest {
    my ( $name, $plan, $code ) = @_;
    @_ = (
        $name,
        sub {
            plan tests => $plan;
            $code->();
        }
    );
    goto &subtest;
}

sub debug {
    use Data::Dumper;
    diag( Dumper(@_) );
}

sub debug_headers {
    my $R = shift;
    @_ = ( scalar HTTP::Headers::Fancy::decode_hash( $R->headers ) );
    goto &debug;
}

sub request {
    my $PT = shift;
    return $PT->request( HTTP::Request::Common::_simple_req(@_) );
}

sub OPTIONS {
    return HTTP::Request::Common::_simple_req( OPTIONS => @_ );
}

1;
