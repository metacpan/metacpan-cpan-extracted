#!perl
# $Id: 02-inflate.t 2 2005-02-22 01:31:59Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;

BEGIN
{
    require Test::More;
    if ($ENV{HAVE_SQLITE}) {
        Test::More->import(tests => 5);
    } else {
        Test::More->import(skip_all => 'DBD::SQLite is not installed');
    }
}

BEGIN
{
    use_ok("Class::DBI::LazyInflate");
}

use vars qw($INFLATED);

package TC::DateTime;
use strict;
sub new {
    my $class = shift;
    my $time  = shift;

    return bless \$time, $class;
}

sub epoch {
    my $self = shift;
    return $$self;
}

package TC;
use strict;
use base qw(Class::DBI);
use Class::DBI::LazyInflate;

__PACKAGE__->set_db(Main => 'dbi:SQLite:dbname=t/test.db', undef, undef, { AutoCommit => 1, RaiseError => 1});
__PACKAGE__->table('tc');
__PACKAGE__->columns(All => qw(id datetime));
__PACKAGE__->has_lazy(
    datetime => 'TC::DateTime',
    inflate => sub { $main::INFLATED = 1; TC::DateTime->new(shift) },
    deflate => 'epoch',
);

package main;
use strict;

TC->db_Main->do(q{
    CREATE TABLE tc (
        id INT,
        datetime INT
    );
});

my $time  = time();
my $tc_dt = TC::DateTime->new($time);
my $tc    = TC->create({ id => 1, datetime => $tc_dt });

$INFLATED = 0;
$tc = TC->retrieve(1);
ok(!$INFLATED);
isa_ok($tc->datetime, 'TC::DateTime');
ok($INFLATED);
is($tc->datetime->epoch, $time);

END
{
    unlink("t/test.db");
}
