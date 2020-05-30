# CSV::Reader - CSV reader class

Easy to use Perl CSV file/handle reader class that's meant for reading typical CSV files having a CSV header row.\
This was designed with the idea of using an iterator interface, but Perl does not support interators (nor interfaces) yet :(\
You can also find this module on cpan: https://metacpan.org/pod/CSV::Reader

Synopsis
--------
```perl
use CSV::Reader ();
use open OUT => ':locale'; # optional; make perl aware of your terminal's encoding

# Create reader from file name:
my $reader = new CSV::Reader('/path/to/file.csv');

# Create reader from a file handle (GLOB):
open(my $h, '<', $filename) || die("Failed to open $filename: $!");
# or preferred method that can handle files having a UTF-8 BOM:
open(my $h, '<:via(File::BOM)', $filename) || die("Failed to open $filename: $!");
my $reader = new CSV::Reader($h);

# Create reader from an IO::Handle based object:
my $io = IO::File->new(); # subclass of IO::Handle
$io->open($filename, '<:via(File::BOM)') || die("Failed to open $filename: $!");
my $reader = new CSV::Reader($io);

# Create reader with advanced options:
my $reader = new CSV::Reader('/path/to/file.csv',
	'delimiter' => ';',
	'enclosure' => '',
	'field_normalizer' => sub {
		my $nameref = shift;
		$$nameref = lc($$nameref);	# lowercase
		$$nameref =~ s/\s/_/g;	# whitespace to underscore
	},
	'field_aliases'	=> {
		'postal_code' => 'postcode', # applied after normalization
	},
);

# Show the field names found in the header row:
print "Field names:\n" . join("\n", $reader->fieldNames()) . "\n";

# Iterate over the data rows:
while (my $row = $reader->nextRow()) {
	# It's recommended to validate the $row hashref first with something such as Params::Validate.
	# Now do whatever you want with the (validated) row hashref...
	require Data::Dumper; local $Data::Dumper::Terse = 1;
	print Data::Dumper::Dumper($row);
}
```

Public static methods
---------------------

### new($file, %options)

Constructor.

```$file``` can be a string file name, an open file handle (GLOB), or an IO::Handle based object (e.g. IO::File or IO::Scalar).
If a string file name is given, then the file is opened via File::BOM.

The following ```%options``` are supported:

- ```debug```: boolean, if true, then debug messages are emitted using warn().
- ```field_aliases```: hashref of case insensitive alias (in file) => real name (as expected in code) pairs.
- ```field_normalizer```: optional callback that receives a field name by reference to normalize (e.g. make lowercase).
- ```include_fields```: optional arrayref of field names to include. If given, then all other field names are excluded.
- ```delimiter```: string, default ','
- ```enclosure```: string, default '"'
- ```escape```: string, default backslash

Note: the option ```field_aliases``` is processed after the option ```field_normalizer``` if given.

Public object methods
---------------------

### fieldNames()

Returns the field names as an array.

### current()

Returns the current row.

### linenum()

Returns the current row index.

### nextRow()

Reads the next row.

### eof()

Returns boolean

### rewind()

Rewinds the file handle.

Requirements
------------
- File::BOM (recommended; not required)
- Params::Validate
- Text::CSV
- Tie::IxHash

Installation using cpan
-----------------------
CSV::Reader may be installed through the CPAN shell in the usual manner:
```
# perl -MCPAN -e 'install CSV::Reader'
```
or you can install the component from the CPAN prompt:
```
cpan> install CSV::Reader
```

Installation using make
-----------------------
```
perl Makefile.PL
make
make test
make install
```

Author
------
Craig Manley

Copyright
---------
Copyright (C) 2020 Craig Manley. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
