#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
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
    schema_class => 'MyApp::Schema',
    connect_info => ['dbi:SQLite:dbname=:memory:']
});


after BUILD => sub {
    my $self = shift;
    my $schema = $self->schema;
    eval('use SQL::Translator 0.09003;');
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
	
	$schema->resultset('User')->create({email => 'lisa@simpsons.com', first => 'Lisa', last => 'Simpson' });
	$schema->resultset('User')->create({email => 'bart@simpsons.com', first => 'Bart', last => 'Simpson' });
	$schema->resultset('User')->create({email => 'maggie@simpsons.com', first => 'Maggie', last => 'Simpson' });
	$schema->resultset('User')->create({email => 'homer@simpsons.com', first => 'Homer', last => 'Simpson' });
	$schema->resultset('User')->create({email => 'marge@simpsons.com', first => 'Marge', last => 'Simpson' });
};

1;