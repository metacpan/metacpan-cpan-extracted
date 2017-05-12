# NAME

Convert::TBX::UTX - Convert back and forth from TBX-Min to UTX format

# SYNOPSIS

	use Convert::TBX::UTX;
	my $UTX_string_output = min2utx('/path/to/file.tbx', '/path/to/output');  #or scalar ref to data
	my $TBX_string_output = utx2min('/path/to/file.utx', '/path/to/output');  

# DESCRIPTION

A two way converter for Termbase Exchange files in UTX 1.11 (see http://www.aamt.info/english/utx/ for specifications) format to TBX-Min.

# METHODS

## 'min2utx(input [, output])'

	Converts TBX-Min into UTX format.  'Input' can be either filename or scalar ref containing scalar data.  If given only 'input' it returns a scalar ref containing the converted data.  If given both 'input' and 'output', it will print converted data to the 'output' file.

## 'utx2min(input [, output])'

	Converts UTX into TBX-Min format.  'Input' can be either filename or scalar ref containing scalar data.  If given only 'input' it returns a scalar ref containing the converted data.  If given both 'input' and 'output', it will print converted data to the 'output' file.

# TERMINAL COMMANDS

## 'tbx2utx (input_tbx) (output)'

	Converts TBX-Min to UTX and prints to <output>.

## 'utx2tbx (input_utx) (output)'

	Converts UTX to TBX-Min and prints to <output>.

# AUTHORS

James Hayes <james.s.hayes@gmail.com>,
Nathan Glenn <garfieldnate@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

