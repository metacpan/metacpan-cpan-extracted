# $Header: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI/Mock/dbh.pm,v 1.1 2006/08/20 19:52:52 matisse Exp $
# $Revision: 1.1 $
# $Author: matisse $
# $Source: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI/Mock/dbh.pm,v $
# $Date: 2006/08/20 19:52:52 $
###############################################################################

#  Mock class - for testing only

package DBI::Mock::dbh;
use strict;
use warnings;

our $VERSION = 0.01;

sub errstr { }

sub prepare_cached {
    my ( $self, $sql ) = @_;
    return if ( $sql eq 'TEST_FAILURE' );
    my $sth = { sql => $sql, };
    bless $sth, 'DBI::Mock::sth';
    return $sth;
}

sub disconnect { }

1;
