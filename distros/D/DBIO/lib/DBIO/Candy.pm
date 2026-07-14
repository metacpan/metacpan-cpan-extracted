package DBIO::Candy;
# ABSTRACT: Sugar syntax for defining DBIO result classes

use strict;
use warnings;

use DBIO::Candy::Exports ();
use MRO::Compat;
use Sub::Exporter 'build_exporter';
use Carp 'croak';
use namespace::clean;

my %aliases = (
   column            => 'add_columns',
   primary_key       => 'set_primary_key',
   unique_constraint => 'add_unique_constraint',
   relationship      => 'add_relationship',
);

my @methods = qw(
   resultset_class
   resultset_attributes
   remove_columns
   remove_column
   table
   source_name

   inflate_column

   belongs_to
   has_many
   might_have
   has_one
   many_to_many

   sequence

   col_created
   col_updated
   cols_updated_created
);

sub base { return $_[1] || 'DBIO::Core' }

sub perl_version { return $_[1] }

sub autotable { $_[1] }

sub experimental { $_[1] }

sub _extract_part {
   my ($self, $class) = @_;
   if (my ( $part ) = $class =~ /(?:::Schema)?::Result::(.+)$/) {
      return $part
   } else {
      croak 'unrecognized naming scheme!'
   }
}

my $decamelize = sub {
   my $s = shift;
   $s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
      my $fc = pos($s)==0;
      my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
      my $t = $p0 || $fc ? $p0 : '_';
      $t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
      $t;
   }ge;
   $s;
};

sub gen_table {
   my ( $self, $class, $version ) = @_;
   if ($version eq 'singular') {
      my $part = $self->_extract_part($class);
      $part =~ s/:://g;
      return $decamelize->($part);
   } elsif ($version == 1) {
      my $part = $self->_extract_part($class);
      require Lingua::EN::Inflect;
      $part =~ s/:://g;
      $part = $decamelize->($part);
      return join q{_}, split /\s+/, Lingua::EN::Inflect::PL(join q{ }, split /_/, $part);
   }
}

sub import {
   my $self = shift;

   my $inheritor = caller(0);
   my $args         = $self->parse_arguments(\@_);
   my $perl_version = $self->perl_version($args->{perl_version});
   my $experimental = $self->experimental($args->{experimental});
   my @rest         = @{$args->{rest}};

   $self->set_base($inheritor, $args->{base});
   # Always load Timestamp for col_created/col_updated/cols_updated_created
   $inheritor->load_components('Timestamp', @{$args->{components}});
   my @custom_methods;
   my %custom_aliases;
   {
      my @custom = $self->gen_custom_imports($inheritor);
      @custom_methods = @{$custom[0]};
      %custom_aliases = %{$custom[1]};
   }

   my $set_table = sub {};
   if (my $v = $self->autotable($args->{autotable})) {
     my $table_name = $self->gen_table($inheritor, $v);
     my $ran = 0;
     $set_table = sub { $inheritor->table($table_name) unless $ran++ }
   }
   @_ = ($self, @rest);
   my $import = build_exporter({
      exports => [
         has_column => $self->gen_has_column($inheritor, $set_table),
         primary_column => $self->gen_primary_column($inheritor, $set_table),
         unique_column => $self->gen_unique_column($inheritor, $set_table),
         indices => $self->gen_indices($inheritor, $set_table),
         (map { $_ => $self->gen_proxy($inheritor, $set_table) } @methods, @custom_methods),
         (map { $_ => $self->gen_rename_proxy($inheritor, $set_table, %aliases, %custom_aliases) }
            keys %aliases, keys %custom_aliases),
      ],
      groups  => {
         default => [
            qw(has_column primary_column unique_column indices), @methods, @custom_methods, keys %aliases, keys %custom_aliases
         ],
      },
      installer  => $self->installer,
      collectors => [
         INIT => $self->gen_INIT($perl_version, \%custom_aliases, \@custom_methods, $inheritor, $experimental),
      ],
   });

   goto $import
}

sub gen_custom_imports {
  my ($self, $inheritor) = @_;
  my @methods;
  my %aliases;
  for (@{mro::get_linear_isa($inheritor)}) {
    if (my $a = DBIO::Candy::Exports::get_aliases_for($_)) {
      %aliases = (%aliases, %$a)
    }
    if (my $m = DBIO::Candy::Exports::get_methods_for($_)) {
      @methods = (@methods, @$m)
    }
  }
  return(\@methods, \%aliases)
}

sub parse_arguments {
  my $self = shift;
  my @args = @{shift @_};

  my $skipnext;
  my $base;
  my @rest;
  my $perl_version = undef;
  my $components   = [];
  my $autotable = 0;
  my $experimental;

  for my $idx ( 0 .. $#args ) {
    my $val = $args[$idx];

    next unless defined $val;
    if ($skipnext) {
      $skipnext--;
      next;
    }

    if ( $val eq '-base' ) {
      $base = $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-autotable' ) {
      $autotable = $args[$idx + 1];
      $autotable = ord $autotable if length $autotable == 1;
      $skipnext = 1;
    } elsif ( $val eq '-perl5' ) {
      $perl_version = ord $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-experimental' ) {
      $experimental = $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-components' ) {
      $components = $args[$idx + 1];
      $skipnext = 1;
    } else {
      push @rest, $val;
    }
  }

  return {
    autotable    => $autotable,
    base         => $base,
    perl_version => $perl_version,
    components   => $components,
    rest         => \@rest,
    experimental => $experimental,
  };
}

sub gen_primary_column {
  my ($self, $inheritor, $set_table) = @_;
  sub {
    my $i = $inheritor;
    sub {
      my $column = shift;
      my $info   = shift;
      $set_table->();
      $i->add_columns($column => $info);
      $i->set_primary_key($i->primary_columns, $column);
    }
  }
}

sub gen_unique_column {
  my ($self, $inheritor, $set_table) = @_;
  sub {
    my $i = $inheritor;
    sub {
      my $column = shift;
      my $info   = shift;
      $set_table->();
      $i->add_columns($column => $info);
      $i->add_unique_constraint([ $column ]);
    }
  }
}

sub gen_has_column {
  my ($self, $inheritor, $set_table) = @_;
  sub {
    my $i = $inheritor;
    sub {
      my $column = shift;
      $set_table->();
      $i->add_columns($column => { @_ })
    }
  }
}

# Sugar wrapper around the indices() class method installed by
# DBIO::ResultSourceProxy — available to both vanilla and Candy.
sub gen_indices {
  my ($self, $inheritor, $set_table) = @_;
  sub {
    my $i = $inheritor;
    sub {
      $set_table->();
      $i->indices(@_);
    }
  }
}

sub gen_rename_proxy {
  my ($self, $inheritor, $set_table, %aliases) = @_;
  sub {
    my ($class, $name) = @_;
    my $meth = $aliases{$name};
    my $i = $inheritor;
    sub { $set_table->(); $i->$meth(@_) }
  }
}

sub gen_proxy {
  my ($self, $inheritor, $set_table) = @_;
  sub {
    my ($class, $name) = @_;
    my $i = $inheritor;
    sub { $set_table->(); $i->$name(@_) }
  }
}

sub installer {
  my ($self) = @_;
  sub {
    Sub::Exporter::default_installer @_;
    my %subs = @{ $_[1] };
    namespace::clean->import( -cleanee => $_[0]{into}, keys %subs )
  }
}

sub set_base {
   my ($self, $inheritor, $base) = @_;

   # inlined from parent.pm
   for ( my @useless = $self->base($base) ) {
      s{::|'}{/}g;
      require "$_.pm"; # dies if the file is not found
   }

   {
      no strict 'refs';
      # Idempotent: skip if already in @ISA (needed for Loader reload)
      my @base = $self->base($base);
      my %seen = map { $_ => 1 } @{"$inheritor\::ISA"};
      my @new = grep { !$seen{$_} } @base;
      @{"$inheritor\::ISA"} = (@{"$inheritor\::ISA"}, @new) if @new;
   }
}

sub gen_INIT {
  my ($self, $perl_version, $custom_aliases, $custom_methods, $inheritor, $experimental) = @_;
  sub {
    my $orig = $_[1]->{import_args};
    $_[1]->{import_args} = [];
    %$custom_aliases = ();
    @$custom_methods = ();

    strict->import;
    warnings->import;

    if ($perl_version) {
       require feature;
       feature->import(":5.$perl_version")
    }

    if ($experimental) {
       require experimental;
       die 'experimental arg must be an arrayref!'
          unless ref $experimental && ref $experimental eq 'ARRAY';
       # to avoid experimental referring to the method
       experimental::->import(@$experimental)
    }

    mro::set_mro($inheritor, 'c3');

    1;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Candy - Sugar syntax for defining DBIO result classes

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

 package MyApp::Schema::Result::Artist;
 use DBIO::Candy;

 table 'artists';

 primary_column id => {
     data_type => 'integer',
     is_auto_increment => 1,
 };

 column name => {
     data_type => 'varchar',
     size => 100,
 };

 column bio => {
     data_type => 'text',
     is_nullable => 1,
 };

 column created_at => {
     data_type => 'timestamp',
     set_on_create => 1,
 };

 column updated_at => {
     data_type => 'timestamp',
     set_on_create => 1,
     set_on_update => 1,
 };

 unique_constraint [qw(name)];
 has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';

 1;

PostgreSQL-specific example:

 package MyApp::Schema::Result::User;
 use DBIO::Candy -components => ['InflateColumn::DateTime'];

 table 'users';

 primary_column id => {
     data_type => 'uuid',
     retrieve_on_insert => 1,
 };

 column name => {
     data_type => 'varchar',
     size => 100,
 };

 column role => {
     data_type => 'enum',
     extra => { list => [qw( admin moderator user guest )] },
     is_nullable => 1,
 };

 column metadata => {
     data_type => 'jsonb',
     default_value => '{}',
     serializer_class => 'JSON',
 };

 column embedding => {
     data_type => 'vector',
     size => 1536,
 };

 column tags => {
     data_type => 'text[]',
     is_nullable => 1,
 };

 column created_at => {
     data_type => 'timestamp',
     set_on_create => 1,
 };

 column updated_at => {
     data_type => 'timestamp',
     set_on_create => 1,
     set_on_update => 1,
 };

 column deleted_at => {
     data_type => 'timestamp',
     is_nullable => 1,
 };

 1;

See F<t/candy_indices.t> for a runnable example.

=head1 DESCRIPTION

C<DBIO::Candy> sits between vanilla L<DBIO::Core> and L<DBIO::Cake>. It keeps
the familiar method-based API, but imports shorter helper names so result
classes read more cleanly.

By default it:

=over

=item *

turns on strict and warnings

=item *

sets your parent class to L<DBIO::Core>

=item *

exports package methods used to define results as simple subroutines

=item *

aliases some method names for clarity

=item *

cleans the namespace after export via L<namespace::clean>

=back

=head1 IMPORT OPTIONS

Candy is a good fit when you want lighter syntax but still prefer explicit
column hashrefs over Cake's DDL-style declarations.

=head2 -base

 use DBIO::Candy -base => 'MyApp::Schema::Result';

Set the parent class.  Defaults to L<DBIO::Core>.

=head2 -autotable

 use DBIO::Candy -autotable => v1;

Automatically generate the table name from the class name.  Version C<v1>
pluralizes (C<Cat> becomes C<cats>), C<'singular'> does not.

=head2 -components

 use DBIO::Candy -components => ['InflateColumn::DateTime'];

Load components at import time so they can register their own sugar via
L<DBIO::Candy::Exports>.

=head2 -perl5

 use DBIO::Candy -perl5 => v10;

Enable Perl feature flags (equivalent to C<use feature ':5.10'>).

=head2 -experimental

 use DBIO::Candy -experimental => ['signatures'];

Enable experimental features.

=head1 IMPORTED SUBROUTINES

The following are exported with the same name and arguments as their
C<< __PACKAGE__->method >> equivalents:

 belongs_to
 has_many
 has_one
 inflate_column
 many_to_many
 might_have
 remove_column
 remove_columns
 resultset_attributes
 resultset_class
 sequence
 source_name
 table

=head1 IMPORTED ALIASES

Shorter or clearer names for common methods:

 column            => 'add_columns'
 primary_key       => 'set_primary_key'
 unique_constraint => 'add_unique_constraint'
 relationship      => 'add_relationship'

=head1 TRANSFORMER FUNCTIONS

=head2 has_column

 has_column foo => (
   data_type => 'varchar',
   size => 25,
 );

Like C<add_columns> but takes a flat list of key/value pairs (Moose-style)
and wraps them into a hashref.

=head2 primary_column

 primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
 };

Defines a column and adds it to the primary key in a single call.

=head2 unique_column

 unique_column name => {
   data_type => 'varchar',
   size => 30,
 };

Defines a column and adds a unique constraint on it in a single call.

=head2 indices

 indices(
   name_idx       => 'name',
   name_email_idx => ['name', 'email'],
 );

Declares one or more secondary indexes on the table. Field lists may be a
single column name or an arrayref of column names. Equivalent to the
L<DBICx::Indexing> component on DBIx::Class. The indexes are picked up by
both the SQL::Translator deploy path (via C<sqlt_deploy_hook>) and the
native PostgreSQL deploy path (via C<pg_indexes>), so they end up in the
generated DDL regardless of which deploy method is in use.

=head1 SETTING DEFAULT IMPORT OPTIONS

Create a subclass to avoid repeating import options:

 package MyApp::Schema::Candy;
 use base 'DBIO::Candy';

 sub base { $_[1] || 'MyApp::Schema::Result' }
 sub perl_version { 12 }
 sub autotable { 1 }
 sub experimental { ['signatures'] }

Then in your result classes:

 use MyApp::Schema::Candy;

=head1 AUTOTABLE VERSIONS

=head2 C<v1>

Extracts the part after C<::Result::>, removes C<::>, decamelizes, and
pluralizes:

 MyApp::Schema::Result::Cat           -> cats
 MyApp::Schema::Result::LonelyPerson  -> lonely_people

=head2 C<'singular'>

Same as C<v1> but without pluralization:

 MyApp::Schema::Result::Cat           -> cat
 MyApp::Schema::Result::LonelyPerson  -> lonely_person

=head1 TIMESTAMP HELPERS

These are proxy methods for L<DBIO::Timestamp> (loaded automatically):

=head2 col_created

 col_created;               # creates 'created_at' column
 col_created 'born_at';     # custom column name

=head2 col_updated

 col_updated;               # creates 'updated_at' column
 col_updated 'modified_at'; # custom column name

=head2 cols_updated_created

 cols_updated_created;      # creates both at once

The most common pattern -- one line for both timestamp columns.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
