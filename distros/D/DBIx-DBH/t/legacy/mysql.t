# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-DBH.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;
use Test::More;
BEGIN { plan 'no_plan' }
use DBIx::DBH;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my @opt = 'mysql_client_found_rows';
my @dat =       ( driver => 'mysql',
	dbname => 'db_terry',
	user => 'terry',
	password => 'markso' ) ;

sub make_data {
  DBIx::DBH->form_dsn
      (
       @dat,
       map {	 $_ => 1 } @opt
      );
}
    
is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1');

push @opt, 'mysql_compression';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1');

push @opt, 'mysql_connect_timeout';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1');

push @opt, 'mysql_read_default_file';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1');

push @opt, 'mysql_read_default_group';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1');

push @opt, 'mysql_ssl';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1');

push @opt, 'mysql_ssl_client_key';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_client_key=1');

push @opt, 'mysql_ssl_client_cert';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_client_cert=1;mysql_ssl_client_key=1');

push @opt, 'mysql_ssl_ca_file';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_ca_file=1;mysql_ssl_client_cert=1;mysql_ssl_client_key=1');

push @opt, 'mysql_ssl_ca_path';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_ca_file=1;mysql_ssl_ca_path=1;mysql_ssl_client_cert=1;mysql_ssl_client_key=1');

push @opt, 'mysql_ssl_cipher';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_ca_file=1;mysql_ssl_ca_path=1;mysql_ssl_cipher=1;mysql_ssl_client_cert=1;mysql_ssl_client_key=1');

push @opt, 'mysql_local_infile';

is(make_data, 'DBI:mysql:db_terry;mysql_client_found_rows=1;mysql_compression=1;mysql_connect_timeout=1;mysql_local_infile=1;mysql_read_default_file=1;mysql_read_default_group=1;mysql_ssl=1;mysql_ssl_ca_file=1;mysql_ssl_ca_path=1;mysql_ssl_cipher=1;mysql_ssl_client_cert=1;mysql_ssl_client_key=1');

undef @opt;
push @dat, (port => 3313);

is(make_data, 'DBI:mysql:db_terry;port=3313');
