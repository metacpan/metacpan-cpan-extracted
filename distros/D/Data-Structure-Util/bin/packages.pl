use strict;
use warnings;
use blib;
use TEST;
use Data::Dumper;
use Data::Structure::Util qw( has_circular_ref );


sub check_globals {
  my $package = shift || 'main';
  next_package($package);
}

sub next_package {
  my $pkg = shift;
  no strict 'refs';
  
  for my $key (%{"$pkg".'::'}) {
    next if ($key =~ /^\*/);
    if ($key =~ /(.+)\:\:$/) {
      if ($1 ne $pkg) {
        next_package($pkg . '::' . $1);
      }
    }

    my $scalar = ${"$pkg\::$key"};
    if (ref $scalar) {
      if (my $ref = has_circular_ref($scalar)) {
        warn "###### CIRCULAR REF DETECTED IN \$$pkg\::$key\n";
      }
    }
    
    my $hash = \%{"$pkg\::$key"};
    if (%$hash) {
      if (my $ref = has_circular_ref($hash)) {
        warn "###### CIRCULAR REF DETECTED IN \%$pkg\::$key\n";
      }
    }
  
    my $array = \@{"$pkg\::$key"};
    if (@$array) {
      if (my $ref = has_circular_ref($array)) {
        warn "###### CIRCULAR REF DETECTED IN \@$pkg\::$key\n";
      }
    }
  
  }
}

=head1 NAME

packages.pl

=head1 DESCRIPTION

Search through all the global variables in all packagse 
for any circular reference.

=cut

