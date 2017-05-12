use strict;
use warnings;
use Test::More;

package My::SetDefaultSchema;
use DBIx::Schema::DSL;

database 'MySQL';
create_database 'my_database';

default_unsigned;
default_not_null;
add_table_options
    mysql_charset => 'utf8mb4';

create_table 'book' => columns {
    integer 'id',   primary_key, auto_increment;
    varchar 'name';
};

package My::NoSetDefaultSchema;
use DBIx::Schema::DSL;

database 'MySQL';
create_database 'my_database';

create_table 'book' => columns {
    integer 'id',   primary_key, auto_increment;
    varchar 'name';
    varchar 'explanation', null;
};


package main;

subtest 'SetDefaultSchema' => sub {
    my $output_schema = My::SetDefaultSchema->output;
    note $output_schema;
    like( $output_schema, qr/`id` INTEGER unsigned NOT NULL auto_increment,/);
    like( $output_schema, qr/`name` VARCHAR\(191\) NOT NULL,/);
};

subtest 'NoSetDefaultSchema' => sub {
    my $output_schema = My::NoSetDefaultSchema->output;
    note $output_schema;
    like( $output_schema, qr/`id` INTEGER NOT NULL auto_increment,/);
    like( $output_schema, qr/`name` VARCHAR\(255\) NULL,/ );
    like( $output_schema, qr/`explanation` VARCHAR\(255\) NULL DEFAULT NULL,/ );
};

done_testing;
