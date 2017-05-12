use t::boilerplate;

use Test::More;

use_ok 'Class::Usul::Schema';

my $prog = Class::Usul::Schema->new_with_options(
   config         => { ctrldir => 't', tempdir => 't' },
   database       => 'test',
   dry_run        => 1,
   noask          => 1,
   quiet          => 1,
);

is $prog->db_attr->{no_comments}, 1, 'Database attributes';
is $prog->driver, 'sqlite', 'Driver';
is $prog->host, 'localhost', 'Host';
is $prog->password, 'test', 'Password';
is $prog->user, 'root', 'User';

my $dsn = (lc $^O eq 'mswin32')
        ? 'dbi:sqlite:database=t\test.db;host=localhost;port=3306'
        : 'dbi:sqlite:database=t/test.db;host=localhost;port=3306';

is $prog->dsn, $dsn, 'DSN';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
