# $Header: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI/Mock/sth.pm,v 1.1 2006/08/20 19:52:52 matisse Exp $
# $Revision: 1.1 $
# $Author: matisse $
# $Source: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI/Mock/sth.pm,v $
# $Date: 2006/08/20 19:52:52 $
###############################################################################

#  Mock class - for testing only



package DBI::Mock::sth;

use strict;
use warnings;

our $VERSION = 0.01;

sub execute {
    my ( $sth, @bind_values ) = @_;
    return if ( $bind_values[0] eq 'TEST_FAILURE' );
    $sth->{bind_values} = \@bind_values;
    $sth->{remaining_rows_in_result} = scalar @bind_values;
    return $sth;
}

sub fetchrow_hashref {
    my ($sth) = @_;
    if ( !defined $sth->{remaining_rows_in_result}
        || $sth->{remaining_rows_in_result} < 1 )
    {
        return;
    }
    $sth->{remaining_rows_in_result}--;
    return { sth => $sth, };
}

sub finish { }
1;
