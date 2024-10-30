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
   feature->import("try"); "station"
EVAL
}

sub test_experimental { eval <<'EVAL'
   feature->import("try"); 1
EVAL
}

1;

