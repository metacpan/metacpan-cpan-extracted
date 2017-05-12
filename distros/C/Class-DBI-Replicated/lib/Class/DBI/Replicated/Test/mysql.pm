package Class::DBI::Replicated::Test::mysql;

use strict;
use warnings;
use base qw(Class::DBI::Replicated::Test
            Class::DBI::Replicated::mysql);

=head1 NAME

Class::DBI::Replicated::Test::mysql

=cut

my @from_env = qw(db user pass host repl_user repl_pass);
my %cfg;

for my $key (@from_env) {
  $cfg{$key} = $ENV{"MYSQL_" . uc($key)} || "";
}
      
__PACKAGE__->_test_init;

__PACKAGE__->replication({
  master => [
    "dbi:mysql:$cfg{db};host=$cfg{host}",
    $cfg{user}, $cfg{pass},
  ],
  slaves => [
    localhost => [
      "dbi:mysql:$cfg{db}",
      $cfg{user}, $cfg{pass},
    ],
  ],
  user     => $cfg{repl_user},
  password => $cfg{repl_pass},
});

__PACKAGE__->table('repl_test');

__PACKAGE__->create_table(<<'');
id     int         not null auto_increment primary key,
name   varchar(40) not null,
flavor varchar(20) not null default 'Original'

__PACKAGE__->set_up_table;

1;
