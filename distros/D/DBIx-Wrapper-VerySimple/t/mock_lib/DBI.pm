# $Header: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI.pm,v 1.1 2006/08/20 19:52:52 matisse Exp $
# $Revision: 1.1 $
# $Author: matisse $
# $Source: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/mock_lib/DBI.pm,v $
# $Date: 2006/08/20 19:52:52 $
###############################################################################

#  Mock class - for testing only

package DBI;
use strict;
use warnings;

#warn 'Loading mock library ' . __FILE__;
my $MOCK_DBH_CLASS = 'DBI::Mock::dbh';

my %ARGS = ();

sub connect {
    my ( $class, @args ) = @_;
    my $fake_dbh = {};
    bless $fake_dbh, $MOCK_DBH_CLASS;
    $ARGS{$fake_dbh} = \@args;
    return $fake_dbh;
}
1;
