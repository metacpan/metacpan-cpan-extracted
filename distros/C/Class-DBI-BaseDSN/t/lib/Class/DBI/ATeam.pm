use strict;
package Class::DBI::ATeam;
sub set_db {
    my $class = shift;
    my ($name, $dsn, $extra) = @_;
    $$extra = "$class, you have found the A-team";
}

1;
