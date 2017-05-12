
BEGIN{ require "t/lib/t.pl"; &init; }
use Test::More tests => 16;
use t::tie;
use IO::String;
use Scalar::Util qw( blessed );
use Symbol;

our $called = undef;
our @args   = ();

# Scalar
{
  my $b = Data::Rebuilder->new;
  tie my $hoge , 't::tie::Scalar';
  $hoge = 123;
  is( $called, 'STORE' );
  my $r = $b->_t(\$hoge);
  $called = undef;
  @args   = @_;
  is( blessed( tied $$r ) , 't::tie::Scalar');
  is( $$r      , 123 );
  is( $called  , 'FETCH' );
}

# Hash
{
  my $b = Data::Rebuilder->new;
  tie my %hoge , 't::tie::Hash';
  $hoge{fuga} = 123;
  is( $called, 'STORE' );
  my $r = $b->_t(\%hoge);
  $called = undef;
  @args   = @_;
  is( blessed( tied %$r ) , 't::tie::Hash');
  is( $r->{fuga} , 123 );
  is( $called  , 'FETCH' );
  is( $args[1] , 'fuga' );
}

# Array
{
  my $b = Data::Rebuilder->new;
  tie my @hoge , 't::tie::Array';
  push @hoge, 123;
  my $r = $b->_t(\@hoge);
  $called = undef;
  @args   = @_;
  is( blessed( tied @$r ) , 't::tie::Array');
  is( $r->[0]  , 123 );
  is( $called  , 'FETCH' );
  is( $args[1] , 0 );
}

# Glob
{
  my $b   = Data::Rebuilder->new;
  my $sym = IO::String->new;
  print $sym "123\n";
  print $sym "456\n";
  print $sym "789\n";
  seek $sym, 0 , 0;
  is( <$sym> , "123\n");
  my $r = $b->_t($sym);
  $called = undef;
  @args   = @_;
  is( blessed( tied *{$r} ) , 'IO::String');
  is( <$r>     , "456\n" );
}
