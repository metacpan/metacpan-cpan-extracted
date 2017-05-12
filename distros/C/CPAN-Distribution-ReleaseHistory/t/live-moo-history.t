use strict;
use warnings;

use Test::More;
use Test::RequiresInternet ( 'api.metacpan.org' => 80 );
use Test::Fatal qw( exception );

# ABSTRACT: Show live Moo history

0 and eval <<'DEBUGGING';
  use HTTP::Tiny;
  package HTTP::Tiny;

  use Class::Method::Modifiers qw( around );
  use Data::Dump qw(pp);
  require JSON;

  sub _decode_response {
    my ( $response ) = @_;
    if ( exists $response->{content} ) {
      my $clone = { %{$response} };

      my $data = $clone->{content};
      local $@;
      my $ok = eval {
        $clone->{content} = JSON->new->decode( "$data" );
        1;
      };
      $response->{json_err} = substr $@, 0, 130 if not $ok;
      #warn $@ if not $ok;
      return $clone if $ok;
    }
    return $response;
  }
  sub _decode_request {
    my ( $request ) = @_;
    my ( $method, $url, $params ) = @_;
    return $request unless $params;
    return $request unless $params->{'content'};
    my $content;
    return $request unless eval { $content = JSON->new->decode( $params->{'content'}); 1 };
    my $clone = {%{$params}};
    $clone->{content} = $content;
    return [ $method, $url, $clone ];
  }
  around 'request' => sub {
    my ( $orig, $self, @args )  = @_;
      pp( _decode_request(@args) );
      my $rval = $orig->( $self, @args );
      pp( _decode_response($rval));
      return $rval;
  };
DEBUGGING

use CPAN::Distribution::ReleaseHistory;

my $rh;
my $e;
is(
  $e = exception {
    $rh = CPAN::Distribution::ReleaseHistory->new(
      distribution => "Moo",
      sort         => 'asc',
    );
  },
  undef,
  "Created Instance OK"
) or diag explain $e;

my $ri;

is(
  exception {
    $ri = $rh->release_iterator;
  },
  undef,
  "Created release iterator OK"
) or diag explain $e;

my $i = 0;

sub get_release {
  my $release;
  is(
    $e = exception {
      $release = $ri->next_release;
    },
    undef,
    "Get release $i OK"
  ) or diag explain $e;
  return $release;
}

while ( my $r = get_release() ) {
  last if $i > 11;
  $i++;
  my $rel = "$i-th @" . $r->distinfo->version;
  # NB: This shit is here because the subtests are broken for some reason and
  # Give useless context.
  note "BEGIN: $rel";
  cmp_ok( $r->timestamp, '<=', 1321316878, "$rel: Prior to Tue Nov 15 00:27:58 2011" );
  is( $r->distinfo->cpanid, 'MSTROUT', "$rel Was released by MST" );
  cmp_ok( $r->distinfo->version, '>=', 0.009000, "$rel V >= 0.009000" );
  cmp_ok( $r->distinfo->version, '<=', 0.009012, "$rel V <= 0.009012" );
  note "END: $rel";
}

done_testing;

