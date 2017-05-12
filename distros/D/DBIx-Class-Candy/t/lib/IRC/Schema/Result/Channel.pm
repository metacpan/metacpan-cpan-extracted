package IRC::Schema::Result::Channel;

use IRC::Schema::Candy;

primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
};

column name => {
   data_type => 'varchar',
   size      => 100,
};

column network_id => {
   data_type => 'int',
};

belongs_to network => 'IRC::Schema::Result::Network', 'network_id';
unique_constraint [qw( name )];

sub test_perl_version { eval <<'EVAL'
   no if $] > 5.017010, warnings => 'experimental::smartmatch';

   given (1) { when (1) { return 'station' } }
EVAL
}

sub test_experimental { eval <<'EVAL'
   sub ($a) { $a + 1}
EVAL
}

1;

