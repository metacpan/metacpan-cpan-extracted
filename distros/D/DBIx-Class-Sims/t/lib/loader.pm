# vi:sw=2
package # Hide from PAUSE
  loader;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  build_schema
);

use Data::Dumper;
use Hash::Merge qw( merge );

sub build_schema {
  my $def = shift || [];
  my $options = shift // {};
  $options->{sims_component} //= 1;

  my $schema = "MyApp::Schema";
  my $prefix = "MyApp::Schema::Result";

  my $pkg = '';
  my @packages;
  my $n = 0;
  while (my $name = shift @{$def}) {
    my $defn = shift @$def;

    local $Data::Dumper::Terse = 1;

    push @packages, $name;
    $pkg .= "{ package ${prefix}::$name;\n  use base 'DBIx::Class::Core';\n";

    $defn->{table} //= sprintf('table_%03d', $n++);
    $pkg .= "  __PACKAGE__->table('$defn->{table}');\n";

    (my $v = Dumper($defn->{columns})) =~ s/{\n(.*)}\n/$1/ms;
    $pkg .= "  __PACKAGE__->add_columns(\n$v  );\n";

    my $pks = join ',', map { "'$_'" } @{$defn->{primary_keys}};
    $pkg .= "  __PACKAGE__->set_primary_key($pks);\n";

    foreach my $uk (@{$defn->{unique_constraints}//[]}) {
      my $key = Dumper($uk);
      $pkg .= "  __PACKAGE__->add_unique_constraint($key);\n";
    }

    foreach my $rel_type (qw(has_many belongs_to has_one might_have)) {
      while (my ($name, $opts) = each %{$defn->{$rel_type}}) {
        while (my ($foreign, $column) = each %{$opts}) {
          $column = ref($column) eq 'HASH'
            ? Dumper($column)
            : $column =~ /^sub \{/
                ? "$column"
                : "'$column'";

          $pkg .= "  __PACKAGE__->$rel_type(\n";
          $pkg .= "    $name => '${prefix}::$foreign' => $column,\n";
          $pkg .= "  );\n";
        }
      }
    }

    # NOTE: This is limited to just one column - YAGNI.
    if ($defn->{inflate_json}) {
      $pkg .= "  use JSON qw(encode_json decode_json);\n";
      $pkg .= "  __PACKAGE__->inflate_column('$defn->{inflate_json}' => {\n";
      $pkg .= "    inflate => sub { decode_json(shift) },\n";
      $pkg .= "    deflate => sub { encode_json(shift) },\n";
      $pkg .= "  });\n";
    }
    $pkg .= "}\n";
  }

  $pkg .= "{ package $schema;\n  use base 'DBIx::Class::Schema';\n";
  $pkg .= "  __PACKAGE__->register_class($_ => '${prefix}::$_');\n"
    for @packages;
  $pkg .= "  __PACKAGE__->load_components('Sims');\n" if $options->{sims_component};
  $pkg .= "}\n";

  #print STDERR $pkg;
  eval $pkg; if ($@) {
    die "$@\n";
  }
}

1;
