package DBIx::SimpleGoBetween;

use strict;
use warnings;
use vars qw($VERSION);
use Carp qw(croak);
$VERSION = '1.003';


=head1 NAME

DBIx::SimpleGoBetween - DBI Wrapper interface

=head1 SYNOPSIS

  use DBIx::SimpleGoBetween;
  use DBI;

  my $dbh=DBI->connect(blah blah blah);

  my $db=DBIx::SimpleGoBetween->new(\$dbh);


  # returns the first column of the first row of your query
  $count=$db->get_scalar('select count(*) from table_a');

  # fetches the entire result set as a single list
  ($max,$sum)=$db->get_list(
    'select max(column_a) ,sum(column_a) from table_a'
  );

  # returns a list reference of list references
  # each list reference represents a row from the result set
  $array_ref=$db->get_list_of_lists(
    'select * from table_a'
  );

  # returns a list reference of hash references
  # each hash reference represents a row from the result set
  $array_ref=$db->get_list_of_hashes(
    'select * from table_a'
  );

  # does a prepare then executes the query with the list reference 
  # provide by the 2nd argument
  $db->sql_do('delete from table_a where column_a=?',[$value]);

  # Callback
  # code_ref: is called on a per row basis, arguments based on 'type'
  # type: array,hash,array_ref,hash_ref
  $sth=$db->callback(
    'sql',[execute list],[prepare_args],'type',\&code_ref
  );


=head1 DESCRIPTION

DBIx::SimpleGoBetween acts as a go between for DBI and any other development interfaces you use.  This package has no iterators, no error checking.  It simply returns the result sets in one of many data structure formants.

Odds are your result does not need to be processed, just placed in a structure in the order it was retrieved, if so then this is the module you are looking for.

Example using HTML::Template

  use DBI;
  use DBIx::SimpleGoBetween;
  use HTML::Template;

  my $dbh=DBH->connect();
  my $db=DBIx::SimpleGoBetween->new(\$dbh);
  my $tmpl=HTML::Template->new(filename=>'file.tmpl');

  $tmpl->param(
    total_rows=>$db->get_scalar('select count(*) from table_a')
    ,tmpl_loop=>$db->get_list_of_hashes('select * from table_a')
  );

=head2 EXPORT

None


=cut

use constant key_dbh=>0;

=head2 OO Methods

This section documents the OO functions

=over 4

=item * my $db=DBIx::SimpleGoBetween->new(\$db);

This function creates a new instance of DBIx::SimpleGoBetween.

=back

=cut

sub new ($) {
  my ($class,$dbh_ref)=@_;
  bless [$dbh_ref],$class;
}

=head2 OO interface arguments

All OO interfaces in the instance accept the following arguments:

  -'sql statement'
   Required argument
    Must be an "sql statment" or a "prepared statement handle"

  -[execute list]
   Optional argument ( manditory if [optional prepare args] is used )
     Must be an array reference containing the place holder arguments
     for the $sth->execute command

  -[optional prepare args]
   Optional argument ( manditory if you are using $db->callback )
     Must be an array reference of the arguments passed to
     $dbh->prepare('sql statement',@{[optional prepare args]})

=over 4

=item * my $dbh=$db->dbh;

Returns the database handle used to create this instance.

=cut

sub dbh () { ${ $_[0]->[key_dbh] } }

=item * my $sth=$db->prep('sql statement',[prepare_args]);

Returns a prepared statement handle.  If you pass a prepared statement handle, it returns that statement handle.

In reality this is just a wrapper for:

	my $sth=$db->dbh->prepare('sql statement',@$prepare_args);

=cut

sub prep {
  my ($s,$sql,$args)=@_;
  return $sql if ref($sql);
  $args=[] unless $args;
  $s->dbh->prepare($sql,@{$args});
}

=item * $db->callback('sql statement',[execute list],[optional prepare args],type,code_ref);

Although DBIx::Simple offers no iterator interfaces, it does offer a callback interface, that allows you consolidate the following operations: prepare, execute, while.

Example:

 # type eq 'array'
 $db->callback(
 	'sql statement'
	,[execute list]
	,[prepare arguments]
	,'array'
	,sub {
  		 print join(',',@_),"\n";
 	}
 );

 # type eq 'array_ref'
 $db->callback(
 	'sql statement'
	,[execute list]
	,[prepare arguments]
	,'array_ref'
	,sub {
		my ($ref)=@_;
  		print join(',',@$ref),"\n";
 	}
 );

 # type eq 'hash'
 $db->callback(
 	'sql statement'
	,[execute list]
	,[prepare arguments]
	,'hash'
	,sub {
		my %hash=@_;
		while(my ($key,$value)=each %hash) {
		  print $key,',',$value,"\n";
		}
 	}
 );

 # type eq 'hash_ref'
 $db->callback(
 	'sql statement'
	,[execute list]
	,[prepare arguments]
	,'hash'
	,sub {
		my ($hash)=@_;
		while(my ($key,$value)=each %$hash) {
		  print $key,',',$value,"\n";
		}
 	}
 );

=cut

sub callback {
  my ($s,$sql,$placeholder,$sql_args,$type,$code)=@_;
  my $sth=$s->prep($sql,$sql_args);
  $type=lc($type);
  $sth->execute(@$placeholder);
  croak 'not a code ref' unless ref($code) eq 'CODE';
  if($type eq 'hash') {
   while(my $row=$sth->fetchrow_hashref) {
    $code->(%$row)
   }
  } elsif($type eq 'hash_ref') {
   while(my $row=$sth->fetchrow_hashref) {
    $code->($row)
   }
  } elsif($type eq 'array') {
   while(my $row=$sth->fetchrow_arrayref) {
    $code->(@$row)
   }
  } elsif($type eq 'array_ref') {
   while(my $row=$sth->fetchrow_arrayref) {
    $code->($row)
   }
  } else {
     croak 'unknown type'
  }
}

=item * my @list=$db->get_list('sql statement',[execute list],[optional prepare args]);

Returns the entire result set as a single list.  

The [execute list] and [optional prepare args] are optional arguments.

Example:

 my ($count,$sum)=$db->get_list(
  'select max(col_a),sum(col_a) from table'
 );

=cut

sub get_list {
  my ($s,$sql,$ph,$arg)=@_;
  my @list;
  $s->callback($sql,$ph,$arg,'array',sub { push @list,@_ });
  @list;
}

=item * my $value=$db->get_scalar('sql statement',[execute list],[optional prepare args]);

Returns the first column of the first row as a single scalar value. 

This function is intended for those situations where your query contains only one value, or you really only care about the very first value in your result set.

The [execute list] and [optional prepare args] are optional arguments.

=cut

sub get_scalar {
  my ($first)=get_list(@_);
  $first
}

=item * my $ref=$db->get_list_of_lists('sql statement',[execute list],[optional prepare args]);

Returns your result set as a list of list references.

The [execute list] and [optional prepare args] are optional arguments.

Example:

 if your query contained 2 rows and 2 columns the data structure
  would look something like this:

 $ref->[0]->[0] eq 'value of the first column of the first row'
 $ref->[0]->[1] eq 'value of the second column of the first row'

 $ref->[1]->[0] eq 'value of the first column of the second row'
 $ref->[1]->[1] eq 'value of the second column of the second row'

=cut

sub get_list_of_lists {
  my ($s,$sql,$ph,$arg)=@_;
  my $list=[];
  $s->callback($sql,$ph,$arg,'array_ref',sub { push @$list, [@{$_[0]}] });
  $list
}

=item * my $ref=$db->get_list_of_hashes('sql statement',[execute list],[optional prepare args]);

Returns your result as a list of hash references.

The [execute list] and [optional prepare args] are optional arguments.

Example:

 if your query contained 2 rows and 2 columns named:( col_a,col_b)  
  the data structure would look something like this:

 $ref->[0]->{col_a} eq 'value of the first row col_a'
 $ref->[0]->{col_b} eq 'value of the first row col_b'

 $ref->[0]->{col_a} eq 'value of the second row col_a'
 $ref->[0]->{col_b} eq 'value of the second row col_b'

=cut

sub get_list_of_hashes {
 my ($s,$sql,$ph,$arg)=@_;
 my $list=[];
 $s->callback($sql,$ph,$arg,'hash_ref',sub { push @$list, {%{$_[0]}} });
 $list
}

=item * $db->sql_do('sql statement',[execute list],[optional prepare args]);

This is really a wrapper for the following:

 my $sth=$dbh->prepare('sql statement',( list of sql args if any ));
 $sth->execute((execute list);

The [execute list] and [optional prepare args] are optional arguments.

=cut

sub sql_do {
  my ($s,$sql,$ph,$arg)=@_;
  my $sth=$s->prep($sql,$arg);
  $sth->execute(@$ph);
}

=pod

=back

=head1 SEE ALSO

DBI HTML::Template DBIx::BulkLoader::Mysql DBIx::Simple

=head1 Source Forge Porject

If you feel this software is useful please donate.

L<DBIx Simple Go Between|https://sourceforge.net/projects/dbix-simplegobe/>

=head1 AUTHOR

Michael Shipper

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Michael Shipper

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
