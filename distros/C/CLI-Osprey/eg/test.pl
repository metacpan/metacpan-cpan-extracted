package Foo;
use Moo;
use CLI::Osprey
  doc => "The Moo Foo",
  added_order => 1;

option opt => (
  is => 'ro',
  format => 's',
);

option abc => (
  is => 'ro',
  format => 's',
);

sub run {
  warn "foo\n";
}

subcommand bar => 'Foo::Bar';

subcommand baz => sub {
  my ($self, @args) = @_;
  use Data::Dumper;
  warn "inline ", Dumper(\@_);
}, doc => "baz luhrmann";

no Moo;

package Foo::Bar;
use Moo;
use CLI::Osprey
  doc => "bars the foos";

option opt => (
  is => 'ro',
  format => 's',
);

sub run {
  warn "bar\n";
}

package main;
use Data::Dumper;

#print Dumper({ Foo->_osprey_config });
#print Dumper({ Foo->_osprey_options });
#print Dumper({ Foo->_osprey_subcommands });

my $obj = Foo->new_with_options;
print Dumper($obj);
print Dumper($obj->run);
