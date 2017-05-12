{

    package Schema::Item;

    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw(BitField Core));

    __PACKAGE__->table('item');

    __PACKAGE__->add_columns(
        id => { data_type => 'integer' },
        bitfield =>
          { data_type => 'integer', bitfield => [qw(status1 status2 status3)] },
        bitfield2 => {
            data_type       => 'integer',
            bitfield        => [qw(status1 status2 status3)],
            bitfield_prefix => 'status_',
            accessor        => '__bitfield2',
            is_nullable     => 1
        },

    );

    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::BitField');

}

{
    package    # hide
      Schema::Base;

    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw(BitField Core));

    __PACKAGE__->table('foo');

    sub add_common_columns {
        shift->add_columns( "status",
            { data_type => "Integer", bitfield => [qw/foo bar/] } );
    }
}

{

    package    # hide
      Schema::SubClassI;
    use base qw/Schema::Base/;

    __PACKAGE__->table('subclass_1');

    __PACKAGE__->add_columns('id');

    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->add_common_columns;

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::BitField');
}

{

    package    # hide
      Schema::SubClassII;
    use base qw/Schema::Base/;

    __PACKAGE__->table('subclass_2');

    __PACKAGE__->add_columns('id');

    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->add_common_columns;

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::BitField');
}

{
    package    # hide
      Schema;

    use base 'DBIx::Class::Schema';

    __PACKAGE__->load_classes( 'Item', 'SubClassI', 'SubClassII' );

    sub connect {
        my $class  = shift;
        my $schema = $class->next::method('dbi:SQLite::memory:');
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
            $schema->deploy;
            $schema->create_ddl_dir( ['SQLite'], undef, undef, undef,
                { add_drop_table => 0 } );
        }
        return $schema;
    }

    sub ddl_filename {
        return 't/sqlite.sql';
    }

}

1;

