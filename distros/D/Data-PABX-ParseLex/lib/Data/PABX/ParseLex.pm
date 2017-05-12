package Data::PABX::ParseLex;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;
no warnings 'redefine';

require Exporter;

use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::PABX::ParseLex ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.05';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

}	# End of Encapsulated class data.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	$$self{'_service'}		= {};
	$$self{'_unexpected'}	= {};

	$self;

}	# End of new.

# -----------------------------------------------

sub parse
{
	my($self, $file_name) = @_;

	open(INX, $file_name) || Carp::croak("Can't open($file_name): $!");
	my(@line) = <INX>;
	close INX;
	chomp @line;

	# Clean up the input file, in case
	# multiple 'lex a e' commands were issued:
	# o Find the last /\??lex/, if any
	# o Remove all lines prior to that

	my($last) = 0;

	for (0 .. $#line)
	{
		$last = $_ if ($line[$_] =~ /\??\s*lex a e/i);
	}

	splice(@line, 0, ($last + 1) );

	my(@field, %service, $service_number);

	for (@line)
	{
		s/^\s+//;
		s/\s+$//;

		# Skip empty lines and the prompt
		# after the output of 'lex a e'.

		next if (! $_ || (/^\?/) );

		# Check the service number.

		if (/^([A-Z]{2})(\d{4,5})\s/)
		{
			$service_number = $2;

			Carp::carp("Warning. Service: $service_number. Duplicate records for service"), next if ($$self{'_service'}{$service_number});

			$$self{'_service'}{$service_number}					= {};
			$$self{'_service'}{$service_number}{'number_type'}	= $1;
		}
		else
		{
			$$self{'_service'}{$service_number}{'ksgm_id'} = $_;

			next;
		}

		@field = split(/\s+/, $_);

		shift @field; # Discard service number.

		# Check the PABX port.
		# Port digits for types AC, EC, IC and OC:
		# 0 .. 1 => Shelf
		# 2 .. 3 => Slot
		# 4 .. 5 => Access
		# Port digits for BC and DI:
		# 0 .. 3 => Unknown
		# If the service number type was CN or VN, there won't be a port.

		if ($field[0] =~ /^([A-Z]{2})(\d{6})$/)
		{
			$$self{'_service'}{$service_number}{'pabx_card_type'}	= $1;
			$$self{'_service'}{$service_number}{'pabx_port'}		= $2;

			shift @field; # Discard port.
		}
		elsif ($field[0] =~ /^(BC|DI)(\d{4})$/)
		{
			$$self{'_service'}{$service_number}{'pabx_card_type'}	= $1;
			$$self{'_service'}{$service_number}{'pabx_port'}		= $2;

			shift @field; # Discard port.
		}
		else
		{
			$$self{'_service'}{$service_number}{'pabx_card_type'}	= '-';
			$$self{'_service'}{$service_number}{'pabx_port'}		= '-';
		}

		# Check the options.

		while ($_ = shift @field)
		{
			if (/^(\*|\$)$/)
			{
				$$self{'_service'}{$service_number}{$_} = 1;
			}
			elsif (/^(A)(0\d)$/)
			{
				$$self{'_service'}{$service_number}{$1} = $2;
			}
			elsif ($_ eq 'ACD')
			{
				if (@field && ($field[0] eq 'QUEUE') )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected ACD to be followed by QUEUE");
				}
			}
			elsif ($_ eq 'AGENT')
			{
				if (@field && ($field[0] eq 'GROUP') )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected AGENT to be followed by GROUP");
				}
			}
			elsif (/^(BE|BI|DG|HG|IE|KSGM?|MULT|RE|SPARE)$/)
			{
				$$self{'_service'}{$service_number}{$_} = 1;
			}
			elsif (/^(CS)(\d{2})$/)
			{
				$$self{'_service'}{$service_number}{$1} = $2;
			}
			elsif ($_ eq 'D')
			{
				if (@field && ($field[0] =~ /^00(1|2)$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					$$self{'_service'}{$service_number}{$_} = '001';
				}
			}
			elsif ($_ eq 'II')
			{
				if (@field && ($field[0] =~ /^\d+$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected II to be followed by N digits");
				}
			}
			elsif ($_ =~ /^(MLG)(\d+)$/)
			{
				$$self{'_service'}{$service_number}{$1} = $2;
			}
			elsif ($_ eq 'MOH')
			{
				if (@field && ($field[0] =~ /^000$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected MOH to be followed by 000");
				}
			}
			elsif ($_ eq 'OG')
			{
				if (@field && ($field[0] =~ /^\d+$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected OG to be followed by N digits");
				}
			}
			elsif ($_ eq 'RI')
			{
				if (@field && ($field[0] =~ /^\d+$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					Carp::carp("Warning: Service: $service_number. Expected RI to be followed by N digits");
				}
			}
			elsif (/^(TA)(\d{2})$/)
			{
				$$self{'_service'}{$service_number}{$1} = $2;
			}
			elsif (/^(TP)(\d{2})$/)
			{
				$$self{'_service'}{$service_number}{$1} = $2;
			}
			elsif ($_ eq 'V')
			{
				if (@field && ($field[0] =~ /^00(1|2)$/) )
				{
					$$self{'_service'}{$service_number}{$_} = shift @field;
				}
				else
				{
					$$self{'_service'}{$service_number}{$_} = '001';
				}
			}
			elsif (/^\d+$/)
			{
				if ($$self{'_service'}{$service_number}{'#'})
				{
					Carp::carp("Warning: Service: $service_number. 2 numbers within options: $_ and $$self{'_service'}{$service_number}{'#'}");
				}
				else
				{
					$$self{'_service'}{$service_number}{'#'} = $_;
				}
			}
			else
			{
				$$self{'_unexpected'}{$_} = 0;
			}
		}	# End of while.
	}	# End of for.

	$$self{'_service'};

}	# End of parse.

# -----------------------------------------------

sub unexpected
{
	my($self) = @_;

	[sort keys %{$$self{'_unexpected'} }];

}	# End of unexpected.

# -----------------------------------------------

1;

=head1 NAME

Data::PABX::ParseLex - Parse output of /lex a e/ command for the iSDC PABX

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Data::Dumper;
	use Data::PABX::ParseLex;

	# -----------------------------------------------

	sub process
	{
		my($parser, $input_file_name) = @_;
		my($hash)                     = $parser -> parse($input_file_name);

		print Data::Dumper -> Dump([$hash], ['PABX']);

	}	# End of process.

	# -----------------------------------------------

	$Data::Dumper::Indent = 1;
	my($parser)           = Data::PABX::ParseLex -> new();

	process($parser, 'pabx-a.txt');
	process($parser, 'pabx-b.txt');

See examples/test-parse.pl for this test program, and the same directory for 2
test data files. The output is in examples/test-parse.log.

Note: My real data has of course been replaced in these files with random numbers.

=head1 Description

C<Data::PABX::ParseLex> is a pure Perl module.

This module reads the output file from the 'lex a e' (List Extensions, All Extensions)
command given to a PABX of type iSDC.

It returns a hash ref keyed by extension.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns an object of type C<Data::PABX::ParseLex>.

This is the class's contructor.

Usage: Data::PABX::ParseLex -> new().

This method takes no parameters.

=head1 Method: parse($input_file_name)

Returns: A hash ref of the data read from the file.

The file is assumed to be the output of the 'lex a e' command issued to a
PABX of type iSDC.

The 'lex a e' command may have been run several times, and the output of all
runs concatenated into the file. This module checks for multiple copies of the
output, and discards all but the last. It does this by looking for the string
/lex a e/i, and deleting all data from the start of the file down to the
record containing this string.

Typical lines in the input file look like:

	EN22433   EC141702    KSGM  CS11  TA07 MOH 000  BE BI RE RI 54103
	Ron S
	DN58903   BC0123      A04  D  TP02    CS31  TA31 MOH 000

where '22433' and '58903' are the extensions.

The other fields on the line are attributes of this extension.

Fields are generated from such lines by splitting the lines on spaces, except for lines such as 'Ron S'.

The line 'Ron S' needs a bit of an explanation. This field is known in this module as the KSGM id.
You see, some lines don't contain extensions. They contain the names people choose to have
appear on the caller's display. 'Ron S' is such an id. The KSGM id may be blank.

The keys of the returned hash are the 4 or 5 digit extensions.

Each of these keys points to another hash ref with the following keys (listed in alphabetical order):

=over 4

=item o ksgm_id

This would be 'Ron S' above.

=item o number_type

This comes from the first 2 characters of each line containing an extension.

This would be 'EN' in the first line above, and 'DN' in the third line.

=item o pabx_card_type

This would be 'EC' from the field 'EC141702' above.

Typical values: AC, BC, DI, EC, IE, OC.

=item o pabx_port

When the pabx_card_type is AC, EC, IE or OC, this field consists of three sub-fields of 2 digits each:

=over 4

=item o Shelf

=item o Slot

=item o Access

=back

This would be '141702' from the field 'EC141702' above.

When the pabx_card_type is BC or DI, this field consists of one field of 4 digits.

This would be '0123' from the field 'BC0123' above.

If the pabx_card_type is none of the above, then both the pabx_card_type and the pabx_port
are set to '-'.

The remaining fields on each line are options, and are stored thus:

=item o *

Store as key '*' and value '1'.

=item o $

Store as key '$' and value '1'.

=item o /A\s+(0\d)/

Store as key 'A' and value $1.

=item o ACD

Store as key 'ACD' and value 'QUEUE'.

=item o AGENT

Store as key 'AGENT' and value 'GROUP'.

=item o /(BE|BI|DG|HG|IE|KSGM?|MULT|RE|SPARE)/

Store as key $1 and value '1'.

=item o /CS\s+(\d{2})/

Store as key 'CS' and value $1.

This is the Class of Service attribute.

=item o /D\s+(00(1|2))/

Store as key 'D' and value $1.

=item o /II\s+(\d+)/

Store as key 'II' and value $1.

=item o /MLG\s+(\d+)/

Store as key 'MLG' and value $1.

=item o /MOH\s+000/

Store as key 'MOH' and value '000' (Zeros).

=item o /OG\s+(\d+)/

Store as key 'OG' and value $1.

=item o /RI\s+(\d+)/

Store as key 'RI' and value $1.

With RI and some other options, the parsing is a little bit slack, in that several
options can be combined and followed by a single extension, which is what the \d+
is with RI. Since I did not need to process such data, I have not bothered to combine
such options with the single trailing extension.

=item o /TA\s+(\d{2})/

Store as key 'TA' and value $1.

=item o /TP\s+(\d{2})/

Store as key 'TP' and value $1.

=item o /V\s+(00(1|2))/

Store as key 'V' and value $1.

Where 'V' is not followed by '00\d', the value used is '001'.

=item o /(\d+)/

Store as key '#' and value $1.

=item o Any other string

Store the string as the key in another internal hash, together with the value 0.

The keys in this hash can be returned, sorted, by calling the method C<unexpected()>.

=back

=head1 Method: C<parse($input_file_name)>

Parse the given file and return a hash ref as documented in the previous section.

=head1 Method: C<unexpected()>

Return, sorted, the keys of the hash holding extension attributes not recognized
by any of the above patterns.

=head1 Author

C<Data::PABX::ParseLex> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>>
in 2005.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
