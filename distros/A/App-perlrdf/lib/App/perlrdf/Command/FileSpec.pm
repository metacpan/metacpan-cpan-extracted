package App::perlrdf::Command::FileSpec;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::FileSpec::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::FileSpec::VERSION   = '0.006';
}

use App::perlrdf -command;

use namespace::clean;

use constant abstract      => q (Shows help on how to use "file specifications");
use constant command_names => qw( filespec );
use constant description   => <<'DESCRIPTION';
FileSpecs are an App::perlbrew microsyntax for specifying input and output
data streams. Various commands expect to be given filespecs so that they know
what files, URLs or streams to operate on.

FileSpecs have a two part syntax. They start with an optional JSON-like
options specification, and are followed by a (non-optional) file name, URL or
dash. Some examples:

    {format:RDFXML}C:\Data\Countries.rdfx
    http://www.example.com/data.rdf
    {format:"Turtle",base:"http://www.example.net/"}-

The optional JSON-like part is a list of key-value pairs, where pairs are
separated with commas, and keys are seperated from values with colons. Keys
and values must be quoted with single or double quotes if they contain
"non-word" characters (i.e. /\W/). No escaping is available. There are no
nested data structures.

The following keys are currently defined:

    format   - file format (media type, format name or parser class)
    base     - base URI

Additional keys are currently ignored, available for future use.

The second part may be a relative or absolute filename which will be
converted into a URI; or may be an absolute URI in any supported URI scheme;
or may be a dash, which is treated as STDIN or STDOUT depending on context.

Supported URI schemes include any URI scheme which can be used for GET
requests by LWP::UserAgent, including http, https, data, file, ftp, gopher
and nntp; and pseudo-schemes cpan, loopback and nogo. App::perlrdf also
supports pseudo-schemes stdin, stdout and stderr.

So for example, to write Turtle to STDERR:

    perlrdf translate -i mydata.rdf -o "{format:Turtle}stderr:"

The 'translate' command allows you to specify input our output as either a
filename or a file spec, using different parameters for each:

    perlrdf translate --input=FILE --output-spec=SPEC
    perlrdf translate --input-spec=SPEC --output=FILE
    perlrdf translate -I SPEC -O SPEC
    perlrdf translate -i FILE -o FILE -O SPEC

If you want to test FileSpecs, you can run:

    perlrdf filespec SPEC1 SPEC2 ...
DESCRIPTION
use constant opt_spec      => qw();
use constant usage_desc    => '%c filespec';

sub execute
{
	my ($class, $opt, $args) = @_;
	
	if (@$args)
	{
		require App::perlrdf::FileSpec;
		say
			App::perlrdf::FileSpec->new_from_filespec($_)->TO_JSON(1),
			for @$args;
	}
	else
	{
		say $class->description;
	}
}

1;

