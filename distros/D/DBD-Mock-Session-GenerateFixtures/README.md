# DBD::Mock::Session::GenerateFixtures

DBD::Mock::Session::GenerateFixtures - When a real DBI database handle ($dbh) is provided, the module generates DBD::Mock::Session data.
Otherwise, it returns a DBD::Mock::Session object populated with generated data.
This not a part form DBD::Mock::Session distribution just a wrapper around it.

# SYNOPSIS

```		
	# Case 1: Providing a pre-existing DBI database handle for genereting a mocked data files with the test name
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ dbh => $dbh });
	my $real_dbh = $mock_dumper->get_dbh();

	# Case 2: Read data from the same file as current test
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new();
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD

	# Case 3: Read data from a coustom file
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ file => 'path/to/fixture.json' });
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD

	# Case 4: Providing an array reference containing mock data
	my $mock_dumper = DBD::Mock::Session::GenerateFixtures->new({ data => \@mock_data });
	my $dbh = $mock_dumper->get_dbh();
	# Your code using the mock DBD
```
# Instalation
	
1. git clone git@github.com:DragosTrif/DBD-Fixtures.git
2. perl Makefile.PL
3. make test
4. make install 
