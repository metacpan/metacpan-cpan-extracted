use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use CGI::Carp::DebugScreen;

my @engines = ( '', 'DefaultView' );

eval { require HTML::Template };
push @engines, 'HTML::Template' unless $@;

eval { require Template };
push @engines, 'TT' unless $@;

foreach my $engine ( @engines ) {
  diag "engine is $engine";

  {
    diag('default set');
    my $html = html( engine => $engine );
    test( $html,
      version     => 1,
      error       => 1,
      stacktraces => 1,
    );
  }

  {
    diag('with module list');
    my $html = html( engine => $engine, mod => 1, );
    test( $html,
      version     => 1,
      error       => 1,
      stacktraces => 1,
      modules     => 1,
    );
  }

  {
    diag('with env');
    my $html = html( engine => $engine, env => 1, );
    test( $html,
      version     => 1,
      error       => 1,
      stacktraces => 1,
      env         => 1,
    );
  }

  {
    diag('with watch list');
    my $html = html(
      engine    => $engine,
      watchlist => { myscalar => 'this is watched' },
    );
    test( $html,
      version     => 1,
      error       => 1,
      stacktraces => 1,
      watchlist   => 1,
    );
  }

  {
    diag('raw error');
    my $html = html(
      engine    => $engine,
      raw_error => 1,
    );
    test( $html,
      version     => 1,
      stacktraces => 1,
      raw_error   => 1,
    );
  }

  {
    diag('error screen');
    my $html = html(
      engine    => $engine,
      mod       => 1,
      env       => 1,
      watchlist => { myscalar => 'this is watched' },
      raw_error => 1,
      debug     => 0,
    );
    test( $html,
      error_template => 1,
    );
  }
}

sub html {
  my %options = @_;
  my $watchlist = delete $options{watchlist};
  CGI::Carp::DebugScreen->import(%options);
  if ( $watchlist && ref $watchlist eq 'HASH' ) {
    CGI::Carp::DebugScreen->add_watchlist(%{ $watchlist });
  }
  eval { croak "foo" };
  return CGI::Carp::DebugScreen->_render($@);
}

sub test {
  my ($html, %flags) = @_;

  my %mapping = (
    version     => qr{CGI::Carp::DebugScreen $CGI::Carp::DebugScreen::VERSION},
    stacktraces    => qr{<h2><a name="stacktraces">Stacktraces},
    watchlist      => qr{<h2><a name="watch">Watch List},
    modules        => qr{<h2><a name="modules">Included Modules},
    env            => qr{<h2><a name="environment">Environmental Variables},
    raw_error      => qr{<pre class="raw_error">foo at \S+ line \d+},
    error          => qr{<div class="box">\s*foo at \S+ line \d+},
    error_template => qr{An unexpected error has been detected},
  );

  foreach my $key ( keys %mapping ) {
    my $flag = $html =~ $mapping{$key};
    ok not ( $flag xor $flags{$key} ), ( $flag ? "has $key" : "has no $key" );
  }
}
