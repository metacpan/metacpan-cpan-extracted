#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::Model::DBIC;

use Moose;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config({
    schema_class => 'TestSchema',
    connect_info => ['dbi:SQLite:dbname=:memory:']
});


after BUILD => sub {
    my $self = shift;
    my $schema = $self->schema;
    eval('use SQL::Translator 0.11005;');
    if ($@) {
        my $sql;
        {
            local $/;
            open( my $fh, 't/sqlite.sql' );
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
        unlink('t/sqlite.sql') if(-e 't/sqlite.sql');
        $schema->deploy;
        $schema->create_ddl_dir( ['SQLite'], undef, './', undef,
            { add_drop_table => 0 } );
    }
};

1;