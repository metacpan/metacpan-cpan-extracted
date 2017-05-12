package ContactTestData;
use strict;

our ($first_name, $last_name)=qw(foo bar);
our @aliases = qw(foob foobar);
our @email_addresses=qw(foo@bar.com foobar@yahoo.com);

our @args=(
    -first_name => $first_name,
    -last_name => $last_name,
    -aliases => \@aliases,
    -emails => \@email_addresses
);

1;
