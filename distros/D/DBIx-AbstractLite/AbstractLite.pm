package DBIx::AbstractLite;

use strict;

=head1 NAME

DBIx::AbstractLite - Lightweight DBI SQL abstraction in a hybrid interface

=head1 SYNOPSIS

  use Project::DB;

  my $DB = new Project::DB; # connect to DB
  $DB->setWhere('date >= sysdate-1'); # global condition for all queries to follow
  my $sth = $DB->select({
      fields    => [ 'user', 'email' ],
      table     => 'users',
      where     => { 'user'             => [ 'like', 'me%' ],
                     'length(email)'    => [ '>', '20' ],
                     },
      }) or die $DB->error();
  print $sth->fetchrow_array();

  $DB->query('SELECT user, email FROM users WHERE user like ?', 'me%') 
    or die $DB->error();
  my $userEmail = $DB->fetch_hash();
  print "someuser's email is: ", $userEmail->{someuser}, "\n";

  $DB->query('SELECT email FROM users WHERE user = ?', 'me') 
    or die $DB->error();
  print "my email is ", $DB->fetch_col();


  package Project::DB;

  use DBIx::AbstractLite;
  use vars qw (@ISA);
  @ISA = qw(DBIx::AbstractLite);

  sub _initMembers {
    my ($self) = @_;

    $self->{DSN} = "dbi:Oracle:$ENV{ORACLE_SID}";
    $self->{USER} = 'username';
    $self->{PASS} = 'password';
  }

=head1 DESCRIPTION

This module is based on DBIx::Abstract, but is much simpler. 
It also doesn't deviate from the DBI interface as much as DBIx::Abstract does.
The main similarity between DBIx::AbstractLite and DBIx::Abstract 
is in the select method.
Unlike Abstract, AbstractLite is not 100% abstract in that it still allows 
conventional access to the DBI interface, 
using plain SQL and the DBI statement handle methods.

CGI::LogCarp is used internally to trace the queries sent to DBI.
To see the trace statements, add this statement at the beginning of your program:
  use CGI::LogCarp qw(:STDBUG);



MORE DOCUMENTATION TBD...

=cut

use DBI;
use Error::Dumb;
use CGI::LogCarp qw(:STDBUG);

use vars qw($VERSION @ISA);

@ISA = qw(Error::Dumb);
$VERSION = do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };


sub new {
  my ($class) = @_;
  
  my $self= {};
  $self->{WHERE} = undef; # a list of where conditions

  bless $self, $class;

  $self->_initMembers() if $self->can('_initMembers');

  $self->{DBH} = $self->connect() or die $DBI::errstr;
  trace "$self->{DSN} successfully connected\n";

  return $self;
}

sub DESTROY {
  my ($self) = @_;

  $self->{STH}->finish() if $self->{STH};

# don't disconnect if running under mod_perl and Apache::DBI
  return if $ENV{MOD_PERL};

  $self->disconnect() if $self;
}

sub connect {
  my ($self) = @_;

  return DBI->connect($self->{DSN}, $self->{USER}, $self->{PASS}, 
      { ChopBlanks => 1 } );
}

my %aliases = (
    group       => 'group_by',
    order       => 'order_by',
    );

sub select {
  my ($self, $args) = @_;

  my @bind = ();
  my @where = ();

  $args->{fields_global} = $self->{FIELDS};

# convert aliases
  while ( my ($alias, $real) = each %aliases ) {
    if ( defined $args->{$alias} ) {
      $args->{$real} = $args->{$alias};
      delete $args->{$alias};
    }
  }

# "join" arg is a special case. add it to @where list directly,
  if ( $args->{join} && ref $args->{join} eq 'ARRAY' ) {
    push @where, @{ $args->{join} }; 
    delete $args->{join};
  }

# convert scalar to arrayref, 
# then convert arrayref to comma-separated string.
# this is to accomodate a choice of input: either arrayref or scalar
  foreach my $key ( keys %$args ) {
    unless ( ref $args->{$key} ) {
      $args->{$key} = [ $args->{$key} ];
    }
    if ( ref $args->{$key} eq 'ARRAY') {
      $args->{$key} = join ', ', @{ $args->{$key} };
    }
  }

  $args->{fields} .= ", $args->{fields_global}" if $args->{fields_global};
  my $query = "SELECT $args->{fields} FROM $args->{table} ";
  if ( $args->{where} ) {
    while ( my ($key, $value) = each %{ $args->{where} } ) {
      my ($operator, $targetValue) = @$value;
      push @where, "($key $operator ?)"; 
      push @bind, $targetValue;
    }
  }
  if ( $args->{where_raw} ) {
    while ( my ($key, $value) = each %{ $args->{where_raw} } ) {
      my ($operator, $targetValue) = @$value;
      push @where, "($key $operator $targetValue)"; 
    }
  }
  push @where, @{ $self->{WHERE} } if $self->{WHERE};
  if ( @where ) {
    $query .= 'WHERE ';
    $query .= join ' AND ', @where;
  }
  if ( $args->{group_by} ) {
    $query .= " GROUP BY $args->{group_by}";
  }
  if ( $args->{order_by} ) {
    $query .= " ORDER BY $args->{order_by}";
  }
  if ( $args->{extra} ) {
    $query .= " $args->{extra}";
  }
  $self->{QUERY} = $query;
  $self->{BIND} = \@bind;
  return $self->_query();
}

sub query {
  my ($self, $query, @args) = @_;

  $self->{QUERY} = $query;
  $self->{BIND} = \@args;
  return $self->_query();
}

sub _query {
  my ($self) = @_;

  my @args = @{ $self->{BIND} };
  my $args = join ',', @args;
  trace "$self->{DSN} query: $self->{QUERY}; args: $args\n";
  $self->{STH} = $self->{DBH}->prepare($self->{QUERY}) 
    or return $self->_setError($self->{DBH}->errstr);
  $self->{STH}->execute(@args) or return $self->_setError($self->{STH}->errstr);
  
  return $self->{STH};
}

sub disconnect {
  my ($self) = @_;

  $self->{DBH}->disconnect() if $self->{DBH};
}

sub fetch_col {
  my ($self) = @_;

  my ($col) = $self->{STH}->fetchrow_array();
  return $col;
}

sub fetch_hash {
  my ($self) = @_;

  my $hash = {};
  while ( my ($key, $value) = $self->{STH}->fetchrow_array() ) {
    $hash->{$key} = $value;
  }

  return $hash;
}

sub setWhere {
  my ($self, $where) = @_;

  push @{ $self->{WHERE} }, $where;
}

sub getWhere {
  my ($self) = @_;

  if ( defined $self->{WHERE} ) {
    return ' WHERE ' . join (' AND ', @{ $self->{WHERE} }) . ' ';
  }
  else {
    return '';
  }
}

sub setFields {
  my ($self, $field) = @_;

  push @{ $self->{FIELDS} }, $field;
}

sub getDistinct {
  my ($self, $colname, $table) = @_;

  my @cols = ();
  my $sth = $self->select({
      fields    => "distinct($colname)",
      table     => $table
      });
  while ( my ($col) = $sth->fetchrow_array() ) {
    push @cols, $col;
  }
  return \@cols;
}

1;

__END__

=head1 AUTHOR

Ilia Lobsanov <ilia@lobsanov.com>

=head1 COPYRIGHT

  Copyright (c) 2001 Ilia Lobsanov, Nurey Networks Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
