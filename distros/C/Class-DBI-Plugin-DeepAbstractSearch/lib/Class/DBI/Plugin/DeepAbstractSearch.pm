package Class::DBI::Plugin::DeepAbstractSearch;

our $VERSION = '0.08';

use strict;
use warnings;
use base 'Class::DBI::Plugin';
use SQL::Abstract;

sub init {
	my $class = shift;
	$class->set_sql( deeply_and_broadly => qq{%s} );
}

sub deep_search_where : Plugged
{
    my $class = shift;
    
    my ($what, $from, $where, $bind) = $class->get_deep_where(@_);
    
	my $sql = <<"";
SELECT DISTINCT $what
FROM $from
WHERE $where

	return $class->sth_to_objects($class->sql_deeply_and_broadly($sql), $bind);
}

sub count_deep_search_where : Plugged
{
    my $class = shift;
    
    my ($what, $from, $where, $bind) = $class->get_deep_where(@_);
    
	my $sql = <<"";
SELECT COUNT(*)
FROM $from
WHERE $where

	return $class->sql_deeply_and_broadly($sql)->select_val(@$bind);
}

# my ($what, $from, $where, $bind) = CDBI->get_deep_where($where, $attr);
sub get_deep_where : Plugged
{
    my $class = shift;
    my $where = (ref $_[0]) ? $_[0]          : { @_ };
    my $attr  = (ref $_[0]) ? $_[1]          : undef;
    my $order = ($attr)     ? delete($attr->{order_by}) : undef;
	my $joins = {};
	my $order_fields = '';

	## Collect tables
	$where = _transform_where($class, $joins, $where);
	if ($order) {
		my %order_fields;
		$order = join(", ", @$order) if ref $order;
		$order = _transform_order($class, $joins, $order, \%order_fields);
		$order_fields = join(", ", map { /\./ ? $_ : () } keys %order_fields);
		$order_fields = ", $order_fields"
			if $order_fields;
	}

	## Translate to SQL
    my $sql = SQL::Abstract->new(%$attr);
    my($filter, @bind) = $sql->where($where, $order);
    $filter = "WHERE 1=1 $filter"
    	unless $filter =~ /^\s*WHERE/i;
	my $op = (keys(%$joins) > 1) ? 'AND' : '';
    $filter =~ s/^\s*WHERE/$op/i;

	## Build __TABLEs__
	my $tables = join(', ', map { "__TABLE($_->{class}=$_->{alias})__" } values %$joins) || "__TABLE__";

	## Build __JOINs__
	my $join = join(' AND ', map { $_->{fclass} ? "__JOIN($_->{fclass} $_->{alias})__" : () } values %$joins);

	## Build pseudo-query
	my $alias = $joins->{''}->{alias};
	my $essential = defined ($alias) ? "__ESSENTIAL($alias)__" : "__ESSENTIAL__";

	$sql = join("\0", "$essential$order_fields", $tables, "$join $filter");

	## Transform to real SQL
	$sql = $class->transform_sql($sql);

	return (split(/\0/, $sql), \@bind);
}


# Replace field names with fully qualified (table_alias.field) names
sub _transform_where {
    my ($class, $joins, $where, $hint) = @_;
    my $ref  = ref $where || '';
    my $val;

    $hint ||= '';

    if($ref eq 'ARRAY') {
    	my @where = @$where;
        if ($hint ne 'exps' || $where->[0] !~ /^[a-z]/i) {
            ## transforming [ operator, expr1, expr2 ]
            ## or array in  { operator => ['assigned', 'in-progress']}
            $val = [];
            while ($_ = shift @where) {
                push @$val, ((ref $_) ? _transform_where($class, $joins, $_) : $_);
            }
        } else {
            ## transforming [ field1 => expr1, field2 => expr2 ]
            ## or array in  { operator => [ field1 => expr1, field2 => expr2 ]}
            $val = [];
            while ($_ = shift @where) {
                push @$val, _transform_field($class, $joins, $_);
                push @$val, _transform_where($class, $joins, shift @where);
            }
        }
    } elsif ($ref eq 'HASH') {
        $val = {};
        foreach my $key (keys %$where) {
            if($key !~ /^[a-z]/i) {
                ## transforming   { operator => expr }
                ## or operator in   field => { operator => [ values ] }
                if($key =~ /^-?\s*(not[\s_]+)?(in|between)\s*$/i) {
                	## special case for IN and BETWEEN
	                $hint = 'val';
                } else {
	                $hint ||= 'exps';
	            }
                $val->{$key} = _transform_where($class, $joins, $where->{$key}, $hint);
            } else {
                ## transforming { field => expr }
                $val->{_transform_field($class, $joins, $key)} =
                    _transform_where($class, $joins, $where->{$key}, 'val');
            }
        }
    } else {
        ## literal or SQL
        $val = $where;
    }
    $val;
}

# Change "table.field1.field2, table.field3.field4 DESC" into
#     "t_table_field1.field2, t_table_field3.field4 DESC"
sub _transform_order {
	my ($class, $joins, $order, $order_fields) = @_;

	join(", ", map {
 		my @ord = split /\s+/, $_;
		$ord[0] = _transform_field($class, $joins, $ord[0]);
		$order_fields->{$ord[0]} = 1;
		join(" ", @ord);
	} (split /\s*,\s*/, $order));
}

# Change "table.field1.field2" into "t_table_field1.field2"
sub _transform_field {
    my ($class, $joins, $field) = @_;
	my @path = split /\./, $field;

	$field = pop @path;
	my $join = _get_join($class, $joins, @path);
	"$join->{alias}.$field";
}

# Return the join for (table, field1, field2, field3)
sub _get_join {
    my ($class, $joins, @path) = @_;

	my $join_key = lc join('.', @path);
	my $join = $joins->{$join_key};
	if(!$join) {
		if(my $field = pop @path) {
			## Joined table
			my $prev_join = _get_join($class, $joins, @path);
			my $fcl = $prev_join->{class};
			my $falias = $prev_join->{alias};

			my $col = $fcl->find_column($field)
				or $class->_croak("$fcl doesn't contain column '$field'");
			my $has_a = $fcl->meta_info('has_a')
				or $class->_croak("$fcl column '$col' doesn't have a 'has_a' relationship");
			$has_a = $has_a->{$col}
				or $class->_croak("$fcl column '$col' doesn't have a 'has_a' relationship");
			my $cl = $has_a->foreign_class;
			$join = { fclass => $falias, fkey => "$col", class => $cl, alias => "${falias}_$col" }
		} else {
			## Primary table
			$join = { class => $class, alias => "t_" . $class->table }
		}

		## Add join to list of joins
		$joins->{$join_key} = $join;
	}

	$join;
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::DeepAbstractSearch - deep_search_where() for Class::DBI

=head1 SYNOPSIS

	use base 'Class::DBI';
	use Class::DBI::Plugin::DeepAbstractSearch;

	my @cds = Music::CD->deep_search_where(
		{
			'artist.name' => $artist_name
		}
	);

=head1 DESCRIPTION

This plugin provides a L<SQL::Abstract> search method for L<Class::DBI>.
It is similar to L<Class::DBI::AbstractSearch>, but allows you to search
and sort by fields from joined tables.

Note: When searching and sorting by the fields of the current class only,
it is more efficient to use L<Class::DBI::AbstractSearch>.

=head1 METHODS

=head2 deep_search_where

	my @cds = Music::CD->deep_search_where(
		{
			'artist.name' => $artist_name
		}
	);

This method will be exported into the calling class, and allows for searching
of objects using L<SQL::Abstract> format based on fields from the calling
class as well as using fields in classes related through a (chain of) 'has_a'
relationships to the calling class.

When specifying a field in a related class, you separate it with a period
from the corresponding foreign key field in the primary class.

	package Music::Artist;
	use base 'Class::DBI';
	Music::Artist->table('artist');
	Music::Artist->columns(All => qw/artistid name/);
	Music::Artist->has_many(cds => 'Music::CD');

	package Music::CD;
	use base 'Class::DBI';
	Music::CD->table('cd');
	Music::CD->columns(All => qw/cdid artist title year/);
	Music::CD->has_many(tracks => 'Music::Track');
	Music::CD->has_a(artist => 'Music::Artist');

	package Music::Track;
	use base 'Class::DBI';
	Music::Track->table('track');
	Music::Track->columns(All => qw/trackid cd position title/); 

	## Tracks on all CDs with the title "Greatest Hits"
	@tracks = Music::Track->deep_search_where(
		{
			'cd.title' => "Greatest Hits"
		},
		{
			sort_by => 'cd.title'
		}
	);

	## Tracks on CDs by Willie Nelson, sorted by CD Title and Track Position
	@tracks = Music::Track->deep_search_where(
		{
			'cd.artist.name' => "Willie Nelson"
		},
		{
			sort_by => 'cd.title, position'
		}
	);

	## First 3 Tracks on CDs, whose title contains "Outlaw", by Willie Nelson
	@tracks = Music::Track->deep_search_where(
		{
			'cd.artist.name' => "Willie Nelson",
			'cd.title' => { -like => '%Outlaw%' },
			position => { '<=' => 3 }
		},
		{
			sort_by => 'cd.title, position'
		}
	);

=head2 count_deep_search_where

	my $num_cds = Music::CD->count_deep_search_where(
		{
			'artist.name' => $artist_name
		}
	);

This method will be exported into the calling class, and allows for counting
of objects using L<SQL::Abstract> format based on fields from the calling
class as well as using fields in classes related through a (chain of) 'has_a'
relationships to the calling class.

=head2 get_deep_where

    my ($what, $from, $where, $bind) = $class->get_deep_where($where, $attr);

This method will be exported into the calling class, and allows for retrieving
SQL fragments used for creating queries.  The parameters are the same as to
deep_search_where.

=head1 AUTHOR

Stepan Riha, C<sriha@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005, 2007, 2008 Stepan Riha. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<SQL::Abstract>, L<Class::DBI::AbstractSearch>

=cut