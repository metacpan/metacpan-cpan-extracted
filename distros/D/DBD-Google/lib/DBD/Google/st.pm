package DBD::Google::st;

# ----------------------------------------------------------------------
# DBD::Google::st - Statement handle
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::st);
use vars qw($VERSION $imp_data_size);

use DBI;

$VERSION = "2.00";
$imp_data_size = 0;

# ----------------------------------------------------------------------
# execute()
#
# I have no intention of supporting bind_params, BTW.
# ----------------------------------------------------------------------
sub execute {
    my $sth = shift;
    my (@data, @columns);
    my ($google, $search, $results, $result);

    # The Net::Google::Search instance
    $search = $sth->{'GoogleSearch'};

    # The names of the columns in which we are interested
    @columns = @{ $sth->{'Columns'} };

    # This is where fetchrow_hashref etc get their names from
    $sth->{'NAME'} = [ map { $_->{'ALIAS'} } @columns ];

    # This executes the search
    $results = $search->results;
    for $result (@$results) {
        my (@this, $column);

        for $column (@columns) {
            my ($name, $method, $value, $function);
            $name = lc $column->{'FIELD'};

            # These are in the same order as described
            # in Net::Google::Response
            if ($name eq 'title') {
                $method = "title";
            } elsif ($name eq 'url') {
                $method = "URL";
            } elsif ($name eq 'snippet') {
                $method = "snippet";
            } elsif ($name eq 'cachedsize') {
                $method = 'cachedSize';
            } elsif ($name eq 'directorytitle') {
                $method = 'directoryTitle';
            } elsif ($name eq 'summary') {
                $method = 'summary';
            } elsif ($name eq 'hostname') {
                $method = 'hostName';
            } elsif ($name eq 'directorycategory') {
                $method = 'directoryCategory';
            }

            $value = defined $method ? $result->$method() : "";

            $function = $column->{'FUNCTION'};
            eval { $value = &$function($search, $value); }
                if defined $function;

            push @this, ($@ or $value or "");
        }

        push @data, \@this;
    }
    # Need to do stuff with total rows, search time, and such,
    # all from $search

    $sth->{'driver_data'} = \@data;
    $sth->{'driver_rows'} =  @data;
    $sth->STORE('NUM_OF_FIELDS', scalar @columns);

    return scalar @data || 'E0E';
}

sub fetchrow_arrayref {
    my $sth = shift;
    my ($data, $row);

    $data = $sth->FETCH('driver_data');

    $row = shift @$data
        or return;

    return $sth->_set_fbav($row);
}
*fetch = *fetch = \&fetchrow_arrayref;

sub rows {
    my $sth = shift;
    return $sth->FETCH('driver_rows');
}

# Alas! This currently doesn't work.
sub totalrows {
    my $sth = shift;
    return $sth->estimateTotalResultsNumber();
}

# Returns available tables
sub table_info { return "Google" }

# Implement metadata functions
{   no strict qw(refs);
    for my $sub (qw(documentFiltering searchComments searchQuery
                    estimateTotalResultsNumber estimateIsExact
                    startIndex endIndex searchTips searchTime)) {
        *{$sub} = sub {
            my $sth = shift;
            my $search = $sth->{'GoogleSearch'};
            return $search->$sub() if defined $search;
            return;
        };
    }
}

1;

sub DESTROY { 1 }

__END__
