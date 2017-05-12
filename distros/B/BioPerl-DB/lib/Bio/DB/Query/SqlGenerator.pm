# $Id$

#
# Copyright Chris Mungall <cmungall@fruitfly.org>
#
# You may use, copy, modify, and redistribute this module under the same terms
# as Perl itself.
#

=head1 NAME

Bio::DB::Query::SqlGenerator - Object representing an SQL Query

=head1 SYNOPSIS

    use Bio::DB::Query::BioQuery;
    use Bio::DB::Query::SqlGenerator;

    # get a Bio::DB::Query::AbstractQuery or derived query somehow
    my $query = Bio::DB::Query::BioQuery->new(-tables => ["table1, table2"]);
    $query->where(["and",
                   ["or", "col4 = ?", "col5 = 'somevalue'"],
	           ["col2 = col4", "col6 not like 'abcd*'"]]);

    # use the generator to turn a query object into SQL
    my $sqlgen = Bio::DB::Query::SqlGenerator->new(-query => $query);
    my $sql = $sqlgen->generate_sql();
    print "SQL: $SQL\n";

    # then bind as necessary, and execute ...

=head1 DESCRIPTION

This represents the strategy pattern for generating a SQL statement given
a Query object.

Eventually there should be interfaces for this pattern as well as for the
Query.

=head1 AUTHOR Chris Mungall, Hilmar Lapp

Chris Mungall, cmungall@fruitfly.org
Hilmar Lapp, hlapp at gmx.net

This is essentially code ripped out of SqlQuery.pm and AbstractQuery.pm 
(both by Chris Mungall), put into its own module as a strategy pattern.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Query::SqlGenerator;

use vars qw(@ISA);
use strict;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);

=head2 new


=cut

sub new {
    my ($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    my ($query) = $self->_rearrange([qw(QUERY)], @args);

    $self->query($query) if $query;

    return $self;
}

=head2 query

 Title   : query
 Usage   : $obj->query($newval)
 Function: Get/set query object (a Bio::DB::Query::AbstractQuery or derived
           instance).
 Example : 
 Returns : value of query (a Bio::DB::Query::AbstractQuery or derived)
 Args    : new value (a Bio::DB::Query::AbstractQuery or derived, optional)


=cut

sub query{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'query'} = $value;
    }
    return $self->{'query'};
}

=head2 generate_sql

  Usage:  $sqlstmt = $sqlgen->generate_sql; $dbh->do($sqlstmt);
          $sqlstmt = $sqlgen->generate_sql($query); $dbh->do($sqlstmt);

Flattens query object into a SQL statement.

=cut

sub generate_sql {
    my $self = shift;
    my $query = shift || $self->query();

    my @sel = @{$query->selectelts || []};
    my $str = 
	sprintf(
		"SELECT %s%s FROM %s",
		$query->flag("distinct") ? "DISTINCT " : "",
		@sel ? join(", ", @sel) : "*",
		join(", ", @{$query->datacollections}));
    my $qc = $query->where;
    my $wh = $self->flatten_qc($qc);
    $str.= " WHERE $wh" if $wh;
    
    my @ord = @{$query->orderelts || []};
    $str.= sprintf(" ORDER BY %s", join(", ", @ord)) if @ord;
    
    my @gp = @{$query->groupelts || []};
    $str.= sprintf(" GROUP BY %s", join(", ", @gp)) if @gp;
    
    return $str;
}

sub flatten_qc {
    my $self = shift;
    my $qc = shift;
    my $flat;
    if ($qc->is_composite) {
	my @subqcs = ();
	foreach my $subqc (@{$qc->value}) {
	    my $cond = $self->flatten_qc($subqc);
	    next unless $cond;
	    push(@subqcs, $subqc->is_composite ? "(".$cond.")" : $cond);
	}
	$flat = join(" ".uc($qc->operand)." ", @subqcs);
    }
    else {
	my $val = $qc->value();
	my $op = uc($qc->operand) || "=";
	if(($op =~ /LIKE/) && ($val =~ /.(\*|\?)./)) {
	    # we need to replace wildcard chars
	    $val =~ s/\*/%/g;
	    $val =~ s/\?/_/g;
	}
	$flat = join(" ", $qc->name, $op, $val);
	$flat = "(NOT $flat)" if $qc->neg;
    }
    return $flat;
}

1;
