# $Id$

#
# Copyright Chris Mungall <cmungall@fruitfly.org>
#
# You may use, copy, modify, and redistribute this module under the same terms
# as Perl itself.
#

=head1 NAME

Bio::DB::Query::SqlQuery - Object representing an SQL Query

=head1 SYNOPSIS

  $q = Bio::DB::Query::SqlQuery->new(-datacollections=>\@tables,
                                   -select=>\@selectcols);
  $q->flags("distinct", 1);
  $q->where("or", "colA=x", "colB=y", "colC=y");


=head1 DESCRIPTION

This class inherits from Bio::DB::Query::AbstractQuery

=head1 CONTACT

Chris Mungall, cmungall@fruitfly.org

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Query::SqlQuery;

use vars qw(@ISA);
use strict;
use Bio::DB::Query::AbstractQuery;

@ISA = qw(Bio::DB::Query::AbstractQuery);

=head2 new

  Usage:  $sqlq = $self->new("table1", "col=val", "*");
      OR  $sqlq = $self->new(-select=>["col1", "col2"],
			     -table=>["table1", "table2"], 
			     -where=>["col3='val1'", "col4='val4'"]);
      OR  $sqlq = $self->new("col1, col2", "col1.fk=col2.pk", "*", "col2,col1");
      OR  $sqlq = $self->new("col1", {col1=>$val1, col2=>$val2});

  Args: tables, where, select, order, group, sql

all arguments except table are optional (select defaults to *)

the arguments can either be array references or a comma delimited string

the where argument can also be passed as a hash reference (in which
case the values are autoquoted)

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my ($sql) = $self->_rearrange([qw(SQL)], @_);

    $self->sqlstatement($sql) if $sql;

    return $self;
}

=head2 querytype

  Usage:  $query->querytype($val);      # setting
      OR   return $query->querytype();  # getting

one of : select, select distinct, insert, update, delete

ignored for now...

=cut

sub querytype {
    my $self = shift;
    $self->{_querytype} = shift if @_;
    return $self->{_querytype};
}


=head2 sql

  Usage:  $query->sql($val);      # setting
      OR   return $query->sql();  # getting

=cut

sub sql {
    my $self = shift;
    $self->{_sql} = shift if @_;
    return $self->{_sql};
}


1;
