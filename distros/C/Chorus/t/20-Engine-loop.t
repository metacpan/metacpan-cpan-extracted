#!perl -T

use strict;
use Test::More tests => 4;
use Chorus::Frame;
use Chorus::Engine;

diag( "Testing Chorus::Engine::loop $Chorus::Engine::VERSION, Perl $], $^X" );

sub make_engine {
  my $e = Chorus::Engine->new(@_);
  $e->set('BOARD', Chorus::Frame->new());
  return $e;
}

# Test 1 : _APPLY est appelé pour chaque combinaison du scope
{
  my @collected;
  my $e = make_engine();

  $e->addrule(
    _SCOPE => { x => [1, 2, 3] },
    _APPLY => sub {
      my %opts = @_;
      push @collected, $opts{x};
      return;  # ne signale pas de succès -> une seule passe
    }
  );

  $e->loop();
  is_deeply( [sort { $a <=> $b } @collected], [1, 2, 3],
             'Test 1 - _APPLY appelé pour chaque élément du scope' );
}

# Test 2 : loop itère tant qu'une règle retourne vrai
{
  my $counter = 0;
  my $e = make_engine();

  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub {
      $counter++;
      return 1 if $counter < 3;  # succès 2 fois, échoue à la 3e
      return;
    }
  );

  $e->loop();
  is( $counter, 3, 'Test 2 - loop itère tant qu\'une règle réussit' );
}

# Test 3 : solved() stoppe la boucle
{
  my $counter = 0;
  my $e = make_engine();

  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub {
      $counter++;
      $e->solved();
      return 1;
    }
  );

  $e->loop();
  is( $counter, 1, 'Test 3 - solved() stoppe la boucle immédiatement' );
}

# Test 4 : failed() stoppe la boucle
{
  my $counter = 0;
  my $e = make_engine();

  $e->addrule(
    _SCOPE => { x => [1] },
    _APPLY => sub {
      $counter++;
      $e->failed();
      return 1;
    }
  );

  $e->loop();
  is( $counter, 1, 'Test 4 - failed() stoppe la boucle immédiatement' );
}

done_testing();
