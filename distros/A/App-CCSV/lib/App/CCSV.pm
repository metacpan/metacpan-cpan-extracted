package App::CCSV;

use strict;
use Data::Dumper;
use App::CCSV::TieCSV;
use Text::CSV_XS;
use Config::General;
require Exporter;
our @ISA = qw(Exporter);

our $csv;
our $csvout;

our @EXPORT = qw(cprint csay parse $csv);

our $VERSION = 0.02;

sub import 
{
	my $name = shift;
	_init(@_);
	__PACKAGE__->export_to_level(1,1,qw(csay cprint parse $csv));
	tie *ARGV, 'TieCSV',$csv;
}

sub _init
{
	my $out = length($_[-1] || '') > 1 && $#_ > 0 ? pop : ''; # last argument length > 1 means csvout config section if more than 1 argument
	my ($quote,$sep,$escape,$eol) = @_;
	#print join "|", ($quote, $sep, $escape, $eol,"\n");
	my $cfgfile = $ENV{CCSVCONF} || $ENV{HOME} || '~';
	$cfgfile = $cfgfile . '/.CCSVConf' unless $ENV{CCSVCONF};
	if (length($quote || '') <= 1) # length > 1 specifies config section
	{
		$csv = Text::CSV_XS->new( {
        	        quote_char => $quote || '"',
                	sep_char => $sep || ',',
	                escape_char => $escape || '"',
        	        eol => $eol || '',
			binary => 1,
       		} ); 
	} else
	{
		$csv = Text::CSV_XS->new(); # config later from cfgfile
	}
	if (-r $cfgfile)
	{
		my $conf = new Config::General($cfgfile);
		my %config = $conf->getall;
		# CSV:
		if (!@_ || ($#_ == 0 and $quote eq '')) # no override(s) from command line
		{
			_confme($csv,$config{CCSV}) if $config{CCSV};
		} elsif (length($quote) > 1) # config section
		{
				die "no config section with name <$quote> could be found in $cfgfile\n" unless $config{CCSV}->{names}->{$quote};
				_confme($csv,$config{CCSV}->{names}->{$quote});
		}

		_confme($csv,$config{CCSV}->{overrideall}) if $config{CCSV}->{overrideall}; 
		# different CSVOUT?
		if ($out) # get from config section
		{
			 die "no config section with name <$out> could be found in $cfgfile\n" unless $config{CCSV}->{names}->{$out};
			 $csvout = Text::CSV_XS->new(); 
			 _confme($csvout,$config{CCSV}->{names}->{$out});
		} elsif ($config{CCSV}->{out})
		{
			$csvout = Text::CSV_XS->new();
			_confme($csvout,$config{CCSV}->{out});
		}
	} else # die if config file is needed but not present:
	{
		die "1st param char length > 1 means input config section, but no readable config file could be found at $cfgfile \n" if (length($quote || '') > 1);
		 die "last param length > 1 means output config section, but no readable config file could be found at $cfgfile\n" if (length($out || '') > 1);
	}
}

sub _confme
{
	# ($csv,$conf);
	my $conf = $_[1];
	for my $key (keys %{$conf})
	{
	 	next if ($key eq 'overrideall' or $key eq 'out' or $key eq 'names');
		$_[0]->$key($conf->{$key});
	}
}

sub cprint
{
	if ($csvout)
	{
		$csvout->combine(@_);
		print $csvout->string();

	} else
	{
		$csv->combine(@_);
		print $csv->string();
	}
}

sub csay
{
	cprint(@_);
	print $/;
}

sub parse
{
	my $line = shift;
	$csv->parse($line || $_);
	return $csv->fields();
}

1;


__END__

=pod

=head1 NAME

App::CCSV - Command line "auto split" for easy working on CSV files via perl -ne

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	# similar to @F in perl's autosplit switch (perl -a ..),
	# an array @f will give you access to the fields of the current line of a CSV file
	:~$ perl -MApp::CCSV -ne 'print @f' < some.csv

	# you can pass definitions of your CSV file, like quote char, delimiter, etc.
	# as options to the module
	:~$ perl -MApp::CCSV=",; -ne 'print @f' < some.csv

	# you can create a config file with CSV definitions 
	# and pass them as named configs to the module
	:~$ perl -MApp::CCSV=tabs -ne 'print @f' < some.csv
	:~$ perl -MApp::CCSV=foo -ne 'print @f' < some.csv

	# useful methods are exported,
	# like printing an array as a CSV line
	:~$ perl -MApp::CCSV=foo -ne 'cprint @f[2,3,-1]' < some.csv

	# input and output CSV definitions can be configured separately
	# this will convert a CSV file from one definition to another
	:~$ perl -MApp::CCSV=in,out -ne 'cprint @f' < some.csv

=head1 DESCRIPTION

This module provides easy access to field values of a CSV file for quick manipulation through shell one-liners, similar to perl's autosplit feature (C<perl -ane>). Parsing and easy printing of CSV files are supported.

Similar to the array C<@F> when using C<perl -a>, an array C<@f> is provided, holding the field values of the current line of your CSV (iterated through C<perl -n>).

=head1 EXPORTS

The array C<@f>, which will hold the field values of the CSV, the functions C<cprint()>, C<csay()>, C<parse()>, and the L<Text::CSV_XS> objects C<$csv> and C<$csvout> will be exported by default.

C<$csv> will be initialized with your config for the CSV input, C<$csvout> for the CSV output. In case you haven't specified any configs, C<$csv> and C<$csvout> will be initialized as this:

	Text::CSV_XS->new( {
		quote_char => '"',
        	sep_char => ',',
	        escape_char '"',
	        eol => '',
	        binary => 1,
	} );

Note that these are slightly different from the L<Text::CSV_XS> defaults.

=head1 FUNCTIONS

=over 4

=item cprint(@array)

prints a CSV line according to the specified CSV output configuration.

=item csay(@array)

like C<cprint()>, with an added newline at the end (actually, the value of C<$/> is printed at the end of the line).

=item parse($string)

parses C<$string> according to the current input CSV configuration, and returns the fields as an array. Note that you will hardly need that function, as you will have the fields of the current line in C<@f> automatically  - this function is here "just in case".

=back

=head1 CONFIGURATION

You can configure CSV quote char, separator, escape char and end of line char by passing them directly to the module, like this:

	:~$ perl -MApp::CCSV=<quote char>,<sep char>,<escape char>,<eol char> -ne 'print @f' < some.csv

Note that these are really limited to one character. More than one character would mean a config section in the config file (more about the config file in a moment).

If you don't specify any options, the defaults shown under "EXPORTS" will be used.

Any of the characters can be skipped, in which case the defaults will be used. For instance, setting only the escape char to for example "@" will look like this:

	:~$ perl -MApp::CCSV=,,@ -ne 'print @f' < some.csv

=head1 CONFIG FILE

App::CCSV expects a config file in any format L<Config::General> understands.

There are two ways of setting a config file. Firstly, APP::CCSV will look for a config file in your environment variable C<$ENV{CCSVCONF}>. 

Secondly, if this variable is not set, App:CCSV will look for a file called .CCSVConf in your home directory. If there is none, it falls back to defaults. An example .CCSVConf file is included in the examples directory of this distribution.

At the moment, all that's configurable is the behavior of L<Text::CSV_XS>. Have a look at L<Text::CSV_XS> to examine which functions there are to choose from.

A line in the config file consists of a L<Text::CSV_XS> function, and the parameter passed to it.

For instance, if you want to configure sep_char ; and quote_char " as defaults, it could look like this:

	<CCSV>
	sep_char   ;
	quote_char """
	</CCSV>

Note that App::CCSV will always need and only look up a CCSV section in your config file.

App::CCSV will then expect and output a CSV file, unless you override this by passing different parametes in the module call.

A default output config can also be configured, via an "out" section in the config file:

	<CCSV>
	sep_char   ;
	quote_char """
	<out>
	  sep_char ,
	  quote_char """	
	</out>
	</CCSV>

App::CCSV will also understand named config sections. These must be defined in a "names" section in the config file. For instance, you can specify a named config for the popular tab-delimited CSV format like this:

	<CCSV>
	sep_char   ;
	quote_char """
	<names>
	  <tabs>
	    sep_char "	"
	    quote_char """	
	  </tabs>
	</names>
	</CCSV>

Then it is possible to pass this config name in the module call:

	:~$ perl -MApp::CCSV=tabs -ne 'print @f' < some.csv

Note that a config name must be at least 2 characters long, otherwise L<Text::CSV_XS> will think of it as a quote char.

The above call configures the CSV parser for input and output, if there is no default output config.

For output options, a second named config section can be passed to the module:

	:~$ perl -MApp::CCSV=tabs,foo -ne 'csay @f' < some.csv 

This will use the "tabs" config for input and "foo" for output, so the above example will convert a tab-delimited format to a "foo" format, defined at your leisure.

The output config will always be taken from the last passed parameter, if it is more than 1 character long. So

	:~$ perl -MApp::CCSV=,tabs -ne 'csay @f' < some.csv 

will use default settings for input and the "tabs" config for output.

Finally, you can also specify a parameter set that you can't override, by entering a section called "overrideall" in your config file. For instance

	<CCSV>
	...
	<overrideall>
		binary	0
	</overrideall>
	</CCSV>

will always use C<binary =E<gt> 0> for L<Text::CSV_XS>, even if you use a named config that said otherwise.

=head1 EXAMPLES

First, and probably most important if you contemplate "everyday use" of this module, it might get tedious to type "App::CCSV" all the time - so a shorter module name would be desirable!

You will find a file "CL.pm" (for CommandLine) included in the examples directory of this distribution. Copy it somewhere your perl installation can find it. After this it will be possible to replace 

	:~$ perl -MApp::CCSV -ne 'print @f' < some.csv

with 

	:~$ perl -MCL -ne 'print @f' < some.csv

but take care here, especially if you want do that system-wide, as it is possible that this may collide with other installed modules!

Having said this, you will find some real-world examples below.

	# Printing the sum of a particular field's values:
	:~$ perl -MApp::CCSV -lne '$sum+=$f[4]; END{print $sum}' < csv.csv

	# Extracting lines that match certain criteria:
	:~$ perl -MApp::CCSV -lne 'print if $f[4] =~ /^John/ and $f[5] !~ /^Doe/' < csv.csv

	# Extracting unique field values:
	:~$ perl -MApp::CCSV -lne '$v{$f[3]}=1; END{print for keys %v}' < csv.csv

	# Adding data, storing in a new CSV:
	:~$ perl -MApp::CCSV -ne '$sum=$f[1]+$f[4]; csay @f,$sum' < csv.csv > csv2.csv

	# Extracting some values from your CSV, storing them in a new CSV:
	:~$ perl -MApp::CCSV -ne 'csay @f[1,4,7,22]' < csv.csv > csv2.csv

	# Easy checking if there are field values that contain the quote char -
	# means, checking if you can get by with normal autosplit or if you really have
	# to treat your file as CSV (this example works from perl 5.10 onwards):
	:~$ perl -MApp::CCSV -F/\;/ -lanE 'say if !(@f ~~ @F)' < csv.csv


=head1 SEE ALSO

L<Text::CSV_XS>, L<Config::General>, L<perlrun>

=head1 BUGS

There surely are ...

Please send bug reports or feature requests to Karlheinz Zoechling <kh at ibeatgarry dot com>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Karlheinz Zoechling. All rights reserved.

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
