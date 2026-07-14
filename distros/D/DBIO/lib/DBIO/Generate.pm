package DBIO::Generate;
# ABSTRACT: Driver-agnostic Result class generator for DBIO

use strict;
use warnings;
use base qw/Class::Accessor::Grouped/;
use mro 'c3';
use Carp::Clan qw/^DBIO/;
use DBIO::Util qw(dir_path mkpath write_file);
use Lingua::EN::Inflect::Phrase ();
use DBIO::Generate::Relationships ();
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  dump_directory
  dump_overwrite
  really_erase_my_files
  schema_class
  result_base_class
  additional_classes
  left_base_classes
  components
  result_roles
  generate_pod
  use_namespaces
  preserve_case
  constraint
  exclude
  db_schema
  moniker_map
  moniker_parts
  moniker_part_separator
  col_accessor_map
  rel_name_map
  col_collision_map
  rel_collision_map
  inflect_plural
  inflect_singular
  custom_column_info
  datetime_timezone
  datetime_locale
  datetime_undef_if_invalid
  uniq_to_primary
  allow_extra_m2m_cols
  filter_generated_code
  style
  quiet
  debug
/);

my %STYLE_CLASS = (
  vanilla => 'DBIO::Generate::Style::Vanilla',
  cake    => 'DBIO::Generate::Style::Cake',
  candy   => 'DBIO::Generate::Style::Candy',
  moose   => 'DBIO::Generate::Style::Moose',
  moo    => 'DBIO::Generate::Style::Moo',
);

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  $self->dump_directory( $args{dump_directory} // './lib' );
  $self->result_base_class( $args{result_base_class} // 'DBIO::Core' );
  $self->use_namespaces( exists $args{use_namespaces} ? $args{use_namespaces} : 1 );
  $self->generate_pod( exists $args{generate_pod} ? $args{generate_pod} : 1 );
  $self->style( $args{style} // 'vanilla' );
  $self->moniker_parts( $args{moniker_parts} // ['name'] );
  $self->moniker_part_separator( $args{moniker_part_separator} // '' );
  $self->allow_extra_m2m_cols( $args{allow_extra_m2m_cols} // 0 );
  $self->quiet( $args{quiet} // 0 );
  for my $k (keys %args) {
    $self->$k($args{$k}) if $self->can($k) && !overridden($self, $k);
  }
  return $self;
}

sub overridden {
  my ($self, $name) = @_;
  return $self->$name if eval { $self->can($name) && !$self->can($name)->can('__is_accessor') };
  return;
}


sub dump {
  my ($self, $introspect) = @_;

  croak "dump() requires an introspect object"
    unless ref $introspect;

  my $style_class = $STYLE_CLASS{ $self->style // 'vanilla' }
    or croak "Unknown style '" . ($self->style//'') . "'";

  eval "require $style_class" or croak "Cannot load $style_class: $@";

  my @keys = @{ $introspect->table_keys };

  @keys = $self->_filter_keys(@keys);

  my %moniker_for = map { $_ => $self->_moniker_for($_) } @keys;
  my %class_for   = map { $moniker_for{$_} => $self->_class_for($moniker_for{$_}) } @keys;
  my %pk_for      = map { $moniker_for{$_} => ($introspect->table_pk_info($_) // []) } @keys;

  my @rel_tables;
  for my $key (@keys) {
    my $moniker  = $moniker_for{$key};
    my @fk_info  = map { $self->_resolve_fk_remote($_, \%moniker_for) }
                       @{ $introspect->table_fk_info($key) // [] };
    push @rel_tables, [ $moniker, \@fk_info, ($introspect->table_uniq_info($key) // []) ];
  }

  my $rels = DBIO::Generate::Relationships->new(
    inflect_plural       => $self->inflect_plural,
    inflect_singular     => $self->inflect_singular,
    rel_name_map         => $self->rel_name_map,
    rel_collision_map    => $self->rel_collision_map,
    allow_extra_m2m_cols => $self->allow_extra_m2m_cols,
    quiet                => $self->quiet,
  )->generate_code(\@rel_tables, \%class_for, \%pk_for);

  for my $key (@keys) {
    my $moniker = $moniker_for{$key};
    my $class   = $class_for{$moniker};

    my $spec = {
      moniker          => $moniker,
      class            => $class,
      table            => $self->_table_name($key),
      column_order     => ($introspect->table_columns($key) // []),
      columns          => $self->_normalize_columns_info($introspect->table_columns_info($key) // {}),
      pk               => ($introspect->table_pk_info($key) // []),
      uniq             => ($introspect->table_uniq_info($key) // []),
      relationships    => ($rels->{$moniker} // []),
      extra_statements => [ $introspect->result_class_extra_statements($key) ],
      is_view          => ($introspect->table_is_view($key) // 0),
      view_definition  => $introspect->view_definition($key),
      result_base_class => ($self->result_base_class // 'DBIO::Core'),
      components       => ($self->components // []),
      additional_classes => ($self->additional_classes // []),
    };

    my $code = $style_class->emit($spec);

    $code = $self->filter_generated_code->($code, $spec)
      if ref($self->filter_generated_code) eq 'CODE';

    $self->_write_class($class, $code);
  }
}

# The style contract for optional column-info keys is "absent key", not
# "undef value" -- introspectors that hand back size => undef must not
# leak that into the emitters.
sub _normalize_columns_info {
  my ($self, $info) = @_;
  my %normalized;
  for my $col (keys %$info) {
    my $ci = $info->{$col} // {};
    $normalized{$col} = { map { $_ => $ci->{$_} } grep { defined $ci->{$_} } keys %$ci };
  }
  return \%normalized;
}

sub _filter_keys {
  my ($self, @keys) = @_;
  if (my $con = $self->constraint) {
    @keys = grep { $_ =~ $con } @keys;
  }
  if (my $ex = $self->exclude) {
    @keys = grep { $_ !~ $ex } @keys;
  }
  return @keys;
}

sub _table_name {
  my ($self, $key) = @_;
  (my $name = $key) =~ s/^[^.]+\.//;
  return $name;
}

sub _moniker_for {
  my ($self, $key) = @_;
  my $name = $self->_table_name($key);

  unless ($self->preserve_case) {
    my @parts = split /[_\W]+/, $name;
    $name = join('', map { ucfirst lc } @parts);
    if (@parts > 0) {
      my $last = pop @parts;
      my $singular = Lingua::EN::Inflect::Phrase::to_S($last);
      $name = join('', map { ucfirst lc } @parts) . ucfirst(lc $singular);
    }
  }

  if (my $map = $self->moniker_map) {
    if (ref $map eq 'HASH' && exists $map->{$name}) {
      return $map->{$name};
    }
    elsif (ref $map eq 'CODE') {
      my $mapped = $map->($name);
      return $mapped if defined $mapped;
    }
  }

  return $name;
}

sub _class_for {
  my ($self, $moniker) = @_;
  my $schema = $self->schema_class or croak "schema_class required";
  if ($self->use_namespaces) {
    return "${schema}::Result::${moniker}";
  }
  return "${schema}::${moniker}";
}

sub _resolve_fk_remote {
  my ($self, $fk, $moniker_for) = @_;
  my %by_table;
  while (my ($k, $m) = each %$moniker_for) {
    my $tname = $self->_table_name($k);
    $by_table{$tname} = $m;
  }
  my %resolved = %$fk;
  $resolved{remote_moniker} = $by_table{ $fk->{remote_table} };
  return \%resolved;
}

sub _write_class {
  my ($self, $class, $code) = @_;

  (my $rel_path = $class) =~ s{::}{/}g;
  my $dir = dir_path($self->dump_directory, $rel_path);
  my $file = "${dir}.pm";

  if (-e $file && !($self->dump_overwrite // 0) && !($self->really_erase_my_files // 0)) {
    warn "Skipping existing $file (set dump_overwrite => 1 to overwrite)\n"
      unless $self->quiet;
    return;
  }

  mkpath($dir);
  write_file($file, $code);
  warn "Wrote $file\n" unless $self->quiet;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate - Driver-agnostic Result class generator for DBIO

=head1 VERSION

version 0.900002

=head1 METHODS

=head2 dump

    $gen->dump($introspect);

Iterates over C<$introspect->table_keys>, builds moniker + class name,
infers relationships via L<DBIO::Generate::Relationships>, and writes one
C<.pm> per table using the configured Style emitter.

C<$introspect> must implement the normalized contract defined in
L<DBIO::Introspect::Base>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
