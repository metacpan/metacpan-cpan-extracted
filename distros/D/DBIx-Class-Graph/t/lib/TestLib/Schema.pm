#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package    # hide from PAUSE
  TestLib::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes();

sub ddl_filename {
    't/sqlite.sql';
}

sub deploy {
    my $schema = shift;
    eval('use SQL::Translator 0.11005;');
    if ($@) {
        my $sql;
        {
            local $/;
            open( my $fh, $schema->ddl_filename );
            $sql = <$fh>;
        }
        for my $chunk ( split( /;\s*\n+/, $sql ) ) {
            if ( $chunk =~ / ^ (?! --\s* ) \S /xm )
            { # there is some real sql in the chunk - a non-space at the start of the string which is not a comment
                $schema->storage->dbh->do($chunk)
                  or print "Error on SQL: $chunk\n";
            }
        }
    }
    else {
        unlink($schema->ddl_filename) while(-e $schema->ddl_filename);
        $schema->next::method(@_);
        $schema->create_ddl_dir( ['SQLite'], undef, './', undef,
            { add_drop_table => 0 } );
    }
};

1;
