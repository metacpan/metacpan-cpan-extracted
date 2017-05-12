# vi:sw=2
package # Hide from PAUSE
  t::loader;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  build_schema
);

use Data::Dumper;

sub build_schema {
  my $def = shift;

  my $schema = "MyApp::Schema";
  my $prefix = "MyApp::Schema::Result";

  my $pkg = '';
  my @packages;
  while (my $name = shift @{$def//[]}) {
    my $defn = shift @$def;

    push @packages, $name;
    $pkg .= "{ package ${prefix}::$name;\n  use base 'DBIx::Class::Core';\n";

    $pkg .= "  __PACKAGE__->table('$defn->{table}');\n";

    local $Data::Dumper::Terse = 1;
    (my $v = Dumper($defn->{columns})) =~ s/{\n(.*)}\n/$1/ms;
    $pkg .= "  __PACKAGE__->add_columns(\n$v  );\n";

    my $pks = join ',', map { "'$_'" } @{$defn->{primary_keys}};
    $pkg .= "  __PACKAGE__->set_primary_key($pks);\n";

    foreach my $uk (@{$defn->{unique_constraints}//[]}) {
      my $key = Dumper($uk);
      $pkg .= "  __PACKAGE__->add_unique_constraint($key);\n";
    }

    foreach my $rel_type (qw(has_many belongs_to)) {
      while (my ($name, $opts) = each %{$defn->{$rel_type}}) {
        while (my ($foreign, $column) = each %{$opts}) {
          $column = ref($column) eq 'HASH'
            ? Dumper($column) : "'$column'";

          $pkg .= "  __PACKAGE__->$rel_type(\n";
          $pkg .= "    $name => '${prefix}::$foreign' => $column,\n";
          $pkg .= "  );\n";
        }
      }
    }

    $pkg .= "}\n";
  }

  $pkg .= "{ package $schema;\n  use base 'DBIx::Class::Schema';\n";
  $pkg .= "  __PACKAGE__->register_class($_ => '${prefix}::$_');\n"
    for @packages;
  $pkg .= "  __PACKAGE__->load_components('Sims');\n}\n";

  #print STDERR $pkg;
  eval $pkg; if ($@) {
    die "$@\n";
  }
}

1;
