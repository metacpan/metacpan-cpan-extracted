#!perl
use strict;
use ExtUtils::testlib;

use Benchmark qw( cmpthese );

########################################################################

my @generators = qw( Basic Standard Composite Evaled Template );
my @methods = map "method_$_", 1 .. 30;

my %pckgno;
my $cputime = shift(@ARGV) || 0;

########################################################################

print "\nComparing module load time (usage overhead)...\n";

my %inc = %INC;
sub test_load {
  local %INC = %inc;
  my $f = "$_[0].pm";
  $f =~ s{::}{/}g;
  require $f;
}

cmpthese( $cputime, {
  'Superclass' => sub { 
    test_load( "Class::MakeMethods" )
  },
  map {
    my $gen = $_;
    $gen => sub { 
      test_load( "Class::MakeMethods::${gen}::Hash" )
    }
  } @generators
} );

########################################################################

print "\nComparing method generation (startup duration)...\n";

cmpthese( $cputime, {
  'inline' => sub {
    eval( join "\n", 
      "package package_inline_" . ++ $pckgno{inline} . ";", 
      'sub new { my $class = shift; bless { @_ }, $class }',
  map "sub $_ { my \$self = shift; \@_ ? \$self->{$_} = shift : \$self->{$_} }", @methods 
    );
  },
  map {
    my $gen = $_;
    $gen => sub { 
      Class::MakeMethods->make(
	-MakerClass => $gen . "::Hash",
	-TargetClass => ( "package_${gen}_" . ++ $pckgno{$gen} ),
	'new' => 'new',
	'scalar' => \@methods
      );
    }
  } @generators
} );

########################################################################

print "\nComparing method calling (runtime duration)...\n";

cmpthese( $cputime, {
  map {
    my $gen = $_;
    $gen => sub { 
      my $instance = "package_${gen}_1"->new();
      foreach ( 1 .. 5 ) {
	foreach my $method ( @methods ) {
	  my $value = $instance->$method();
	  $instance->$method( $value );
	  $instance->$method();
	}
      }
    }
  } keys %pckgno
} );

########################################################################

__END__

########################################################################

date; perl -v | grep This; perl benchmark.pl | grep -v wallclock

