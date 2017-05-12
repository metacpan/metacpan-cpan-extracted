package CD::mysql;
use base qw(Class::DBI::mysql);
__PACKAGE__->set_db('Main', 'dbi:mysql:test', '', '', { RaiseError => 1 });

1;
