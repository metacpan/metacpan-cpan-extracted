package Artist;

BEGIN { unshift @INC, './t/testlib'; }
use base 'Class::DBI::Test::SQLite';
use mixin 'Class::DBI::Audit';
use strict;

__PACKAGE__->set_table('artist');
__PACKAGE__->columns('Primary',   'artistid');
__PACKAGE__->columns('Essential', qw(first_name last_name age));

__PACKAGE__->columns(Audit => qw/first_name last_name age/);
__PACKAGE__->add_audit_triggers();

__PACKAGE__->auditColumns( {
        remote_addr => [ from_hash   => { name => 'ENV', key => 'REMOTE_ADDR' } ],
        remote_user => [ from_hash   => { name => 'ENV', key => 'REMOTE_USER' } ],
        request_uri => [ from_hash   => { name => 'ENV', key => 'REQUEST_URI' } ],
        command     => [ from_scalar => { name => '0',    } ], 
        time_stamp  => [ from_sub    => { subroutine => sub { time } } ],
    }
);

sub create_sql {
    return qq{
       artistid   integer not null primary key autoincrement,
       first_name varchar(255),
       last_name  varchar(255),
       age        integer
  }
}

sub create_test_artist {
    return shift->insert({
            first_name => 'Jennifer',
            last_name  => 'Lopez',
        });
}

1;

