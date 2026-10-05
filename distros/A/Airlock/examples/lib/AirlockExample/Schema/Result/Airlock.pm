package AirlockExample::Schema::Result::Airlock;

# The Airlock table as a DBIO result class. Same columns as examples/schema.sql.

use DBIO::Candy;

table 'airlock';

primary_column hash => { data_type => 'varchar', size => 64 };

column kind            => { data_type => 'varchar', size => 16 };
column user_code       => { data_type => 'varchar', size => 16, is_nullable => 1 };
column client_id       => { data_type => 'varchar', size => 255 };
column scope           => { data_type => 'text' };
column state           => { data_type => 'varchar', size => 16 };
column created         => { data_type => 'bigint' };
column expires         => { data_type => 'bigint' };
column poll_interval   => { data_type => 'integer', is_nullable => 1 };
column last_poll       => { data_type => 'bigint', is_nullable => 1 };
column subject         => { data_type => 'varchar', size => 255, is_nullable => 1 };
column amr             => { data_type => 'varchar', size => 255, is_nullable => 1 };
column acr             => { data_type => 'varchar', size => 255, is_nullable => 1 };
column auth_time       => { data_type => 'bigint', is_nullable => 1 };
column approved        => { data_type => 'bigint', is_nullable => 1 };
column origin_ip       => { data_type => 'varchar', size => 64, is_nullable => 1 };
column origin_ua       => { data_type => 'varchar', size => 255, is_nullable => 1 };
column factor_failures => { data_type => 'integer', default_value => 0 };

unique_constraint airlock_user_code => ['user_code'];

1;
