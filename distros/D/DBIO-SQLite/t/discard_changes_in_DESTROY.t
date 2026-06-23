use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_; };
    {
        # Test that this doesn't cause infinite recursion.
        local *DBIO::Test::Artist::DESTROY;
        local *DBIO::Test::Artist::DESTROY = sub { $_[0]->discard_changes };

        my $artist = $schema->resultset("Artist")->create( {
            artistid    => 10,
            name        => "artist number 10",
        });

        $artist->name("Wibble");

        print "# About to call DESTROY\n";
    }
    is_deeply \@warnings, [];
}

done_testing;
