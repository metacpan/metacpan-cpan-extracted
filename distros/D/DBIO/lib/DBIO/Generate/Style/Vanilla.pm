package DBIO::Generate::Style::Vanilla;
# ABSTRACT: Vanilla-style Result class emitter for DBIO::Generate

use strict;
use warnings;
use Carp::Clan qw/^DBIO/;
use namespace::clean;


sub emit {
  my ($self, $spec) = @_;

  my @lines;

  push @lines, "package $spec->{class};";
  push @lines, '';
  push @lines, "use strict;";
  push @lines, "use warnings;";
  push @lines, "use base '$spec->{result_base_class}';";
  push @lines, '';
  push @lines, "__PACKAGE__->table('$spec->{table}');";
  push @lines, "__PACKAGE__->add_columns(";

  my @cols;
  for my $col (@{ $spec->{column_order} }) {
    my $info = $spec->{columns}{$col} // {};
    my @col_args;
    push @col_args, "data_type => '$info->{data_type}'" if $info->{data_type};
    if (defined $info->{size}) {
      push @col_args, "size => $info->{size}";
    }
    if ($info->{is_nullable}) {
      push @col_args, "is_nullable => 1";
    } else {
      push @col_args, "is_nullable => 0";
    }
    if ($info->{is_auto_increment}) {
      push @col_args, "is_auto_increment => 1";
    }
    if (my $def = $info->{default_value}) {
      $def =~ s/'/\\'/g;
      push @col_args, "default_value => '$def'";
    }
    push @cols, "  $col => {\n    " . join(",\n    ", @col_args) . "\n  }";
  }

  push @lines, join(",\n", @cols) . "\n);";
  push @lines, '';

  if ($spec->{pk} && @{ $spec->{pk} }) {
    my $pk_str = join(', ', map { "'$_'" } @{ $spec->{pk} });
    push @lines, "__PACKAGE__->set_primary_key($pk_str);";
  } else {
    push @lines, "# __PACKAGE__->set_primary_key('id'); # auto-detected or set manually";
  }
  push @lines, '';

  if ($spec->{uniq} && @{ $spec->{uniq} }) {
    for my $uniq (@{ $spec->{uniq} }) {
      my ($name, $cols) = @$uniq;
      my $cols_str = join(', ', map { "'$_'" } @$cols);
      push @lines, "__PACKAGE__->add_unique_constraint('$name' => [$cols_str]);";
    }
    push @lines, '';
  }

  for my $rel (@{ $spec->{relationships} // [] }) {
    my $method = $rel->{method};
    my $args   = $rel->{args};
    my ($name, $class, $cond, $attrs) = @$args;
    my $cond_str = join(', ',
      map { "'$_' => '$cond->{$_}'" } sort keys %$cond
    );
    push @lines, "__PACKAGE__->$method('$name', '$class', {$cond_str});";
  }
  push @lines, '';

  for my $stmt (@{ $spec->{extra_statements} // [] }) {
    my $method = $stmt->[0];
    my @args   = @$stmt[1..$#$stmt];
    my $args_str = join(', ', map { /^[\d\w_]+$/ ? "'$_'" : $_ } @args);
    push @lines, "__PACKAGE__->$method($args_str);";
  }

  push @lines, '';
  push @lines, '1;';

  return join("\n", @lines);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate::Style::Vanilla - Vanilla-style Result class emitter for DBIO::Generate

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 emit

    my $src = DBIO::Generate::Style::Vanilla->emit($spec);

Takes a $spec hashref and returns Perl source text.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
