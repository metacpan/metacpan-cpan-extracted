#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Create;


unless ( eval { require DBD::Pg } && ! $@ )
{
    plan skip_all => 'needs DBD::Pg';
    exit;
}

plan tests => 13;


my $new_schema;
eval_ok( sub { $new_schema = Alzabo::Create::Schema->new( name => 'hello_there',
                                                          rdbms => 'PostgreSQL' ) },
	 "Make a new PostgreSQL schema named 'hello_there'" );

{
    eval { Alzabo::Create::Schema->new( name => "hello'there",
                                        rdbms => 'PostgreSQL' ); };

    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception::RDBMSRules',
            "Exceptiont thrown from attempt to create a PostgreSQL schema named hello\'there" );
}

{
    eval { $new_schema->make_table( name => 'x' x 65 ) };
    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception::RDBMSRules',
            "Exception thrown from attempt to create a table in PostgreSQL with a 65 character name" );
}

my $table = $new_schema->make_table( name => 'quux' );

{
    eval { $table->make_column( name => 'foo2',
                                type => 'text',
                                length => 1,
                              ); };
    my $e = $@;
    isa_ok( $e, 'Alzabo::Exception::RDBMSRules',
            "Exception thrown from attempt to make 'text' column with a length parameter" );
}

{
    foreach my $type ( qw( DATE TIMESTAMP TIMESTAMPTZ  ) )
    {
        my $col = $table->make_column( name => "col_$type",
                                       type => $type,
                                     );

        ok( $col->is_date, "$type is date" );
    };
}

{
    foreach my $type ( qw( TIMESTAMP TIMESTAMPTZ ) )
    {
        my $col = $table->make_column( name => "col2_$type",
                                       type => $type,
                                     );

        ok( $col->is_datetime, "$type is date" );
    };
}

{
    my $col = $table->make_column( name => 'col_INTERVAL',
                                   type => 'INTERVAL',
                                 );

    ok( $col->is_time_interval, 'INTERVAL is a time interval' );
}

{
    my $col = $table->make_column( name => 'int1',
                                   type => 'integer',
                                   default => 27,
                                 );

    is( $new_schema->rules->_default_for_column($col), 27, 'default is 27' );
}

{
    my $col = $table->make_column( name => 'vc1',
                                   type => 'varchar',
                                   length => 20,
                                   default => 'hello',
                                 );

    is( $new_schema->rules->_default_for_column($col), q|'hello'|, "default is 'hello' (with quotes)" );
}

{
    my $col = $table->make_column( name => 'dt1',
                                   type => 'timestamp',
                                   default => 'NOW()',
                                   default_is_raw => 1,
                                 );

    is( $new_schema->rules->_default_for_column($col), q|NOW()|, 'default is NOW()' );
}
