
use Apache::Session::NoSQL;
  
my %session1;
tie %session1, 'Apache::Session::NoSQL', undef, {
    Driver => 'Cassandra',
    Hostname => 'localhost',
  };
$session1{visa_number} = "1234 5678 9876 5432";
my $id = $session1{_session_id};
untie %session1;

my %session2;
tie %session2, 'Apache::Session::NoSQL', $id, {
    Driver => 'Cassandra',
    Hostname => 'localhost',
  };
tied(%session2)->delete;

