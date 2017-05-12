package DBIx::Simple::Class;
use 5.010001;
use strict;
use warnings;
use Carp;
use Params::Check;
use DBIx::Simple;

our $VERSION = '1.009';


#CONSTANTS

#defauld debug mode
my $DEBUG = 0;
sub DEBUG { defined $_[1] ? ($DEBUG = $_[1]) : $DEBUG }

#abstract tablename
sub TABLE {
  croak("You must define a table-name for your class: sub TABLE {'tablename'}!");
}

#abstract table columns
sub COLUMNS {
  croak("You must define fields for your class: sub COLUMNS {['id','name','etc']}!");
}

#Used to validate params to field-setters
#Passed to Params::Check::check()
sub CHECKS {
  croak(
    "You must define your CHECKS subroutine that returns your private \$_CHECKS HASHREF!"
  );
}

sub is_base_class {
  no strict 'refs';
  return scalar grep { __PACKAGE__ eq $_ } @{"$_[0]\::ISA"};
}

#default where
sub WHERE { {} }

#default primary key
sub PRIMARY_KEY {'id'}

#no default aliases
sub ALIASES { {} }

#should we quote identifiers for a class or not?
sub QUOTE_IDENTIFIERS {
  my $class = shift;
  state $QUOTE_IDENTIFIERS = {};
  return $QUOTE_IDENTIFIERS->{$class} //= shift || '';
}

#Used to store unquoted identifirers as they were before quoting
#See BUILD()
sub _UNQUOTED {
  my $class = ref $_[0] || $_[0];    #class
  state $UNQUOTED = {};
  return $UNQUOTED->{$class} //= {};
}

#for outside modification during tests
my $_attributes_made = {};
sub _attributes_made {$_attributes_made}

#stored generated SQL strings
my $SQL_CACHE = {};
sub _SQL_CACHE {$SQL_CACHE}

my $SQL = {};
$SQL = {
  SELECT => sub {

    #my $class = shift;
    return $SQL_CACHE->{$_[0]}{SELECT} ||= do {
      my $where = $_[0]->WHERE;
      my $dbh   = $_[0]->dbix->dbh;
      'SELECT '
        . join(',', @{$_[0]->COLUMNS})
        . ' FROM '
        . $_[0]->TABLE
        . (
        (keys %$where)
        ? ' WHERE '
          . join(
          ' AND ', map { "$_=" . $dbh->quote($where->{$_}) }
            keys %$where
          )
        : ''
        );
      }
  },
  INSERT => sub {
    my $class = $_[0];

    #cache this query and return it
    return $SQL_CACHE->{$class}{INSERT} ||= do {
      my ($pk, $table, @columns) =
        ($class->PRIMARY_KEY, $class->TABLE, @{$class->COLUMNS});

      #return of the do
      "INSERT INTO $table ("
        . join(',', @columns)
        . ') VALUES('
        . join(',', map {'?'} @columns) . ')';
    };
  },
  UPDATE => sub {
    my $class = $_[0];

    #cache this query and return it
    return $SQL_CACHE->{$class}{UPDATE} ||= do {
      my $pk = $class->PRIMARY_KEY;

      #do we always update all columns?!?! Yes, if we always retreive all columns.
      my $SET = join(', ', map {qq($/$_=?)} @{$class->COLUMNS});
      'UPDATE ' . $class->TABLE . " SET $SET WHERE $pk=%s";
      }
  },
  SELECT_BY_PK => sub {

    #my $class = $_[0];

    #cache this query and return it
    return $SQL_CACHE->{$_[0]}{SELECT_BY_PK} ||= do {
      'SELECT '
        . join(',', @{$_[0]->COLUMNS})
        . ' FROM '
        . $_[0]->TABLE
        . ' WHERE '
        . $_[0]->PRIMARY_KEY . '=?';
    };
  },

  _LIMIT => sub {

#works for MySQL, SQLite, PostgreSQL
#TODO:See SQL::Abstract::Limit for other implementations
#and implement it using this technique.
croak('SQL LIMIT requires at least one integer parameter or placeholder')
  unless defined($_[1]);
  return " LIMIT $_[1]" . (defined($_[2]) ? " OFFSET $_[2] " : '');
  },
};

# generate(d) limit clause
sub SQL_LIMIT {
  return $SQL->{_LIMIT}->(@_);
}

sub SQL {
  my ($class, $args) = _get_obj_args(@_);    #class
  croak('This is a class method. Do not use as object method.') if ref $class;

  if (ref $args) {                           #adding new SQL strings($k=>$v pairs)
    return $SQL->{$class} = {%{$SQL->{$class} || $SQL}, %$args};
  }

  #a key
  elsif ($args) {

    #do not return hidden keys
    croak("Named query '$args' can not be used directly") if $args =~ /^_+/x;

    #allow subclasses to override parent sqls and cache produced SQL
    my $_SQL =
         $SQL_CACHE->{$class}{$args}
      || $SQL->{$class}{$args}
      || $SQL->{$args}
      || $args;
    if (ref $_SQL) {
      return $_SQL->(@_);
    }
    else {
      return $_SQL;
    }
  }

  #they want all
  return $SQL;
}


#ATTRIBUTES

#copy/paste/override this method in your base schema classes
#if you want more instances per application
sub dbix {

  # Singleton DBIx::Simple instance
  state $DBIx;
  return ($_[1] ? ($DBIx = $_[1]) : $DBIx)
    || croak('DBIx::Simple is not instantiated. Please first do '
      . $_[0]
      . '->dbix(DBIx::Simple->connect($DSN,$u,$p,{...})');
}

sub dbh { $_[0]->dbix->dbh }

#METHODS

sub new {
  my ($class, $fields) = _get_obj_args(@_);
  local $Params::Check::WARNINGS_FATAL = 1;
  local $Params::Check::CALLER_DEPTH   = $Params::Check::CALLER_DEPTH + 1;

  $fields = Params::Check::check($class->CHECKS, $fields)
    || croak(Params::Check::last_error());
  $class->BUILD()
    unless $_attributes_made->{$class};
  return bless {data => $fields}, $class;
}

sub new_from_dbix_simple {
  if (wantarray) {
    return (map { bless {data => $_, new_from_dbix_simple => 1}, $_[0]; }
        @{$_[1]->{st}->{sth}->fetchall_arrayref({})});
  }
  return bless {

    #$_[1]->hash
    data =>
      $_[1]->{st}->{sth}->fetchrow_hashref($_[1]->{lc_columns} ? 'NAME_lc' : 'NAME'),
    new_from_dbix_simple => 1
    },
    $_[0];
}

sub select {
  my ($class, $where) = _get_obj_args(@_);
  $_attributes_made->{$class} || $class->BUILD();
  $class->new_from_dbix_simple(
    $class->dbix->select($class->TABLE, $class->COLUMNS, {%{$class->WHERE}, %$where}));
}

sub query {
  my $class = shift;
  $_attributes_made->{$class} || $class->BUILD();
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->dbix->query(@_) if $class->is_base_class;
  $class->new_from_dbix_simple($class->dbix->query(@_));
}

sub select_by_pk {
  my ($class, $pk) = @_;
  $_attributes_made->{$class} || $class->BUILD();
  return $class->new_from_dbix_simple(
    $class->dbix->query(
      $SQL_CACHE->{$class}{SELECT_BY_PK} || $class->SQL('SELECT_BY_PK'), $pk
    )
  );
}

{
  no warnings qw(once);
  *find = \&select_by_pk;
}

sub BUILD {
  my $class = shift;

  #TODO: Make DEBUG swichable per class
  $class->dbh->{Callbacks}{prepare} = sub {
    $DEBUG || return;
    my ($dbh, $query, $attrs) = @_;
    my ($package, $filename, $line, $subroutine) = caller(2);
    carp("SQL from $subroutine in $filename:$line :\n$query\n");
    return;
  };
  #
  if ($class->is_base_class) {
    carp "Nothing more to build. This is the base class: $class" if $DEBUG;
    return;
  }
  (!ref $class)
    || croak("Call this method as $class->BUILD()");
  $class->_UNQUOTED->{TABLE}   = $class->TABLE;
  $class->_UNQUOTED->{WHERE}   = {%{$class->WHERE}};      #copy
  $class->_UNQUOTED->{COLUMNS} = [@{$class->COLUMNS}];    #copy

  my $code = '';
  foreach (@{$class->_UNQUOTED->{COLUMNS}}) {

    my $alias = $class->ALIASES->{$_} || $_;
    croak("You can not use '$alias' as a column name since it is already defined in "
        . __PACKAGE__
        . '. Please define an \'alias\' for the column to be used as method.')
      if __PACKAGE__->can($alias);
    next if $class->can($alias);                          #careful: no redefine
    $code = "package $class; use strict;$/use warnings;$/use utf8;$/" unless $code;
    $code .= <<"SUB";
sub $alias {
  my (\$s,\$v) = \@_;
  if(defined \$v){ #setting value
    #Not using Params::Check
    my \$allow = (\$s->CHECKS->{qq{$_}}?\$s->CHECKS->{qq{$_}}{allow}:'')||'';
    if(ref \$allow eq 'CODE'){
     \$s->{data}{qq{$_}} = \$allow->(\$v) ? \$v : Carp::croak("$_ is of invalid type");
    }
    elsif(ref \$allow eq 'Regexp'){
      \$s->{data}{qq{$_}} = 
        \$v =~ \$allow ? \$v : Carp::croak("$_ is of invalid type");
    }
    elsif(\$allow && !ref \$allow){
      \$s->{data}{qq{$_}} = 
        \$v eq \$allow ? \$v : Carp::croak("$_ is of invalid type");
    }
    else{
      \$s->{data}{qq{$_}} = \$v;
    }
    #\$s->_check(qq{$_}=>\$v);#Using Params::Check
    #make it chainable
    return \$s;
  }
  #getting value
  return \$s->{data}{qq{$_}} //= \$s->CHECKS->{qq{$_}}{default}; #getting value
}

SUB

  }

  my $dbh = $class->dbh;
  if ($class->QUOTE_IDENTIFIERS) {
    $code
      .= 'no warnings qw"redefine";'
      . "sub $class\::TABLE {'"
      . $dbh->quote_identifier($class->TABLE) . "'}";
    my %where = %{$class->WHERE};
    $code .= "sub $class\::WHERE {{";
    for (keys %where) {
      $code
        .= 'qq{'
        . $dbh->quote_identifier($_)
        . '}=>qq{'
        . $dbh->quote($where{$_}) . '}, '
        . $/;
    }
    $code .= '}}#end WHERE' . $/;
    my @columns = @{$class->COLUMNS};
    $code .= "sub $class\::COLUMNS {[";
    for (@columns) {
      $code .= 'qq{' . $dbh->quote_identifier($_) . '},';
    }
    $code .= ']}#end COLUMNS' . $/;
  }    #if ($class->QUOTE_IDENTIFIERS)
  $code .= "$/1;";

  #I know what I am doing. I think so...
  unless (eval $code) {    ##no critic (BuiltinFunctions::ProhibitStringyEval)
    croak($class . " compiler error: $/$code$/$@$/");
  }
  if ($class->DEBUG) {
    carp($class . " generated accessors: $/$code$/$@$/");
  }

  #make sure we die loudly
  $dbh->{RaiseError} = 1;
  return $_attributes_made->{$class} = 1;
}


#conveninece for getting key/vaule arguments
sub _get_args {
  return ref($_[0]) ? $_[0] : (@_ % 2) ? $_[0] : {@_};
}
sub _get_obj_args { return (shift, ref($_[0]) ? $_[0] : (@_ % 2) ? $_[0] : {@_}); }

sub _check {
  my ($self, $key, $value) = @_;
  local $Params::Check::WARNINGS_FATAL = 1;
  local $Params::Check::CALLER_DEPTH   = $Params::Check::CALLER_DEPTH + 1;

  my $args_out =
    Params::Check::check({$key => $self->CHECKS->{$key} || {}}, {$key => $value});
  return $args_out->{$key};
}

#fieldvalues HASHREF
sub data {
  my ($self, $args) = _get_obj_args(@_);
  if (ref $args && keys %$args) {
    for my $field (keys %$args) {
      my $alias = $self->ALIASES->{$field} || $field;
      unless (grep { $field eq $_ } @{$self->_UNQUOTED->{COLUMNS}}) {
        Carp::cluck(
          "There is not such field $field in table " . $self->TABLE . '! Skipping...')
          if $DEBUG;
        next;
      }

      #we may have getters/setters written by the author of the subclass
      # so call each setter separately
      $self->$alias($args->{$field});
    }
  }

  #a key (!ref $args)
  elsif (!ref $args) {
    my $alias = $self->ALIASES->{$args} || $args;
    return $self->$alias;
  }

  #they want all that we touched in $self->{data}
  return $self->{data};
}

sub save {
  my ($self, $data) = _get_obj_args(@_);

  #allow data to be passed directly and overwrite current data
  if (keys %$data) { $self->data($data); }
  local $Carp::MaxArgLen = 0;
  if (!$self->{new_from_dbix_simple}) {
    return $self->{new_from_dbix_simple} = $self->insert();
  }
  else {
    return $self->update();
  }
  return;
}

sub update {
  my ($self) = @_;
  my $pk = $self->PRIMARY_KEY;
  $self->{data}{$pk} || croak('Please define primary key column (\$self->$pk(?))!');
  my $dbh = $self->dbh;
  $self->{SQL_UPDATE} ||= do {
    my $SET =
      join(', ', map { $dbh->quote_identifier($_) . '=? ' } keys %{$self->{data}});
    'UPDATE ' . $self->TABLE . " SET $SET WHERE $pk=?";
  };
  return $dbh->prepare($self->{SQL_UPDATE})
    ->execute(values %{$self->{data}}, $self->{data}{$pk});
}

sub insert {
  my ($self) = @_;
  my ($pk, $class) = ($self->PRIMARY_KEY, ref $self);

  $self->dbh->prepare_cached($SQL_CACHE->{$class}{INSERT} || $class->SQL('INSERT'))
    ->execute(
    map {

      #set expected defaults
      $self->data($_)
    } @{$class->_UNQUOTED->{COLUMNS}}
    );

  #user set the primary key already
  return $self->{data}{$pk}
    ||= $self->dbh->last_insert_id(undef, undef, $self->TABLE, $pk);

}

sub create {
  my $self = shift->new(@_);
  $self->insert;
  return $self;
}

1;

__END__


# If you have pod after  __END__,
#comment __END__ marker so you can generate/use
# additional perl tags using exuberant ctags.

# Example ctags filters to put in your ~/.ctags file:
#--regex-perl=/^\s*?use\s+(\w+[\w\:]*?\w*?)/\1/u,use,uses/
#--regex-perl=/^\s*?require\s+(\w+[\w\:]*?\w*?)/\1/r,require,requires/
#--regex-perl=/^\s*?has\s+['"]?(\w+)['"]?/\1/a,attribute,attributes/
#--regex-perl=/^\s*?\*(\w+)\s*?=/\1/a,aliase,aliases/
#--regex-perl=/->helper\(\s?['"]?(\w+)['"]?/\1/h,helper,helpers/
#--regex-perl=/^\s*?our\s*?[\$@%](\w+)/\1/o,our,ours/
#--regex-perl=/^=head1\s+(.+)/\1/p,pod,Plain Old Documentation/
#--regex-perl=/^=head2\s+(.+)/-- \1/p,pod,Plain Old Documentation/
#--regex-perl=/^=head[3-5]\s+(.+)/---- \1/p,pod,Plain Old Documentation/


