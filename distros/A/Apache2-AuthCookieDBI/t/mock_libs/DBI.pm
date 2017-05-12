# $Header: /Users/matisse/Desktop/CVS2GIT/matisse.net.cvs/Apache-AuthCookieDBI/t/mock_libs/DBI.pm,v 1.4 2010/11/27 19:15:37 matisse Exp $
# $Revision: 1.4 $
# $Author: matisse $
# $Source: /Users/matisse/Desktop/CVS2GIT/matisse.net.cvs/Apache-AuthCookieDBI/t/mock_libs/DBI.pm,v $
# $Date: 2010/11/27 19:15:37 $
###############################################################################

#  Mock class - for testing only

package DBI;
use strict;
use warnings;

#warn 'Loading mock library ' . __FILE__;
my $MOCK_DBH_CLASS = 'DBI::Mock::dbh';

our $CONNECT_CACHED_FORCE_FAIL;

sub connect_cached {
    my ( $class, @args ) = @_;

    if ($CONNECT_CACHED_FORCE_FAIL) {
        return;
    }

    my $fake_dbh = {};
    bless $fake_dbh, $MOCK_DBH_CLASS;
    $fake_dbh->{'connect_cached_args'} = \@args;

    return $fake_dbh;
}

package DBI::Mock::dbh;
sub prepare_cached {
    my ($self, @args) = @_;
    return bless {}, 'DBI::Mock::sth';
}

package DBI::Mock::sth;

sub execute {
    my ($self, @args) = @_;
    return $self;
}

# You probably want to override fetchrow_array in your test method
# to simulate various return values.
sub fetchrow_array {
    my ($self, @args) = @_;
    return @args;
}

sub finish {
    my ($self)  = @_;
    undef $self;
    return;
}

1;
