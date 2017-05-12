package DBD::mysql::AutoTypes;

use strict;
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( mysql_auto_types );

our $VERSION = "1.0";
our $DBD_mysql_VERSION = 2.9002;

use Regexp::Common qw ( number );

sub _mysql_fix {
  my ($sth, $attr, @bind) = @_;
  my $n = 1;
  $sth->bind_param( $n, $_, 
    $attr->{TYPES} && $attr->{TYPES}[$n-1] || 
    /^$RE{num}{int}$/ ? DBI::SQL_INTEGER : 
    /^$RE{num}{real}$/ ? DBI::SQL_DOUBLE : 
    DBI::SQL_VARCHAR 
  ), $n++ foreach (@bind);
}

our $FIXES = {

  'selectall_arrayref' => { pkg => '_', code => sub {
    my ($dbh, $stmt, $attr, @bind) = @_;
    my $sth = ( ref $stmt ) ? $stmt : $dbh->prepare( $stmt, $attr ) or return;
    _mysql_fix( $sth, $attr, @bind);
    $sth->execute() || return;
    my $slice = $attr->{Slice};
    if (!$slice and $slice=$attr->{Columns}) {
      if (ref $slice eq 'ARRAY') {
        $slice = [ @{$attr->{Columns}} ];
        for (@$slice) { $_-- }
      }
    }
    return $sth->fetchall_arrayref($slice, $attr->{MaxRows});
  }},

  'selectall_hashref' => { pkg => '_', code => sub {
    my ($dbh, $stmt, $key_field, $attr, @bind) = @_;
    my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr) or return;
    _mysql_fix( $sth, $attr, @bind);
    $sth->execute(@bind) || return;
    return $sth->fetchall_hashref($key_field);
  }},

  'selectcol_arrayref' => { pkg => '_', code => sub {
    my ($dbh, $stmt, $attr, @bind) = @_;
    my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr) or return;
    _mysql_fix( $sth, $attr, @bind);
    $sth->execute(@bind) || return;
    my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
    my @values  = (undef) x @columns;
    my $idx = 0;
    for (@columns) {
      $sth->bind_col($_, \$values[$idx++]) || return;
    }
    my @col;
    if (my $max = $attr->{MaxRows}) {
      push @col, @values while @col<$max && $sth->fetch;
    } else {
      push @col, @values while $sth->fetch;
    }
    return \@col;
  }},

  'do' => { pkg => 'mysql', code => sub {
    my($dbh, $statement, $attr, @bind) = @_;
    my $sth = $dbh->prepare($statement, $attr) or return undef;
    _mysql_fix( $sth, $attr, @bind );
    $sth->execute(@bind) or return undef;
    my $rows = $sth->rows;
    ($rows == 0) ? "0E0" : $rows;
  }},

  '_do_selectrow' => { pkg => 'mysql', code => sub {
    my ($method, $dbh, $stmt, $attr, @bind) = @_;
    my $sth = ((ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr)) or return;
    _mysql_fix( $sth, $attr, @bind );
    $sth->execute(@bind) or return;
    my $row = $sth->$method() and $sth->finish;
    return $row;
  }},

  'selectrow_array' => { pkg => 'mysql', code => sub {
    my $row = DBD::mysql::db::_do_selectrow('fetchrow_arrayref', @_) or return;
    return $row->[0] unless wantarray;
    return @$row;
  }},

  'selectrow_arrayref' => { pkg => 'mysql', code => sub {
    return DBD::mysql::db::_do_selectrow('fetchrow_arrayref', @_);
  }},

  'selectrow_hashref' => { pkg => '_', code => sub {
    return DBD::mysql::db::_do_selectrow('fetchrow_hashref', @_);
  }},

};

sub mysql_auto_types {
  return if $DBD::mysql::VERSION < $DBD_mysql_VERSION;

  while (my ($meth, $params) = each %$FIXES) {
    no warnings;
    if ($params->{pkg} eq '_') {
      $DBD::_::db::{$meth} = $params->{code};
    } elsif ($params->{pkg} eq 'mysql') {
      $DBD::mysql::db::{$meth} = $params->{code};
    }
  }
}

'Grishace';

=head1 NAME

DBD::mysql::AutoTypes -- automatically assign parameters' sql type to support old DBD::mysql functionality

=head1 SYNOPSIS

 use DBI;
 use DBD::mysql::AutoTypes;

 my $dbh = DBI->connect('DBI:mysql:...', '...', '...') and mysql_auto_types();

=head1 DESCRIPTION

Since version 2.9002 DBD::mysql requires explicit sql type for query parameters. 
You should change the tonnes of $dbh->selectall_arrayref() to the ugly 
"prepare - bind - execute - fetch" pipeline. 

This module is provided to solve the problem. 

You have to change only two lines of code (use the module, and apply fixup after accuring database connection).

=head1 DEPENDENCIES

=over 3

=item *

B<DBI>

=item *

B<DBD::mysql>

=item *

B<Regexp::Common>

=back

=head1 BUGS

May be...

=head1 SEE ALSO

=over 4

=item * 

B<DBI> -- Perl DataBase Interface (L<http://search.cpan.org/~timb/DBI/>)

=item *

B<DBD::mysql> -- MySQL (L<http://www.mysql.com>) driver (L<http://search.cpan.org/~rudy/DBD-mysql/>) and  
B<DBD::mysql ChangeLog> -- look for the version 2.9002 changes (L<http://search.cpan.org/src/RUDY/DBD-mysql-2.9002/ChangeLog>), 
that break old behaviour

=item *

B<Regexp::Common> -- determine is data number or string

=back

=head1 AUTHOR

Greg "Grishace" Belenky <greg@webzavod.ru>

=head1 COPYRIGHT

Copyright (C) 2004 Greg "Grishace" Belenky
Portions of code cut'n'pasted from the DBI module

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
