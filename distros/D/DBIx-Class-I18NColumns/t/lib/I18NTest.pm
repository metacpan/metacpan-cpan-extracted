package # Hide from PAUSE
    I18NTest;

use strict;
use warnings;

sub new {
    my ($class, $schema_class) = @_;
    $schema_class ||= 'I18NTest::Schema';

    eval "require $schema_class"
      or die "failed to require $schema_class: $@";

    my $schema = $schema_class->connect("DBI:SQLite::memory:",'','', { sqlite_unicode => 1 })
      or die "failed to connect to DBI:SQLite::memory: ($schema_class)";

    $schema->deploy;
    return $schema;
}

1;

