use lib "../lib";

use strict;
use warnings;
no warnings 'uninitialized';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;


HR_connect;

my @fake_data = ( [qw/emp_id firstname        lastname   /],
                  [qw/1      Johann-Sebastian Bach       /],
                  [qw/2      Hector           Berlioz    /],
                  [qw/3      Claudio          Monteverdi /] );



subtest 'categorize'=> sub {
  eval "use List::Categorize 0.04; 1"
    or plan skip_all => "List::Categorize 0.04 not installed";

  $dbh->{mock_add_resultset}
    = [@fake_data,
       [qw/1 Johann-Christoph Bach/]]; # emp_id=1 on purpose, to test 2-level categ
  my $result = HR->table('Employee')->select(
    -result_as => [categorize => qw/lastname emp_id/],
   );
  is_deeply $result, {
    Monteverdi => {
      3 => [ { emp_id => '3',
               firstname => 'Claudio',
               lastname  => 'Monteverdi',   } ] },
    Bach => {
      1 => [ { emp_id    => '1',
               firstname => 'Johann-Sebastian',
               lastname  => 'Bach',         },
             { emp_id    => '1',
               firstname => 'Johann-Christoph',
               lastname  => 'Bach',         },
       ]
     },
    Berlioz => {
      2 => [ { emp_id    => '2',
               firstname => 'Hector',
               lastname  => 'Berlioz'       } ],
     }
   };


  # custom subroutine for key generation
  $dbh->{mock_add_resultset} = \@fake_data;
  my $key_maker = sub {my $row = shift; substr($row->{lastname}, 0, 1)};
  $result = HR->table('Employee')->select(-result_as => [categorize => $key_maker ]);
  is scalar(@{$result->{B}}), 2 , "categorize with sub"; # Berlioz and Bach
};

subtest 'count'=> sub {
  $dbh->{mock_add_resultset} = [ ['N_ROWS'], [3] ];
  my $result = HR->table('Employee')->select(-result_as => 'count');
  sqlLike('SELECT COUNT(*) AS N_ROWS FROM T_EMPLOYEE', [], 'sql for count(*)');
  is $result, 3, 'count';
};


subtest 'fast_statement'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'fast_statement');
  isa_ok $result, 'DBIx::DataModel::Statement';
};

subtest 'file_tabular'=> sub {
  eval "use File::Tabular; 1"
    or plan skip_all => "File::Tabular not installed";

  $dbh->{mock_add_resultset} = \@fake_data;
  open my $fh, ">", \my $in_memory;
  my $result = HR->table('Employee')->select(
    -result_as => [file_tabular => $fh, {fieldSep => "\t"}],
   );
  close $fh;
  $in_memory =~ s/\r\n/\n/g; # because of stupid binmode(:crlf) in File::Tabular
  my $expected = join "\n", (map {join "\t", @$_} @fake_data), "";
  is $in_memory, $expected, "File::Tabular file OK";
  is $result, 3,            "File::Tabular result count rows OK";
};


subtest 'firstrow'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'firstrow');
  isa_ok $result, 'HR::Employee';
};

subtest 'flat_arrayref'=> sub {
  $dbh->{mock_add_resultset} = [map {[@{$_}[2,0]]} @fake_data];
  my $result = HR->table('Employee')->select(-columns => [qw/lastname emp_id/],
                                             -result_as => 'flat');
  my %hash = @$result;
  is_deeply \%hash, {Bach => 1, Berlioz => 2, Monteverdi => 3}, 'flat_arrayref';
};

subtest 'hashref'=> sub {
  # regular 1-level hashref
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-columns => [qw/lastname emp_id/],
                                             -result_as => [hashref => 'lastname']);
  is_deeply [sort keys %$result], [qw/Bach Berlioz Monteverdi/], 'hashref';

  # tree of depth 2
  $dbh->{mock_add_resultset} = \@fake_data;
  $result = HR->table('Employee')->select(-result_as => [hashref => (qw/lastname firstname/) ]);
  ok defined $result->{Berlioz}{Hector}, "nested columns";

  # custom subroutine for key generation
  $dbh->{mock_add_resultset} = \@fake_data;
  my $key_maker = sub {my $row = shift; map {substr($_, 0, 1)} @{$row}{qw/lastname firstname/}};
  $result = HR->table('Employee')->select(-result_as => [hashref => $key_maker ]);
  ok defined $result->{B}{H}, "hashref with sub";
};

subtest 'json'=> sub {
  eval "use JSON::MaybeXS; 1"
    or plan skip_all => "JSON::MaybeXS not installed";

  $dbh->{mock_add_resultset} = \@fake_data;
  my $json = HR->table('Employee')->select(-result_as => 'json');
  like $json, qr/lastname"?\s*:\s*"?Bach/, 'JSON';

  my @records = $json =~ m/{/g;
  is scalar(@records), 3, 'nb of records in JSON';
};

subtest 'rows'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'rows');
  isa_ok $result->[0], 'HR::Employee', 'rows are Employees';
  is scalar(@$result), 3, '3 rows';
};

subtest 'sql'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-where => {foo => 123},
                                             -result_as => 'sql');
  like $result, qr/^select\s+\*\s+from/i, 'SQL in scalar context';

  $dbh->{mock_add_resultset} = \@fake_data;
  my @result = HR->table('Employee')->select(-where => {foo => {-in => [123, 456]}},
                                             -result_as => 'sql');
  like $result[0], qr/^select\s+\*\s+from/i, 'SQL in list context';
  is   $result[1], 123,                      'bind value 1';
  is   $result[2], 456,                      'bind value 2';
};

subtest 'statement'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'statement');
  isa_ok $result, 'DBIx::DataModel::Statement';
};

subtest 'sth'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'sth');
  isa_ok $result, 'DBI::st';
};

subtest 'subquery'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'subquery');
  isa_ok $$result, 'ARRAY', 'subquery: ref to arrayref';
};

subtest 'table'=> sub {
  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(-result_as => 'table');
  is_deeply $result, \@fake_data, 'table';
};


subtest 'tsv'=> sub {
  open my $fh, ">", \my $in_memory;

  $dbh->{mock_add_resultset} = \@fake_data;
  my $result = HR->table('Employee')->select(
    -result_as => [tsv => $fh],
   );

  close $fh;
  my $expected = join "\n", (map {join "\t", @$_} @fake_data), "";
  is $in_memory, $expected, "Tsv file OK";
};


subtest 'xlsx'=> sub {
  eval "use Excel::Writer::XLSX; 1"
    or plan skip_all => "Excel::Writer::XLSX not installed";

  $dbh->{mock_add_resultset} = \@fake_data;
  open my $fh, ">", \my $in_memory;
  my $result = HR->table('Employee')->select(
    -result_as => [xlsx => $fh],
   );
  close $fh;
  ok $in_memory; # just checks if non-empty ... any way to test better ?
};


subtest 'yaml'=> sub {
  eval "use YAML::XS; 1"
    or plan skip_all => "YAML::XS not installed";

  $dbh->{mock_add_resultset} = \@fake_data;
  my $yaml = HR->table('Employee')->select(-result_as => 'yaml');
  like $yaml, qr/lastname:\s+Bach/, 'YAML';
  my @records = $yaml =~ m/^-\s/gm;
  is scalar(@records), 3, 'nb of records in YAML';
};


subtest 'correlated_update'=> sub {
  my $count_updates = HR->join(qw/Activity employee department/)->select(
    -columns   => [qw/d_birth d_begin dpt_name/],
    -result_as => [correlated_update =>
       {'T_Activity.remark' => "'started in ' || dpt_name || ' at age ' || d_begin-d_birth"}
     ]);

  sqlLike("UPDATE (SELECT d_birth, d_begin, dpt_name FROM T_Activity " .
          "INNER JOIN T_Employee ON ( T_Activity.emp_id = T_Employee.emp_id ) " .
          "INNER JOIN T_Department ON ( T_Activity.dpt_id = T_Department.dpt_id )) " .
          "SET T_Activity.remark='started in ' || dpt_name || ' at age ' || d_begin-d_birth", [], 'correlated update');
};



subtest 'find_subclass' => sub {
  # test a result kind as subclass of current schema
  my $result = HR->table('Employee')->select(-result_as => 'stupid');
  is $result, 'stupid', 'ResultAs subclass in current schema';


  # test loading a buggy result class
  die_ok (sub {HR->table('Employee')->select(-result_as => 'buggy')} );
};


subtest 'bad_subclass' => sub {
  use DBIx::DataModel::Meta::Utils qw/define_class/;
  # create a fake subclass
  define_class(name => "DBIx::DataModel::Schema::ResultAs::FooBar",
               isa  => ["DBIx::DataModel::Schema::ResultAs"],
               metadm => 'DBIx::DataModel::Meta',
              );
  my $fake_instance = bless {}, "DBIx::DataModel::Schema::ResultAs::FooBar";
  eval {$fake_instance->get_result()};
  my $err = $@;
  like($err, qr/should implement.*as required/, 'proper error msg for abstract method');
};


done_testing;
