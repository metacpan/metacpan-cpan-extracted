my ($msg) = @args;

# $query =
#	find(
#		-tables 	=> [qw(table1 table2)],
#		-where 		=> {bla => 'blo', ble => 'bli'},
#		-wherelike 	=> {bla => '%blo', ble => '%bli'},
#		-group 		=> [qw(field1 field2)],
#		-order 		=> [qw(field3 field4)],
#		-limit 		=> 1000,
#		-distinct 	=> 1,
#	);

# $result1 = 
#	create(
#		-table => 'table',
#		-row => {
#			field1 => 'value1',
#			field2 => 'value2',
#			field3 => 33,
#		},
#	);

# $result2 = 
#	update(
#		-table => 'table',
#		-set => {
#			field1 => 'value1',
#			field2 => 'value2',
#			field3 => 33,
#		},
#		-where 		=> {bla => 'blo', ble => 'bli'},
#		-wherelike 	=> {bla => '%blo', ble => '%bli'},
#	);

# $result3 = 
#	remove(
#		-table => 'table',
#		-where 		=> {bla => 'blo', ble => 'bli'},
#		-wherelike 	=> {bla => '%blo', ble => '%bli'},
#	);

#set('bla' => 'blo');
#set('blub' => [qw(a b c d)]);

return output(1, 'ok', Headline(-content => 'Hello, world!'));
