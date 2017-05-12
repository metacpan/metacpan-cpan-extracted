package C::sparse::ctype; 
our @ISA = qw (C::sparse::type); 
use Carp;
use strict; 
use warnings;

foreach my $f ('position','typename') {
  eval("sub C::sparse::ctype::${f} { return \$_[0]->{_o}->$f };");
}

my %m = (
    'C::sparse::sym::SYM_FN'       => { n => 'C::sparse::type::fn'       },
    'C::sparse::sym::SYM_STRUCT'   => { n => 'C::sparse::type::rec'      },
    'C::sparse::sym::SYM_UNION'    => { n => 'C::sparse::type::rec'      },
    'C::sparse::sym::SYM_ENUM'     => { n => 'C::sparse::type::rec'      },
    'C::sparse::sym::SYM_PTR'      => { n => 'C::sparse::type::ptr'      },
    'C::sparse::sym::SYM_ARRAY'    => { n => 'C::sparse::type::ar'       },
    'C::sparse::sym::SYM_TYPEDEF'  => { n => 'C::sparse::type::typedef'  },
    'C::sparse::sym::SYM_BITFIELD' => { n => 'C::sparse::type::bit'      },
    'C::sparse::sym::SYM_BASETYPE' => { n => 'C::sparse::type::BASETYPE' }
);

foreach my $k (keys %m) {
  my $n = $m{$k}{n};
  if (defined($m{$k}{c})) {
    foreach my $f (@{$m{$k}{c}}) {
      eval("sub ${n}::${f} { return \$_[0]->{_o}->$f };");
    }
  }
}

#sub totype { my $s = shift; return C::sparse::type::totype($s->base_type, @_); }

sub l { return (); }
sub c { return (); }

package C::sparse::type; 
our @ISA = qw (C::sparse::sym); use Carp;

sub n {
  return "<undef>" if (!defined($_[0]->{'_n'}));
  return $_[0]->{'_n'}->name;
}

sub totype { 
  my $b = $_[0];
  return bless ({_o=>$b,_n=>$_[1],_p=>$_[2]}, $m{ref($b)}{n}) if (defined($m{ref($b)}{n}));
  confess("\nCannot map :".ref($b).":"); 
} 

package C::sparse::type::fn; 
our @ISA = qw (C::sparse::ctype); use Carp;

sub args { return map { $_->totype($_[0]) } $_[0]->{'_o'}->arguments; }
sub l { return $_[0]->{'_o'}->stmt->l($_[0]); }
sub c { return $_[0]->{'_o'}->stmt; }

package C::sparse::type::rec;
our @ISA = qw (C::sparse::ctype); use Carp;
sub l { return map { $_->totype($_[0]) } $_[0]->{'_o'}->symbol_list; } 

package C::sparse::type::typedef; 
our @ISA = qw (C::sparse::ctype); use Carp;

package C::sparse::type::ptr; 
our @ISA = qw (C::sparse::ctype); use Carp;
sub base { return $_[0]->{'_o'}->totype($_[0]);  }

package C::sparse::type::ar; 
our @ISA = qw (C::sparse::ctype); use Carp;

package C::sparse::type::bit; 
our @ISA = qw (C::sparse::ctype); use Carp;

package C::sparse::type::BASETYPE; 
our @ISA = qw (C::sparse::ctype); use Carp;

1;
