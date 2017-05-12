package DBD::Salesforce::st;

# ----------------------------------------------------------------------
# $Id: st.pm,v 1.1.1.1 2006/02/14 16:54:03 shimizu Exp $
# ----------------------------------------------------------------------
# DBD::Salesforce::st - Statement handle
# ----------------------------------------------------------------------

use strict;
use base qw(DBD::_::st);
use vars qw($VERSION $imp_data_size);

use DBI;
use Data::Dumper;

$VERSION = "0.01";
$imp_data_size = 0;

# ----------------------------------------------------------------------
# execute()
#
# I have no intention of supporting bind_params, BTW.
# ----------------------------------------------------------------------
sub execute {
    my $sth = shift;
    my (@data, @columns);
    my ($command, $salesforce, $search, $search_opts, $parser, $statement, @results, $result);

    # Get the salesforce instance and %attr
    $salesforce  = $sth->{'Database'}->FETCH('driver_salesforce');
    $search_opts = $sth->{'Database'}->FETCH('driver_salesforce_opts');
    $parser    = $sth->{'Parser'};
    $statement = $sth->{'Statement'};

    if ($parser->{'command'} eq "SELECT") {
    
        # Create valid SQL for Salesforce::query
        my $sql = sprintf("SELECT %s FROM %s", 
            join(",", @{$parser->{'org_col_names'}}), $parser->{'table_names'}->[0]);
        my $limit = $parser->{'limit_clause'}->{'limit'} || '10';

        # The Salesforce::query instance
        $search = $salesforce->query(query => $sql, limit => $limit);
        if ($search->valueof('//Body/Fault')) {
            my $errstr = $search->valueof('//Body/Fault/detail/fault')->{'exceptionCode'} . "\n" . 
                         $search->valueof('//Body/Fault/detail/fault')->{'exceptionMessage'};
            $sth->{'Database'}->set_err(1, $errstr);
        }

        # The names of the columns in which we are interested
        @columns = @{ $sth->{'Columns'} };

        # This is where fetchrow_hashref etc get their names from
        $sth->{'NAME'} = [ map { $_->{'ALIAS'} } @columns ];

        # This executes the search
        @results = $search->valueof('//queryResponse/result/records');

        for my $result (@results) {
            my (@this, $column);
            for $column (@columns) {
                # translate SQL field name to SQL display name
                # ex) ID -> Id, FIRSTNAME -> FirstName
                push @this, $result->{$parser->{'col_obj'}->{$column->{'FIELD'}}->{'display_name'}};
            }
            push @data, \@this;
        }
        
    } elsif ($parser->{'command'} eq "UPDATE") {
    
        my %in;
        $in{'Id'} = $parser->{'where_cols'}->{'Id'}->[0];
        $in{'type'} = $parser->{'table_names'}->[0];
        for (my $i = 0; $i < scalar(@{$parser->{'column_names'}}); $i++) {
            $in{$parser->{'column_names'}->[$i]} = $parser->{'values'}->[$i]->{'value'};
        }

        # The Salesforce::update instance
        $search = $salesforce->update(%in);
        if ($search->valueof('//Body/updateResponse/result/errors')) {
            my $errstr = $search->valueof('//Body/updateResponse/result/errors')->{'statusCode'} . "\n" .
                         $search->valueof('//Body/updateResponse/result/errors')->{'message'};
            $sth->{'Database'}->set_err(1, $errstr);
        }

    } elsif ($parser->{'command'} eq "INSERT") {
    
        my %in;
        $in{'type'} = $parser->{'table_names'}->[0];
        for (my $i = 0; $i < scalar(@{$parser->{'column_names'}}); $i++) {
            $in{$parser->{'column_names'}->[$i]} = $parser->{'values'}->[$i]->{'value'};
        }

        # The Salesforce::create instance
        $search = $salesforce->create(%in);
        if ($search->valueof('//Body/Fault')) {
            my $errstr = $search->valueof('//Body/Fault/detail/fault')->{'exceptionCode'} . "\n" . 
                         $search->valueof('//Body/Fault/detail/fault')->{'exceptionMessage'};
            $sth->{'Database'}->set_err(1, $errstr);
        }

    } elsif ($parser->{'command'} eq "DELETE") {
    
        my %in;
        $in{'Id'} = $parser->{'where_cols'}->{'Id'}->[0];
        
        # The Salesforce::delete instance
        $search = $salesforce->delete(%in);
        print Dumper $search->valueof('//Body/deleteResponse/result');
        if ($search->valueof('//Body/deleteResponse/result/errors')) {
            my $errstr = $search->valueof('//Body/deleteResponse/result/errors')->{'statusCode'} . "\n" .
                         $search->valueof('//Body/deleteResponse/result/errors')->{'message'};
            $sth->{'Database'}->set_err(1, $errstr);
        }
    }

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
#sub totalrows {
#    my $sth = shift;
#    return $sth->estimateTotalResultsNumber();
#}

# Returns available tables
#sub table_info { return "Salesforce" }

# Implement metadata functions
#{   no strict qw(refs);
#    for my $sub (qw(documentFiltering searchComments searchQuery
#                    estimateTotalResultsNumber estimateIsExact
#                    startIndex endIndex searchTips searchTime)) {
#        *{$sub} = sub {
#            my $sth = shift;
#            my $search = $sth->{'SalesforceSearch'};
#            return $search->$sub() if defined $search;
#           return;
#        };
#    }
#}

1;

sub DESTROY { 1 }

__END__
