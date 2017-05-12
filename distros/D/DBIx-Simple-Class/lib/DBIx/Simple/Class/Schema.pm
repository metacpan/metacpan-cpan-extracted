package DBIx::Simple::Class::Schema;
use strict;
use warnings;
use 5.010001;
use Carp;
use Data::Dumper;
use parent 'DBIx::Simple::Class';

our $VERSION = '0.006';


*_get_obj_args = \&DBIx::Simple::Class::_get_obj_args;

#struct to keep schemas while building
my $schemas = {};

#for accessing schema structures during tests
sub _schemas {
  $_[2] && ($schemas->{$_[1]} = $_[2]);
  return $_[1] && exists $schemas->{$_[1]} ? $schemas->{$_[1]} : $schemas;
}

sub _get_table_info {
  my ($class, $args) = _get_obj_args(@_);

  $args->{namespace} || Carp::croak('Please pass "namespace" argument');

  #get tables from the current database
  #see https://metacpan.org/module/DBI#table_info
  return $schemas->{$args->{namespace}}{tables} = $class->dbh->table_info(
    undef, undef,
    $args->{table} || '%',
    $args->{type}  || "'TABLE','VIEW'"
  )->fetchall_arrayref({});

}

sub _get_column_info {
  my ($class, $tables) = @_;
  my $dbh = $class->dbh;
  foreach my $t (@$tables) {
    $t->{column_info} =
      $dbh->column_info(undef, undef, $t->{TABLE_NAME}, '%')->fetchall_arrayref({});

    #TODO support multi_column primary keys.see DSC::find()
    $t->{PRIMARY_KEY} =
      $dbh->primary_key_info(undef, undef, $t->{TABLE_NAME})->fetchall_arrayref({})
      ->[0]->{COLUMN_NAME} || '';

    #as child table
    my $sth =
      $dbh->foreign_key_info(undef, undef, undef, undef, undef, $t->{TABLE_NAME});
    $t->{FOREIGN_KEYS} = $sth->fetchall_arrayref({}) if $sth;

  }
  return $tables;
}

#generates COLUMNS and PRIMARY_KEY
sub _generate_COLUMNS_ALIASES_CHECKS {
  my ($class, $tables) = @_;

  foreach my $t (@$tables) {
    $t->{COLUMNS}           = [];
    $t->{ALIASES}           = {};
    $t->{CHECKS}            = {};
    $t->{QUOTE_IDENTIFIERS} = 0;
    foreach my $col (sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} }
      @{$t->{column_info}})
    {
      push @{$t->{COLUMNS}}, $col->{COLUMN_NAME};

      #generate ALIASES
      if ($col->{COLUMN_NAME} =~ /\W/) {    #not A-z0-9_
        $t->{QUOTE_IDENTIFIERS} ||= 1;
        $t->{ALIASES}{$col->{COLUMN_NAME}} = $col->{COLUMN_NAME};
        $t->{ALIASES}{$col->{COLUMN_NAME}} =~ s/\W/_/g;    #foo-bar=>foo_bar
      }
      elsif ($class->SUPER::can($col->{COLUMN_NAME})) {
        $t->{ALIASES}{$col->{COLUMN_NAME}} = 'column_' . $col->{COLUMN_NAME};
      }

      # generate CHECKS
      if ($col->{IS_NULLABLE} eq 'NO') {
        $t->{CHECKS}{$col->{COLUMN_NAME}}{required} = 1;
        $t->{CHECKS}{$col->{COLUMN_NAME}}{defined}  = 1;
      }
      if ($col->{COLUMN_DEF} && $col->{COLUMN_DEF} !~ /NULL/i) {
        my $default = $col->{COLUMN_DEF};
        $default =~ s|\'||g;
        $t->{CHECKS}{$col->{COLUMN_NAME}}{default} = $default;
      }
      my $size = $col->{COLUMN_SIZE} // 0;
      if ($size >= 65535 || $size == 0) {
        $size = '';
      }
      if ($col->{TYPE_NAME} =~ /INT/i) {
        $t->{CHECKS}{$col->{COLUMN_NAME}}{allow} = qr/^-?\d{1,$size}$/x;
      }
      elsif ($col->{TYPE_NAME} =~ /FLOAT|DOUBLE|DECIMAL/i) {
        my $scale = $col->{DECIMAL_DIGITS} || 0;
        my $precision = $size - $scale;
        $t->{CHECKS}{$col->{COLUMN_NAME}}{allow} =
          qr/^-?\d{1,$precision}(?:\.\d{0,$scale})?$/x;
      }
      elsif ($col->{TYPE_NAME} =~ /CHAR|TEXT|CLOB/i) {
        $t->{CHECKS}{$col->{COLUMN_NAME}}{allow} =
          sub { ($_[0] =~ /^.{1,$size}$/x) || ($_[0] eq '') }
      }
    }    #end foreach @{$t->{column_info}
  }    #end foreach $tables
  return $tables;
}

my $_MAKE_SCHEMA;

sub _MAKE_SCHEMA {
  $_MAKE_SCHEMA = $_[1] if defined $_[1];
  return $_MAKE_SCHEMA;
}

sub _generate_CODE {
  my ($class, $args) = @_;
  my $code      = '';
  my $namespace = $args->{namespace};
  my $tables    = $schemas->{$namespace}{tables};
  $schemas->{$namespace}{code} = [];
  if ($class->_MAKE_SCHEMA) {
    push @{$schemas->{$namespace}{code}}, <<"BASE_CLASS";
package $namespace; #The schema/base class
use 5.010001;
use strict;
use warnings;
use utf8;
use parent qw(DBIx::Simple::Class);

our \$VERSION = '0.01';
sub is_base_class{return 1}
sub dbix {

  # Singleton DBIx::Simple instance
  state \$DBIx;
  return (\$_[1] ? (\$DBIx = \$_[1]) : \$DBIx)
    || Carp::croak('DBIx::Simple is not instantiated. Please first do '
      . \$_[0]
      . '->dbix(DBIx::Simple->connect(\$DSN,\$u,\$p,{...})');
}

1;
$/$/=pod$/$/=encoding utf8$/$/=head1 NAME$/$/$namespace - the base schema class.
$/=head1 DESCRIPTION

This is the base class for using table records as plain Perl objects.
The subclassses are:$/$/=over
BASE_CLASS
  }
  foreach my $t (@$tables) {
    my $package =
      $namespace . '::' . (join '', map { ucfirst lc } split /_/, $t->{TABLE_NAME});
    my $COLUMNS = Data::Dumper->Dump([$t->{COLUMNS}],    ['$COLUMNS']);
    my $ALIASES = Data::Dumper->Dump([$t->{ALIASES}],    ['$ALIASES']);
    my $CHECKS  = Data::Dumper->Dump([$t->{CHECKS}],     ['$CHECKS']);
    my $TABLE   = Data::Dumper->Dump([$t->{TABLE_NAME}], ['$TABLE_NAME']);
    my $name_description =
      "A class for $t->{TABLE_TYPE} $t->{TABLE_NAME} in schema $t->{TABLE_SCHEM}";
    $schemas->{$namespace}{code}[0] .= qq|$/=item L<$package> - $name_description$/|
      if $class->_MAKE_SCHEMA;
    push @{$schemas->{$namespace}{code}}, qq|package $package; #A table/row class
use 5.010001;
use strict;
use warnings;
use utf8;
use parent qw($namespace);
| . qq|
sub is_base_class{return 0}
my $TABLE
sub TABLE {return \$TABLE_NAME}| . qq|
sub PRIMARY_KEY{return '$t->{PRIMARY_KEY}'}
my $COLUMNS
sub COLUMNS {return \$COLUMNS}
my $ALIASES
sub ALIASES {return \$ALIASES}
my $CHECKS
sub CHECKS {return \$CHECKS}

__PACKAGE__->QUOTE_IDENTIFIERS($t->{QUOTE_IDENTIFIERS});
#__PACKAGE__->BUILD;#build accessors during load

1;
| . qq|$/=pod$/$/=encoding utf8$/$/=head1 NAME$/$/$name_description

| . qq|=head1 SYNOPSIS$/$/=head1 DESCRIPTION$/$/=head1 COLUMNS$/
Each column from table C<$t->{TABLE_NAME}> has an accessor method in this class.
|
      . (join '', map { $/ . '=head2 ' . $_ . $/ } @{$t->{COLUMNS}})
      . qq|$/=head1 ALIASES$/$/=head1 GENERATOR$/$/L<$class>$/$/=head1 SEE ALSO$/|
      . qq|L<$namespace>, L<DBIx::Simple::Class>, L<$class>
$/=head1 AUTHOR$/$/$ENV{USER}$/$/=cut
|;
  }    # end foreach my $t (@$tables)

  $schemas->{$namespace}{code}[0] .= qq|$/=back$/$/=head1 GENERATOR$/$/L<$class>
$/$/=head1 SEE ALSO$/$/
L<$class>, L<DBIx::Simple::Class>, L<DBIx::Simple>, L<Mojolicious::Plugin::DSC>
$/=head1 AUTHOR$/$/$ENV{USER}$/$/=cut
| if $class->_MAKE_SCHEMA;
  if (defined wantarray) {
    if (wantarray) {
      return @{$schemas->{$namespace}{code}};
    }
    else {
      return join '', @{$schemas->{$namespace}{code}};
    }
  }
  return;
}

sub load_schema {
  my ($class, $args) = _get_obj_args(@_);
  unless ($args->{namespace}) {
    $args->{namespace} = $class->dbh->{Name};
    if ($args->{namespace} =~ /(database|dbname|db)=([^;]+);?/x) {
      $args->{namespace} = $2;
    }
    $args->{namespace} =~ s/\W//xg;
    $args->{namespace} =
      'DSCS::' . (join '', map { ucfirst lc } split /_/, $args->{namespace});
  }

  my $tables = $class->_get_table_info($args);

  #get table columns, PRIMARY_KEY, foreign keys
  $class->_get_column_info($tables);

  #generate COLUMNS, ALIASES, CHECKS
  $class->_generate_COLUMNS_ALIASES_CHECKS($tables);
  $class->_MAKE_SCHEMA(($args->{table} eq '%') or (not $args->{table}));

  #generate code
  if (wantarray) {
    return ($class->_generate_CODE($args));
  }
  return $class->_generate_CODE($args);
}


sub dump_schema_at {
  my ($class, $args) = _get_obj_args(@_);
  $args->{lib_root} ||= $INC[0];
  my ($namespace, @namespace, @base_path, $schema_path);

  #_generate_CODE() should be called by now
  #we always have only one key
  $namespace = (keys %$schemas)[0]
    || Carp::croak('Please first call ' . __PACKAGE__ . '->load_schema()!');

  require File::Path;
  require File::Spec;
  require IO::File;
  @namespace = split /::/, $namespace;
  @base_path = File::Spec->splitdir($args->{lib_root});

  $schema_path = File::Spec->catdir(@base_path, @namespace);

  if (eval "require $namespace" && $class->_MAKE_SCHEMA) {
    carp( "Module $namespace is already installed at "
        . $INC{join('/', @namespace) . '.pm'}
        . ". Please avoid namespace collisions...");
  }
  say('Will dump classes at ' . $args->{lib_root});

  #We should be able to continue safely now...
  my $tables = $schemas->{$namespace}{tables};
  my $code   = $schemas->{$namespace}{code};
  if (!-d $schema_path) {
    eval { File::Path::make_path($schema_path); }
      || carp("Can not make path $schema_path.$/$!. Quitting...") && return;
  }

  if ($class->_MAKE_SCHEMA) {
    carp("Overwriting $schema_path.pm...") if $args->{overwrite} && $class->DEBUG;
    my $base_fh = IO::File->new("> $schema_path.pm")
      || Carp::croak("Could not open $schema_path.pm for writing" . $!);
    print $base_fh $code->[0];
    $base_fh->close;
  }

  foreach my $i (0 .. @$tables - 1) {
    my $filename =
      (join '', map { ucfirst lc } split /_/, $tables->[$i]{TABLE_NAME}) . '.pm';
    next if (-f "$schema_path/$filename" && !$args->{overwrite});
    carp("Overwriting $schema_path/$filename...")
      if $args->{overwrite} && $class->DEBUG;
    my $fh = IO::File->new("> $schema_path/$filename");
    if (defined $fh) {
      print $fh $code->[$i + 1];
      $fh->close;
    }
    else {
      carp("$schema_path/$filename: $!. Quitting!");
      return;
    }
  }
  return 1;
}

1;


=encoding utf8

=head1 NAME

DBIx::Simple::Class::Schema - Create and use classes representing tables from a database

=head1 SYNOPSIS

  #Somewhere in a utility script or startup() of your application.
  DBIx::Simple::Class::Schema->dbix(DBIx::Simple->connect(...));
  my $perl_code = DBIx::Simple::Class::Schema->load_schema(
    namespace =>'My::Model',
    table => '%',              #all tables from the current database
    type  => "'TABLE','VIEW'", # make classes for tables and views
  );

  #Now eval() to use your classes.
  eval $perl_code || Carp::croak($@);


  #Or load and save it for more customisations and later usage.
  DBIx::Simple::Class::Schema->load_schema(
    namespace =>'My::Model',
    table => '%',              #all tables from the current database
    type  => "'TABLE','VIEW'", # make classes for tables and views
  );
  DBIx::Simple::Class::Schema->dump_schema_at(
    lib_root => "$ENV{PERL_LOCAL_LIB_ROOT}/lib"
    overwrite =>1 #overwrite existing files
  ) || Carp::croak 'Something went wrong! See above...';


=head1 DESCRIPTION

DBIx::Simple::Class::Schema automates the creation of classes from
database tables. You can use it when you want to prototype quickly
your application. It is also very convenient as an initial generator and dumper of
your classes representing your database tables.

=head1 METHODS

=head2 load_schema

Class method.

  Params:
    namespace - String. The class name for your base class,
      default: 'DSCS::'.(join '', map { ucfirst lc } split /_/, $database)
    table - SQL string for a LIKE clause,
      default: '%'
    type - SQL String for an IN clause.
      default: "'TABLE','VIEW'"

Extracts tables' information from the current connection and generates
Perl classes representing those tables or/and views.
If called in list context returns an array with perl code for each package.
The first package is the base class. The base class is generated only the argument C<table> is '%' or empty.
If called in scalar context returns all the generated code as a string.

The generated classes are saved internally and are available for use by
L</dump_schema_at>.
This makes it very convenient for quickly prototyping applications
by just modifying tables in your database.

  my $perl_code = DBIx::Simple::Class::Schema->load_schema();
  #concatenaded code as one string
  eval $perl_code || Carp::croak($@);
  #...
  my $user = Dbname::User->find(2345);
  
  #or My::Schema, My::Schema::Table1, My::Schema::Table2,...
  my @perl_code = DBIx::Simple::Class::Schema->load_schema();
  
  #or just prepare code before dumping it to disk.
  DBIx::Simple::Class::Schema->load_schema();

=head2 dump_schema_at

Class method.

  Params:
    lib_root: String - Where classes will be dumped.
      default: $INC[0]
    overwrite: boolean -1/0 Should it overwrite existing classes with the same name?
      default: 0

Uses the generated code by L</load_schema> and saves each class on the disk.
Does several checks:

=over

=item *

Checks if a file with the name of your base class exists and exits
if the flag C<overwrite> is not set.

=item *

The base class is dumped to disk only if the argument C<table> is '%' or empty.
It was not generated in L</load_schema>. 
In other words base/schema class is generated when no specific table class is 
required to be generated. This is convinient if you want to generate only specific table-classes and use them on-the-fly without dumping them to disk.

=item *

Checks if there is a module with the same name as your base class installed
and warns if there is such module. This is done to avoid namespace collisions.

=item *

Checks if the files can be written to disk and exit immediately if there is a problem.

=back

For every check above issues a warning so you, the developer, can decide what to do.
Returns true on success.

=head1 SUPPORTED DATABASE DRIVERS

DBIx::Simple::Class::Schema strives to be DBD agnostic and
uses only functionality specified by L<DBI>.
This means that if a driver implements the methods specifyed in L<DBI> it is supported.
However currently only tests for L<DBD::SQLite> and L<DBD::mysql> are written.
Feel free to contribute with tests for your prefered driver.
The following methods are used to retreive information form the database:

=over

=item * L<DBI/table_info>

=item * L<DBI/column_info>

=item * L<DBI/primary_key_info>

=back

=head1 SUPPORTED SQL TYPES

Currently some minimal L<DBIx::Simple::Class/CHECKS> are automatically generated for TYPE_NAMEs
matching C</INT/i>,C</FLOAT|DOUBLE|DECIMAL/i>, C</CHAR|TEXT|CLOB/i>.
You are supposed to write your own business-specific checks.


=head1 SEE ALSO

L<DBIx::Simple::Class>, L<DBIx::Simple>, L<DBIx::Class::Schema::Loader>,
L<Mojolicious::Plugin::DSC>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

See http://www.opensource.org/licenses/artistic-license-2.0 for more information.

=cut

