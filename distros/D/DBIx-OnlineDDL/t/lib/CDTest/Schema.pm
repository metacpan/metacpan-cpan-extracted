use utf8;
package # hide from PAUSE
    CDTest::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pkzbnywZvNAySndt4tkcrQ

sub multi_do {
    my ($self, $sql) = @_;

    foreach my $chunk (split /\s*;\s*\n+/, $sql) {
        # There is some real sql in the chunk - a non-space at the start of the string which is not a comment
        if ($chunk =~ / ^ (?! --\s* ) \S /xm) {
            $self->storage->dbh_do(sub { $_[1]->do($chunk) }) or warn "Error on SQL: $chunk\n";
        }
    }
}

1;
