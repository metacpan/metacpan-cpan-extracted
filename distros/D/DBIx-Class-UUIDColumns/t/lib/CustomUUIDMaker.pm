package CustomUUIDMaker;

use strict;
use warnings;

use base qw/DBIx::Class::UUIDColumns::UUIDMaker/;

sub as_string {
    return '12345678-1234-2345-3456-123456789090';
};

1;
__END__