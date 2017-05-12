#!/usr/bin/perl

package DBI::ResultPager;

use strict;
use warnings;
use CGI qw/:standard/;
use DBI;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA);
	$VERSION = '0.9.2';
	@ISA = qw(Exporter);
}


sub new {
	my $self = {};
	$self->{DBH} = '';
	$self->{QUERY} = '';
	$self->{PERPAGE} = 30;
	$self->{DEFAULTORDER} = '';
	$self->{ALIGN} = '';

	my %fmt = ();
	my %hidden = ();
	my @cc;
	
	$self->{FORMATTERS} = \%fmt;
	$self->{CUSTOMCOLUMNS} = \@cc;
	$self->{HIDDENCOLUMNS} = \%hidden;
	
	bless($self);
	return $self;	
}

sub display {
	my ($self, @params) = (@_);
	my $rv = getOutput($self, @params);
	print $rv;
}

sub getOutput {
	my ($self, @params) = (@_);

	my $output = '';
	
	my @columns;
	my $page = 1;
	
	if(defined(url_param('page'))) {
		$page = url_param('page');
	}

	my $hidden = $self->{HIDDENCOLUMNS};
	my $query = $self->{QUERY};
	my $perPage = $self->{PERPAGE};
	my $offset = (($page - 1) * $perPage);
	my $dbh = $self->{DBH};
	my $order = $self->{DEFAULTORDER};
	
	my $ccref = $self->{CUSTOMCOLUMNS};
	my @customColumns = @$ccref;
	
	if($order ne '') {
		$query = $query . ' order by ' . $order;
	}

	$query = $query . ' limit ' . ($perPage + 1);

	if($page ne 1) {
		$query = $query . " offset $offset";
	}

	my $sth = $dbh->prepare($query);
	$sth->execute(@params) or die "Error in $query: $!\n";

	$output .= '<center><table width="90%" border="0">';
	
	my $nref = $sth->{NAME};
	my @names = @$nref;

	# Print the header.
	$output .= '<tr>';
	foreach(@names) {
		if(!defined($hidden->{$_})) {
			$output .= '<th>' . $_ . '</th>';
		}
		
		push(@columns, $_);		
	}

	foreach(@customColumns) {
		$output .= '<th>' . $_->{'columnName'} . '</th>';
	}

	# Add headers for any custom columns
	
	$output .= "</tr>\n";
	
	my $formatters = $self->{FORMATTERS};
	my $count = 0;
	while(my @row = $sth->fetchrow_array()) {
		$count++;
		
		if($count > $perPage) { next; }

		my $color = "";
		if( ($count %2) eq 1) {
			$color = ' bgcolor="#EEEEEE"';
		}

		$output .= "<tr$color>";
		my $colcount = 0;
		my $al = '';
		my $align = $self->{ALIGN};
		if($align ne '') {
			$al = ' valign="' . $align . '"';
		}

		foreach(@row) {
			$colcount++;
			my $colname = $columns[$colcount - 1];
			
			if(defined($hidden->{$colname})) { next; }
			
			$output .= '<td' . $al . '>';

			# Check if this column has a custom formatter
			if(defined($formatters->{$colname})) {
				my $subref = $formatters->{$colname};
				$output .= &$subref($_, \@row);
			} else {	
				$output .= $_;
			}

			$output .= '</td>';
		}
	
		foreach(@customColumns) {
			$output .= '<td' . $al . '>';
			my $cref = $_->{'codeRef'};
			$output .= &$cref(@row) .  '</td>';
		}

		$output .= "</tr>\n";
	}

	$output .= '</table>';
	
	my $prev = 0;
	if($offset ne 0) {
		my $u = manglePage($page - 1);
		$output .= '<a href="' . $u . '">Previous Page</a>';
		$prev = 1;
	}

	if($count > $perPage) {
	
		if($prev ne 0) {
			$output .= ' | ';
		}
		
		my $u = manglePage($page + 1);
		$output .= '<a href="'. $u . '">Next Page</a>';
	}
	
	$output .= '</center>';
}

sub alignRows {
	my ($self, $align) = (@_);
	$self->{ALIGN} = $align;
}

# Returns the current URL with the given page number.
# FIXME: URL params only
sub manglePage {
	my ($page) = (@_);

	my $u = url(-relative=>1, -query=>1);
	if($u =~ /[\?&;]page=/) {
		$u =~ s/[\?&;]page=[0-9]*//;
	}

	if($u =~ /\?/) {
		$u = $u . '&page=' . $page;
	} else {
		$u = $u . '?page=' . $page;
	}

	return $u;
}

sub hideColumn {
	my ($self, $columnName) = (@_);
	my $ar = $self->{HIDDENCOLUMNS};
	$ar->{$columnName} = 1;
}

sub addCustomColumn {
	my ($self, $columnName, $codeRef, $identityColumn) = (@_);

	my %cc = ();
	
	$cc{'columnName'} = $columnName;
	$cc{'codeRef'} = $codeRef;
	
	my $ar = $self->{CUSTOMCOLUMNS};
	push(@$ar, \%cc); # Push the hashref onto the arrayref.
}

sub addColumnFormatter {
	my ($self, $column, $formatref) = (@_);

	my $formatters = $self->{FORMATTERS};
	$formatters->{$column} = $formatref;
}

sub defaultOrder {
	my $self = shift;
	if(@_) { $self->{DEFAULTORDER} = shift; }
	return $self->{DEFAULTORDER};
}

sub dbh {
	my $self = shift;
	if(@_) { $self->{DBH} = shift; }
	return $self->{DBH};
}

sub perPage {
	my $self = shift;
	if(@_) { $self->{PERPAGE} = shift; }
	return $self->{PERPAGE};
}

sub query {
	my $self = shift;
	if(@_) { $self->{QUERY} = shift; }
	return $self->{QUERY};
}

1;
__END__

=head1 NAME

DBI::ResultPager - creates an HTML-based pager for DBI result sets.

=head1 SYNOPSIS

 # Create a pageable result set
 use DBI::ResultPager;
 
 my $rp = DBI::ResultPager->new;
 $rp->dbh($dbh);
 $rp->query('select books.title, authors.name
             from books
	     inner join (books.author_id = authors.id)');
 $rp->display();

 # The same result set, but sorted with nicer column headings
 my $rp = DBI::ResultPager->new;
 $rp->dbh($dbh);
 $rp->query('select books.title as "Title", 
             authors.name as "Author"
             from books
	     inner join (books.author_id = authors.id)');
 $rp->defaultOrder('Title');
 $rp->display();

 # Adding a custom formatter to build links
 my $rp = DBI::ResultPager->new;
 $rp->dbh($dbh);
 $rp->query('select books.title as "Title", 
             books.isbn as "ISBN",
             authors.name as "Author"
             from books
	     inner join (books.author_id = authors.id)');
 $rp->addColumnFormatter('ISBN', \&linkISBN);
 $rp->display();

 sub linkISBN {
     my($isbn) = shift;
     return '<a href="http://isbndb.com/search-all.html?kw=' .
         $isbn . '">ISBNdb</a>';
 }

 # Adding a custom column and hiding an identity column
 my $rp = DBI::ResultPager->new;
 $rp->dbh($dbh);
 $rp->query('select books.id,
             books.title as "Title", 
             from books');
 $rp->hideColumn('books.id');
 $rp->addCustomColumn('Functions', \&bookFunctions);
 $rp->display();
 
 sub bookFunctions {
   my (@row) = (@_);
   return '<a href="delete.cgi?id=' . $row[0] . '">delete</a>';
 }

 # Set the number of results per page:
 $rp->perPage(20);

 # Vertically align the outputted columns:
 $rp->alignRows('top');

 # Get the outputted table as a scalar
 my $output = $rp->getOutput();

=head1 DESCRIPTION

This class is a quick and easy method of paging result sets returned 
from the DBI database interface.  It takes a standard SQL query along 
with a database handle and performs the query, inserting the resultant 
rows into a pageable HTML table.  Various options such as sort order can 
be adjusted, and columns can have formatters attached.  Columns can also 
be hidden, and custom columns can be added to the output.

=head1 METHODS

=head2 dbh

This sets the DBI database handle for query execution.

=head2 addColumnFormatter (name, formatter)

Adds a custom formatting routine to a column.  When a row of that column is 
rendered, the customer format routine is called with two parameters - the 
value of the data in that cell, and a list reference containing the current
row of the resultset.  The list reference is useful for referring to other
elements in the current row.

=head1 SOURCE AVAILABILITY

The source for this project should always be available from CPAN.  Other than
that it may be found at https://neuro-tech.net/.

=head1 AUTHOR

	Original code:		Luke Reeves <luke@neuro-tech.net>
				https://neuro-tech.net/

=head1 COPYRIGHT

Copyright (c) 2005 Luke Reeves <luke@neuro-tech.net>

DBI::ResultPager is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 CREDITS

 Luke Reeves <luke@neuro-tech.net>

=head1 SEE ALSO

perl(1), DBI(3).

=cut

