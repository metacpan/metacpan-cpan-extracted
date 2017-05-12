package t::Util;
use strict;
use warnings;

use t::Mock;

use parent qw/Test::Builder::Module/;
our @EXPORT = qw/create_mock_dbh/;

sub create_mock_dbh {
    t::Mock->new('DBI::db', {
        begin_work => sub { 1 },
        rollback   => sub { 1 },
        commit     => sub { 1 },
        FETCH      => sub { $_[1] eq 'AutoCommit' },
    });
}

1;
__END__
