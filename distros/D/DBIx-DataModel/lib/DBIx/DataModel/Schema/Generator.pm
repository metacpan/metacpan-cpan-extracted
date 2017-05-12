#----------------------------------------------------------------------
package DBIx::DataModel::Schema::Generator;
#----------------------------------------------------------------------

# see POD doc at end of file
# version : see DBIx::DataModel

use strict;
use warnings;
no warnings 'uninitialized';
use Carp;
use List::Util   qw/max/;
use Exporter     qw/import/;
use Scalar::Does qw/does/;
use DBI;
use Try::Tiny;
use Module::Load ();


{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

our @EXPORT = qw/fromDBIxClass fromDBI/;


use constant CASCADE => 0; # see L<DBI/foreign_key_info>

#----------------------------------------------------------------------
# front methods
#----------------------------------------------------------------------

sub new {
  my ($class, @args) = @_;
  my $self =  bless {@args}, $class;
  $self->{-schema} ||= "My::Schema";
  $self->{tables}  ||= [];
  $self->{assoc}   ||= [];
  return $self;
}


sub fromDBI {
  # may be called as ordinary sub or as method
  my $self = ref $_[0] eq __PACKAGE__ ? shift : __PACKAGE__->new(@ARGV);

  $self->parse_DBI(@_);
  print $self->perl_code;
}


sub fromDBIxClass {
  # may be called as ordinary sub or as method
  my $self = ref $_[0] eq __PACKAGE__ ? shift : __PACKAGE__->new(@ARGV);

  $self->parse_DBIx_Class(@_);
  print $self->perl_code;
}

# other name for this method
*fromDBIC = \&fromDBIxClass;



# support for SQL::Translator::Producer
sub produce {
  my $tr = shift;

  my $self = __PACKAGE__->new(%{$tr->{producer_args} || {}});
  $self->parse_SQL_Translator($tr);
  return $self->perl_code;
}


sub load {
  my $self = shift;
  eval $self->perl_code;
}


#----------------------------------------------------------------------
# build internal data from external sources
#----------------------------------------------------------------------

sub parse_DBI {
  my $self = shift;

  # dbh connection
  my $arg1    = shift or croak "missing arg (dsn for DBI->connect(..))";
  my $dbh = does($arg1, 'DBI::db') ? $arg1 : do {
    my $user    = shift || "";
    my $passwd  = shift || "";
    my $options = shift || {RaiseError => 1};
    DBI->connect($arg1, $user, $passwd, $options)
      or croak "DBI->connect failed ($DBI::errstr)";
  };

  # get list of tables
  my %args;
  $args{catalog} = shift;
  $args{schema}  = shift;
  $args{type}    = shift || "TABLE";
  my $tables_sth = $dbh->table_info(@args{qw/catalog schema table type/});
  my $tables     = $tables_sth->fetchall_arrayref({});

 TABLE:
  foreach my $table (@$tables) {

    # get primary key info
    my @table_id = @{$table}{qw/TABLE_CAT TABLE_SCHEM TABLE_NAME/};
    my $pkey = join(" ", $dbh->primary_key(@table_id)) || "unknown_pk";

    my $table_info  = {
      classname => _table2class($table->{TABLE_NAME}),
      tablename => $table->{TABLE_NAME},
      pkey      => $pkey,
      remarks   => $table->{REMARKS},
    };

    # insert into list of tables
    push @{$self->{tables}}, $table_info;


    # get association info (in an eval because unimplemented by some drivers)
    my $fkey_sth = try {$dbh->foreign_key_info(@table_id,
                                                undef, undef, undef)}
      or next TABLE;

    while (my $fk_row = $fkey_sth->fetchrow_hashref) {

      # hack for unifying "ODBC" or "SQL/CLI" column names (see L<DBI>)
      $fk_row->{"UK_$_"} ||= $fk_row->{"PK$_"} for qw/TABLE_NAME COLUMN_NAME/;
      $fk_row->{"FK_$_"} ||= $fk_row->{"FK$_"} for qw/TABLE_NAME COLUMN_NAME/;

      my $del_rule = $fk_row->{DELETE_RULE};

      my @assoc = (
        { table      => _table2class($fk_row->{UK_TABLE_NAME}),
          col        => $fk_row->{UK_COLUMN_NAME},
          role       => _table2role($fk_row->{UK_TABLE_NAME}),
          mult_min   => 1, #0/1 (TODO: depend on is_nullable on other side)
          mult_max   => 1,
        },
        { table      => _table2class($fk_row->{FK_TABLE_NAME}),
          col        => $fk_row->{FK_COLUMN_NAME},
          role       => _table2role($fk_row->{FK_TABLE_NAME}, "s"),
          mult_min   => 0,
          mult_max   => '*',
          is_cascade => defined $del_rule && $del_rule == CASCADE,
        }
       );

      push @{$self->{assoc}}, \@assoc;
    }
  }
}


sub parse_DBIx_Class {
  my $self = shift;

  my $dbic_schema = shift or croak "missing arg (DBIC schema name)";

  # load the DBIx::Class schema
  Module::Load::load $dbic_schema or croak $@;

  # global hash to hold assoc. info (because we must collect info from
  # both tables to get both directions of the association)
  my %associations;

  # foreach  DBIC table class ("moniker" : short class name)
  foreach my $moniker ($dbic_schema->sources) {
    my $source = $dbic_schema->source($moniker); # full DBIC class

    # table info
    my $table_info  = {
      classname => $moniker,
      tablename => $source->from,
      pkey      => join(" ", $source->primary_columns),
    };

    # inflated columns
    foreach my $col ($source->columns) {
      my $column_info  = $source->column_info($col);
      my $inflate_info = $column_info->{_inflate_info} 
        or next;

      # don't care about inflators for related objects
      next if $source->relationship_info($col);

      my $data_type = $column_info->{data_type};
      push @{$self->{column_types}{$data_type}{$moniker}}, $col;
    }

    # insert into list of tables
    push @{$self->{tables}}, $table_info;

    # association info 
    foreach my $relname ($source->relationships) {
      my $relinfo   = $source->relationship_info($relname);

      # extract join keys from $relinfo->{cond} (which 
      # is of shape {"foreign.k1" => "self.k2"})
      my ($fk, $pk) = map /\.(.*)/, %{$relinfo->{cond}};

      # moniker of the other side of the relationship
      my $relmoniker = $source->related_source($relname)->source_name;

      # info structure
      my %info = (
        table    => $relmoniker,
        col      => $fk,
        role     => $relname,

        # compute multiplicities
        mult_min => $relinfo->{attrs}{join_type} eq 'LEFT' ? 0   : 1,
        mult_max => $relinfo->{attrs}{accessor} eq 'multi' ? "*" : 1,
      );

      # store assoc info into global hash; since both sides of the assoc must 
      # ultimately be joined, we compute a unique key from alphabetic ordering
      my ($key, $index) = ($moniker cmp $relmoniker || $fk cmp $pk) < 0
                        ? ("$moniker/$relmoniker/$fk/$pk", 0)
                        : ("$relmoniker/$moniker/$pk/$fk", 1);
      $associations{$key}[$index] = \%info;

      # info on other side of the association
      my $other_index = 1 - $index;
      my $other_assoc = $associations{$key}[1 - $index] ||= {};
      $other_assoc->{table} ||= $moniker;
      $other_assoc->{col}   ||= $pk;
      defined $other_assoc->{mult_min} or $other_assoc->{mult_min} = 1;
      defined $other_assoc->{mult_max} or $other_assoc->{mult_max} = 1;
    }
  }

  $self->{assoc} = [values %associations];
}


sub parse_SQL_Translator {
  my ($self, $tr) = @_;

  my $schema = $tr->schema;
  foreach my $table ($schema->get_tables) {
    my $tablename = $table->name;
    my $classname = _table2class($tablename);
    my $pk        = $table->primary_key;
    my @pkey      = $pk ? ($pk->field_names) : qw/unknown_pk/;

    my $table_info  = {
      classname => $classname,
      tablename => $tablename,
      pkey      => join(" ", @pkey),
      remarks   => join("\n", $table->comments),
    };
    push @{$self->{tables}}, $table_info;

    my @foreign_keys 
      = grep {$_->type eq 'FOREIGN KEY'} ($table->get_constraints);

    my $role      = _table2role($tablename, "s");
    foreach my $fk (@foreign_keys) {
      my $ref_table  = $fk->reference_table;
      my @ref_fields = $fk->reference_fields;

      my @assoc = (
        { table    => _table2class($ref_table),
          col      => $table_info->{pkey},
          role     => _table2role($ref_table),
          mult_min => 1, #0/1 (TODO: depend on is_nullable on other side)
          mult_max => 1,
        },
        { table    => $classname,
          col      => join(" ", $fk->fields),
          role     => $role,
          mult_min => 0,
          mult_max => '*',
        }
       );
      push @{$self->{assoc}}, \@assoc;
    }
  }
}


#----------------------------------------------------------------------
# emit perl code
#----------------------------------------------------------------------

sub perl_code {
  my ($self) = @_;

  # check that we have some data
  @{$self->{tables}}
    or croak "can't generate schema: no data. "
           . "Call parse_DBI() or parse_DBIx_Class() before";

  # make sure there is no duplicate role on the same table
  my %seen_role;
  foreach my $assoc (@{$self->{assoc}}) {
    my $count;
    $count = ++$seen_role{$assoc->[0]{table}}{$assoc->[1]{role}};
    $assoc->[1]{role} .= "_$count" if $count > 1;
    $count = ++$seen_role{$assoc->[1]{table}}{$assoc->[0]{role}};
    $assoc->[0]{role} .= "_$count" if $count > 1;
  }

  # compute max length of various fields (for prettier source alignment)
  my %l;
  foreach my $field (qw/classname tablename pkey/) {
    $l{$field} = max map {length $_->{$field}} @{$self->{tables}};
  }
  foreach my $field (qw/col role mult/) {
    $l{$field} = max map {length $_->{$field}} map {(@$_)} @{$self->{assoc}};
  }
  $l{mult} = max ($l{mult}, 4);

  # start emitting code
  my $code = <<__END_OF_CODE__;
use strict;
use warnings;
use DBIx::DataModel;

DBIx::DataModel  # no semicolon (intentional)

#---------------------------------------------------------------------#
#                         SCHEMA DECLARATION                          #
#---------------------------------------------------------------------#
->Schema('$self->{-schema}')

#---------------------------------------------------------------------#
#                         TABLE DECLARATIONS                          #
#---------------------------------------------------------------------#
__END_OF_CODE__

  my $colsizes = "%-$l{classname}s %-$l{tablename}s %-$l{pkey}s";
  my $format   = "->Table(qw/$colsizes/)\n";

  $code .= sprintf("#          $colsizes\n", qw/Class Table PK/)
        .  sprintf("#          $colsizes\n", qw/===== ===== ==/);

  foreach my $table (@{$self->{tables}}) {
    if ($table->{remarks}) {
      $table->{remarks} =~ s/^/# /gm;
      $code .= "\n$table->{remarks}\n";
    }
    $code .= sprintf $format, @{$table}{qw/classname tablename pkey/};
  }


  $colsizes = "%-$l{classname}s %-$l{role}s  %-$l{mult}s %-$l{col}s";
  $format   = "  [qw/$colsizes/]";

  $code .= <<__END_OF_CODE__;

#---------------------------------------------------------------------#
#                      ASSOCIATION DECLARATIONS                       #
#---------------------------------------------------------------------#
__END_OF_CODE__

  $code .= sprintf("#     $colsizes\n", qw/Class Role Mult Join/)
        .  sprintf("#     $colsizes",   qw/===== ==== ==== ====/);

  foreach my $a (@{$self->{assoc}}) {

    # for prettier output, make sure that multiplicity "1" is first
    @$a = reverse @$a if $a->[1]{mult_max} eq "1"
                      && $a->[0]{mult_max} eq "*";

    # complete association info
    for my $i (0, 1) {
      $a->[$i]{role} ||= "---";
      my $mult       = "$a->[$i]{mult_min}..$a->[$i]{mult_max}";
      $a->[$i]{mult} = {"0..*" => "*", "1..1" => "1"}->{$mult} || $mult;
    }

    # association or composition
    my $relationship = $a->[1]{is_cascade} ? 'Composition' : 'Association';

    $code .= "\n->$relationship(\n"
          .  sprintf($format, @{$a->[0]}{qw/table role mult col/})
          .  ",\n"
          .  sprintf($format, @{$a->[1]}{qw/table role mult col/})
          .  ")\n";
  }
  $code .= "\n;\n";

  # column types
  $code .= <<__END_OF_CODE__;

#---------------------------------------------------------------------#
#                             COLUMN TYPES                            #
#---------------------------------------------------------------------#
# $self->{-schema}->ColumnType(ColType_Example =>
#   fromDB => sub {...},
#   toDB   => sub {...});

# $self->{-schema}::SomeTable->ColumnType(ColType_Example =>
#   qw/column1 column2 .../);

__END_OF_CODE__

  while (my ($type, $targets) = each %{$self->{column_types} || {}}) {
    $code .= <<__END_OF_CODE__;
# $type
$self->{-schema}->ColumnType($type =>
  fromDB => sub {},   # SKELETON .. PLEASE FILL IN
  toDB   => sub {});
__END_OF_CODE__

    while (my ($table, $cols) = each %$targets) {
      $code .= sprintf("%s::%s->ColumnType($type => qw/%s/);\n",
                       $self->{-schema}, $table, join(" ", @$cols));
    }
    $code .= "\n";
  }

  # end of module
  $code .= "\n\n1;\n";

  return $code;
}

#----------------------------------------------------------------------
# utility methods/functions
#----------------------------------------------------------------------

# generate a Perl classname from a database table name
sub _table2class{
  my ($tablename) = @_;

  my $classname = join '', map ucfirst, split /[\W_]+/, lc $tablename;
}

# singular / plural inflection. Start with simple-minded defaults,
# and try to more sophisticated use Lingua::Inflect if module is installed
my $to_S  = sub {(my $r = $_[0]) =~ s/s$//i; $r};
my $to_PL = sub {$_[0] . "s"};
eval "use Lingua::EN::Inflect::Phrase qw/to_S to_PL/;"
   . "\$to_S = \\&to_S; \$to_PL = \\&to_PL;"
  or warn "Lingua::EN::Inflect::Phrase is recommended; please install it to "
        . "generate better names for associations";
;

# generate a rolename from a database table name
sub _table2role{
  my ($tablename, $plural) = @_;

  my $inflect         = $plural ? $to_PL : $to_S;
  # my ($first, @other) = map {$inflect->($_)} split /[\W_]+/, lc $tablename;
  # my $role            = join '_', $first, @other;
  my $role            = $inflect->(lc $tablename);
  return $role;
}


1; 

__END__

=head1 NAME

DBIx::DataModel::Schema::Generator - automatically generate a schema for DBIx::DataModel

=head1 SYNOPSIS

=head2 Command-line API

  perl -MDBIx::DataModel::Schema::Generator      \
       -e "fromDBI('dbi:connection:string')" --  \
       -schema My::New::Schema > My/New/Schema.pm

  perl -MDBIx::DataModel::Schema::Generator      \
       -e "fromDBIxClass('Some::DBIC::Schema')" -- \
       -schema My::New::Schema > My/New/Schema.pm

If L<SQL::Translator|SQL::Translator> is installed

  sqlt -f <parser> -t DBIx::DataModel::Schema::Generator <parser_input>

=head2 Object-oriented API

  use DBIx::DataModel::Schema::Generator;
  my $generator 
    = DBIx::DataModel::Schema::Generator(schema => "My::New::Schema");

  $generator->parse_DBI($connection_string, $user, $passwd, \%options);
  $generator->parse_DBI($dbh);

  $generator->parse_DBIx_Class($class_name);

  $generator->parse_SQL_Translator($translator);

  my $perl_code = $generator->perl_code;

  $generator->load();


=head1 DESCRIPTION

Generates schema, table and association declarations
for L<DBIx::DataModel|DBIx::DataModel>, either from
a L<DBI|DBI> connection, or from an existing 
L<DBIx::Class|DBIx::Class> schema. The result is written
on standard output and can be redirected to a F<.pm> file.

The module can be called easily from the perl command line,
as demonstrated in the synopsis above. Command-line arguments
after C<--> are passed to method L<new>.

Alternatively, if L<SQL::Translator|SQL::Translator> is 
installed, you can use C<DBIx::DataModel::Schema::Generator>
as a producer, translating from any available
C<SQL::Translator> parser.

Associations are derived from foreign key constraints declared in
the database. If clause C<ON DELETE CASCADE> is present, this is
interpreted as a composition; otherwise as an association.

The generated code is a skeleton that most probably will need some
manual additions or modifications to get a fully functional datamodel,
because part of the information cannot be inferred automatically. In
particular, you should inspect the names and multiplicities of the
generated associations, and decide which of these associations should
rather be L<compositions|DBIx::DataModel::Doc::Reference/Composition>;
and you should declare the L<column
types|DBIx::DataModel::Doc::Reference/ColumnType> for columns that
need automatic inflation/deflation.


=head1 METHODS

=head2 new

  my $generator = DBIx::DataModel::Schema::Generator->new(@args);

Creates a new instance of a schema generator.
Functions L<fromDBI> and L<fromDBIxClass> automatically call
C<new> if necessary, so usually you do not need to call it yourself.
Arguments are :

=over

=item -schema

Name of the L<DBIx::DataModel::Schema|DBIx::DataModel::Schema>
subclass that will be generated (default is C<My::Schema>).

=back


=head2 fromDBI

  $generator->fromDBI(@dbi_connection_args, $catalog, $schema, $type);
  # or
  fromDBI(@dbi_connection_args, $catalog, $schema, $type);

Connects to a L<DBI|DBI> data source, gathers information from the
database about tables, primary and foreign keys, and generates
a C<DBIx::DataModel> schema on standard output.

This can be used either as a regular method, or as 
a function (this function is exported by default).
In the latter case, a generator is automatically 
created by calling L<new> with arguments C<@ARGV>.

The DBI connection arguments are as in  L<DBI/connect>.
Alternatively, an already connected C<$dbh> can also be
passed as first argument to C<fromDBI()>.

The remaining arguments C<$catalog>, C<$schema> and C<$type> are optional;
they will be passed as arguments to L<DBI/table_info>.
The default values are C<undef>, C<undef> and C<'TABLE'>.


=head2 fromDBIxClass

  $generator->fromDBIxClass('Some::DBIC::Schema');
  # or
  fromDBIxClass('Some::DBIC::Schema');

Loads an existing  L<DBIx::Class|DBIx::Class> schema, and translates
its declarations into a C<DBIx::DataModel> schema 
printed on standard output.

This can be used either as a regular method, or as 
a function (this function is exported by default).
In the latter case, a generator is automatically 
created by calling L<new> with arguments C<@ARGV>.

=head2 produce

Implementation of L<SQL::Translator::Producer|SQL::Translator::Producer>.


=head2 parse_DBI

First step of L</FromDBI> : gather data from a L<DBI> connection and
populate internal datastructures.

=head2 parse_DBIx_Class

First step of L</FromDBIxClass> : gather data from a L<DBIx::Class> schema and
populate internal datastructures.

=head2 parse_SQL_Translator

First step of L</produce> : gather data from a L<SQL::Translator> instance and
populate internal datastructures.

=head2 perl_code

Emits perl code from the internal datastructures parsed by one of the methods above.

=head2 load();

Immediately evals the generated perl code.


=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat  ge  chE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.




