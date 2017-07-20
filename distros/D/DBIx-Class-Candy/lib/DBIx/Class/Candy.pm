package DBIx::Class::Candy;
$DBIx::Class::Candy::VERSION = '0.005003';
use strict;
use warnings;

use namespace::clean;
require DBIx::Class::Candy::Exports;
use MRO::Compat;
use Sub::Exporter 'build_exporter';
use Carp 'croak';

# ABSTRACT: Sugar for your favorite ORM, DBIx::Class

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
);

sub base { return $_[1] || 'DBIx::Class::Core' }

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
   $inheritor->load_components(@{$args->{components}});
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
         (map { $_ => $self->gen_proxy($inheritor, $set_table) } @methods, @custom_methods),
         (map { $_ => $self->gen_rename_proxy($inheritor, $set_table, %aliases, %custom_aliases) }
            keys %aliases, keys %custom_aliases),
      ],
      groups  => {
         default => [
            qw(has_column primary_column unique_column), @methods, @custom_methods, keys %aliases, keys %custom_aliases
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
    if (my $a = $DBIx::Class::Candy::Exports::aliases{$_}) {
      %aliases = (%aliases, %$a)
    }
    if (my $m = $DBIx::Class::Candy::Exports::methods{$_}) {
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
      # This is more efficient than push for the new MRO
      # at least until the new MRO is fixed
      @{"$inheritor\::ISA"} = (@{"$inheritor\::ISA"} , $self->base($base));
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

=head1 NAME

DBIx::Class::Candy - Sugar for your favorite ORM, DBIx::Class

=head1 SYNOPSIS

 package MyApp::Schema::Result::Artist;

 use DBIx::Class::Candy -autotable => v1;

 primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
 };

 column name => {
   data_type => 'varchar',
   size => 25,
   is_nullable => 1,
 };

 has_many albums => 'A::Schema::Result::Album', 'artist_id';

 1;

=head1 DESCRIPTION

C<DBIx::Class::Candy> is a simple sugar layer for definition of
L<DBIx::Class> results.  Note that it may later be expanded to add sugar
for more C<DBIx::Class> related things.  By default C<DBIx::Class::Candy>:

=over

=item *

turns on strict and warnings

=item *

sets your parent class

=item *

exports a bunch of the package methods that you normally use to define your
L<DBIx::Class> results

=item *

makes a few aliases to make some of the original method names shorter or
more clear

=item *

defines very few new subroutines that transform the arguments passed to them

=back

It assumes a L<DBIx::Class::Core>-like API, but you can tailor it to suit
your needs.

=head1 IMPORT OPTIONS

See L</SETTING DEFAULT IMPORT OPTIONS> for information on setting these schema wide.

=head2 -base

 use DBIx::Class::Candy -base => 'MyApp::Schema::Result';

The first thing you can do to customize your usage of C<DBIx::Class::Candy>
is change the parent class.  Do that by using the C<-base> import option.

=head2 -autotable

 use DBIx::Class::Candy -autotable => v1;

Don't waste your precious keystrokes typing C<< table 'buildings' >>, let
C<DBIx::Class::Candy> do that for you!  See L<AUTOTABLE VERSIONS> for what the
existing versions will generate for you.

=head2 -components

 use DBIx::Class::Candy -components => ['FilterColumn'];

C<DBIx::Class::Candy> allows you to set which components you are using at
import time so that the components can define their own sugar to export as
well.  See L<DBIx::Class::Candy::Exports> for details on how that works.

=head2 -perl5

 use DBIx::Class::Candy -perl5 => v10;

I love the new features in Perl 5.10 and 5.12, so I felt that it would be
nice to remove the boiler plate of doing C<< use feature ':5.10' >> and
add it to my sugar importer.  Feel free not to use this.

=head2 -experimental

 use DBIx::Class::Candy -experimental => ['signatures'];

I would like to use signatures and postfix dereferencing in all of my
C<DBIx::Class> classes.  This makes that goal trivial.

=head1 IMPORTED SUBROUTINES

Most of the imported subroutines are the same as what you get when you use
the normal interface for result definition: they have the same names and take
the same arguments.  In general write the code the way you normally would,
leaving out the C<< __PACKAGE__-> >> part.  The following are methods that
are exported with the same name and arguments:

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

There are some exceptions though, which brings us to:

=head1 IMPORTED ALIASES

These are merely renamed versions of the functions you know and love.  The idea is
to make your result classes a tiny bit prettier by aliasing some methods.
If you know your C<DBIx::Class> API you noticed that in the L</SYNOPSIS> I used C<column>
instead of C<add_columns> and C<primary_key> instead of C<set_primary_key>.  The old
versions work, this is just nicer.  A list of aliases are as follows:

 column            => 'add_columns',
 primary_key       => 'set_primary_key',
 unique_constraint => 'add_unique_constraint',
 relationship      => 'add_relationship',

=head1 SETTING DEFAULT IMPORT OPTIONS

Eventually you will get tired of writing the following in every single one of
your results:

 use DBIx::Class::Candy
   -base      => 'MyApp::Schema::Result',
   -perl5     => v12,
   -autotable => v1,
   -experimental => ['signatures'];

You can set all of these for your whole schema if you define your own C<Candy>
subclass as follows:

 package MyApp::Schema::Candy;

 use base 'DBIx::Class::Candy';

 sub base { $_[1] || 'MyApp::Schema::Result' }
 sub perl_version { 12 }
 sub autotable { 1 }
 sub experimental { ['signatures'] }

Note the C<< $_[1] || >> in C<base>.  All of these methods are passed the
values passed in from the arguments to the subclass, so you can either throw
them away, honor them, die on usage, or whatever.  To be clear, if you define
your subclass, and someone uses it as follows:

 use MyApp::Schema::Candy
    -base => 'MyApp::Schema::Result',
    -perl5 => v18,
    -autotable => v1,
    -experimental => ['postderef'];

Your C<base> method will get C<MyApp::Schema::Result>, your C<perl_version> will
get C<18>, your C<experimental> will get C<['postderef']>, and your C<autotable>
will get C<1>.

=head1 SECONDARY API

=head2 has_column

There is currently a single "transformer" for C<add_columns>, so that
people used to the L<Moose> api will feel more at home.  Note that this B<may>
go into a "Candy Component" at some point.

Example usage:

 has_column foo => (
   data_type => 'varchar',
   size => 25,
   is_nullable => 1,
 );

=head2 primary_column

Another handy little feature that allows you to define a column and set it as
the primary key in a single call:

 primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
 };

If your table has multiple columns in its primary key, merely call this method
for each column:

 primary_column person_id => { data_type => 'int' };
 primary_column friend_id => { data_type => 'int' };

=head2 unique_column

This allows you to define a column and set it as unique in a single call:

 unique_column name => {
   data_type => 'varchar',
   size => 30,
 };

=head1 AUTOTABLE VERSIONS

Currently there are two versions:

=head2 C<v1>

It looks at your class name, grabs everything after C<::Schema::Result::> (or
C<::Result::>), removes the C<::>'s, converts it to underscores instead of
camel-case, and pluralizes it.  Here are some examples if that's not clear:

 MyApp::Schema::Result::Cat -> cats
 MyApp::Schema::Result::Software::Building -> software_buildings
 MyApp::Schema::Result::LonelyPerson -> lonely_people
 MyApp::DB::Result::FriendlyPerson -> friendly_people
 MyApp::DB::Result::Dog -> dogs

=head2 C<'singular'>

It looks at your class name, grabs everything after C<::Schema::Result::> (or
C<::Result::>), removes the C<::>'s and converts it to underscores instead of
camel-case.  Here are some examples if that's not clear:

 MyApp::Schema::Result::Cat -> cat
 MyApp::Schema::Result::Software::Building -> software_building
 MyApp::Schema::Result::LonelyPerson -> lonely_person
 MyApp::DB::Result::FriendlyPerson -> friendly_person
 MyApp::DB::Result::Dog -> dog

Also, if you just want to be different, you can easily set up your own naming
scheme.  Just add a C<gen_table> method to your candy subclass.  The method
gets passed the class name and the autotable version, which of course you may
ignore.  For example, one might just do the following:

 sub gen_table {
   my ($self, $class) = @_;

   $class =~ s/::/_/g;
   lc $class;
 }

Which would transform C<MyApp::Schema::Result::Foo> into
C<myapp_schema_result_foo>.

Or maybe instead of using the standard C<MyApp::Schema::Result> namespace you
decided to be different and do C<MyApp::DB::Table> or something silly like that.
You could pre-process your class name so that the default C<gen_table> will
still work:

 sub gen_table {
   my $self = shift;
   my $class = $_[0];

   $class =~ s/::DB::Table::/::Schema::Result::/;
   return $self->next::method(@_);
 }

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
