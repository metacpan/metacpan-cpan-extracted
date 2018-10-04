=head1 NAME

Astro::SIMBAD::Client - Fetch astronomical data from SIMBAD 4.

=head1 SYNOPSIS

 use Astro::SIMBAD::Client;
 my $simbad = Astro::SIMBAD::Client->new ();
 print $simbad->query (id => 'Arcturus');

=head1 NOTICE

As of release 0.027_01 the SOAP interface is deprecated. The +University
of Strasbourg has announced at
+L<http://cds.u-strasbg.fr/resources/doku.php?id=soap> that this
+interface will not be maintained after April 1 2014, and that +B<this
interface will be stopped on December 31 2018>.

Because the SOAP interface is still sort of functional (except for
VO-format queries) as of June 4 2014, I have revised the transition plan
announced with the release of 0.027_01 on October 28 2014.

What I have done as of version 0.031_01 is to add attribute
C<emulate_soap_queries>. This is false by default. If this attribute is
true, the C<query()> method and friends, instead of issuing a SOAP
request to the SIMBAD server, will instead construct an equivalent
script query, and issue that. The deprecation warning will not be issued
if C<emulate_soap_queries> is true, since the SOAP interface is not
being used.

I intend to make the default value of C<emulate_soap_queries> true in
the first release on or after October 1 2014, assuming SOAP queries work
for that long.

When the SOAP servers go out of service (and I notice) SOAP queries will
become fatal, and the default value of C<emulate_soap_queries> will
become true if it is not already.

Eventually the SOAP code will be removed. In the meantime all tests are
marked TODO, and support of SOAP by this module will be on a best-effort
basis; that is, if I can make it work without a huge amount of work I
will -- otherwise SOAP will become unsupported.

=head1 DESCRIPTION

This package implements several query interfaces to version 4 of the
SIMBAD on-line astronomical database, as documented at
L<http://simbad.u-strasbg.fr/simbad4.htx>. B<This package will not work
with SIMBAD version 3.> Its primary purpose is to obtain SIMBAD data,
though some rudimentary parsing functionality also exists.

There are three ways to access these data.

- URL queries are essentially page scrapers, but their use is
documented, and output is available as HTML, text, or VOTable. URL
queries are implemented by the url_query() method.

- Scripts may be submitted using the script() or script_file() methods.
The former takes as its argument the text of the script, the latter
takes a file name.

- Queries may be made using the web services (SOAP) interface. The
query() method implements this, and queryObjectByBib,
queryObjectByCoord, and queryObjectById have been provided as
convenience methods. As of version 0.027_01, SOAP queries are
deprecated. See the L<NOTICE|/NOTICE> section above for the deprecation
schedule.

Astro::SIMBAD::Client is object-oriented, with the object supplying not
only the URL scheme and SIMBAD server name, but the default format and
output type for URL and web service queries.

A simple command line client application is also provided, as are
various examples in the F<eg> directory.

=head2 Methods

The following methods should be considered public:

=over 4

=cut

package Astro::SIMBAD::Client;

# We require Perl 5.008 because of MailTools, used by SOAP::Lite.
# Otherwise it would be 5.006 because of 'our'.

use 5.008;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use LWP::Protocol;
use HTTP::Request::Common qw{POST};
use Scalar::Util 1.01 qw{looks_like_number};
use URI::Escape ();
use XML::DoubleEncodedEntities;
# use Astro::SIMBAD::Client::WSQueryInterfaceService;

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};

my $have_time_hires;
BEGIN {
    $have_time_hires = eval {
	require Time::HiRes;
	Time::HiRes->import (qw{time sleep});
	1;
    };

    *_escape_uri = URI::Escape->can( 'uri_escape_utf8' )
	|| URI::Escape->can( 'uri_escape' )
	|| sub { return $_[0] };
}

our $VERSION = '0.038';

our @CARP_NOT = qw{Astro::SIMBAD::Client::WSQueryInterfaceService};

# TODO replace this with s///r if we ever get to the point where we
# require Perl 5.13.2 or greater.
sub _strip_returns {
    my ( $data ) = @_;
    $data =~ s/ \n //smxg;
    return $data;
}

use constant FORMAT_TXT_SIMPLE_BASIC => _strip_returns( <<'EOD' );
---\n
name: %IDLIST(NAME|1)\n
type: %OTYPE\n
long: %OTYPELIST\n
ra: %COO(d;A)\n
dec: %COO(d;D)\n
plx: %PLX(V)\n
pmra: %PM(A)\n
pmdec: %PM(D)\n
radial: %RV(V)\n
redshift: %RV(Z)\n
spec: %SP(S)\n
bmag: %FLUXLIST(B)[%flux(F)]\n
vmag: %FLUXLIST(V)[%flux(F)]\n
ident: %IDLIST[%*,]
EOD

use constant FORMAT_TXT_YAML_BASIC => _strip_returns( <<'EOD' );
---\n
name: '%IDLIST(NAME|1)'\n
type: '%OTYPE'\n
long: '%OTYPELIST'\n
ra: %COO(d;A)\n
dec: %COO(d;D)\n
plx: %PLX(V)\n
pm:\n
  - %PM(A)\n
  - %PM(D)\n
radial: %RV(V)\n
redshift: %RV(Z)\n
spec: %SP(S)\n
bmag: %FLUXLIST(B)[%flux(F)]\n
vmag: %FLUXLIST(V)[%flux(F)]\n
ident:\n%IDLIST[  - '%*'\n]
EOD

#	Documentation errors/omissions:
#	%PLX:
#	     P = something. Yields '2' for Arcturus
#	%SP: is really %sptype
#	     B = bibcode? Yields '~' for Arcturus
#	     N = don't know -- yields 'S' for Arcturus
#	     Q = quality? Yields 'C' for Arcturus
#	     S = spectral type

use constant FORMAT_VO_BASIC => join ',', qw{
    id(NAME|1) otype ra(d) dec(d) plx_value pmra pmdec rv_value z_value
    sp_type flux(B) flux(V)};
    # Note that idlist was documented at one point as being the
    # VOTable equivalent of %IDLIST. But it is no longer documented,
    # and never returned anything but '<TD>?IDLIST</TD>'.

my %static = (
    autoload => 1,
    debug => 0,
    delay => 3,
    emulate_soap_queries	=> 0,
    format => {
	txt => FORMAT_TXT_YAML_BASIC,
	vo => FORMAT_VO_BASIC,
	script => '',
    },
    parser => {
	txt => '',
	vo => '',
	script => '',
    },
    post => 1,
    # lc(...) per https://tools.ietf.org/html/rfc3986#section-3.1
    scheme => lc( $ENV{ASTRO_SIMBAD_CLIENT_SCHEME} || 'http' ),
##    server => 'simbad.u-strasbg.fr',
    server => $ENV{ASTRO_SIMBAD_CLIENT_SERVER} || 'simbad.u-strasbg.fr',
    type => 'txt',
    url_args => {},
    verbatim => 0,
);

if ( my $msg = _is_scheme_valid(
	$static{scheme},
	q<Unsupported ASTRO_SIMBAD_CLIENT_SCHEME '%s'; falling back to 'http'>,
    ) ) {
    carp $msg;
    $static{scheme} = 'http';
}

=item $simbad = Astro::SIMBAD::Client->new ();

This method instantiates an Astro::SIMBAD::Client object. Any arguments will be
passed to the set() method once the object is instantiated.

=cut

# The set() method does the unpacking. CAVEAT: do _NOT_ modify the
# contents of @_, as this will be seen by the caller. Modifying @_
# itself is fine.
sub new {	## no critic (RequireArgUnpacking)
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self->set (%static, @_);
    return $self;
}

=item $string = $simbad->agent ();

This method retrieves the user agent string used to identify this
package in queries to SIMBAD. This string will be the default string for
LWP::UserAgent, with this package name and version number appended in
parentheses. This method is exposed for the curious.

=cut

{
    my $agent_string;
    sub agent {
	return ($agent_string ||= join (' ', LWP::UserAgent->_agent,
	    __PACKAGE__ . '/' . $VERSION));
    }
}

=item @attribs = $simbad->attributes ();

This method retrieves the names of all public attributes, in
alphabetical order. It can be called as a static method, or
even as a subroutine.

=cut

sub attributes {
    return wantarray ? sort keys %static : [sort keys %static]
}

=item $value = $simbad->get ($attrib);

This method retrieves the current value of the named
L<attribute|/Attributes>. It can be called as a static method to
retrieve the default value.

=cut

sub get {
    my $self = shift;
    croak "Error - First argument must be an @{[__PACKAGE__]} object"
	unless eval {$self->isa(__PACKAGE__)};
    $self = \%static unless ref $self;
    my $name = shift;
    croak "Error - Attribute '$name' is unknown"
	unless exists $static{$name};
    return $self->{$name};
}

=item $result = Parse_TXT_Simple ($data);

This subroutine (B<not> method) parses the given text data under the
assumption that it was generated using FORMAT_TXT_SIMPLE_BASIC or
something similar. The data is expected to be formatted as follows:

A line consisting of exactly '---' separates objects.

Data appear on lines that look like

 name: data

and are parsed into a hash keyed by the given name. If the line ends
with a comma, it is assumed to contain multiple items, and the data
portion of the line is split on the commas; the resultant hash value
is a list reference.

The user would normally not call this directly, but specify it as the
parser for 'txt'-type queries:

 $simbad->set (parser => {txt => 'Parse_TXT_Simple'});

=cut

sub Parse_TXT_Simple {
    my $text = shift;
    my $obj = {};
    my @data;
    foreach (split '\s*\n', $text) {
	next unless $_;
	if (m/^-+$/) {
	    $obj = {};
	    push @data, $obj;
	} else {
	    my ($name, $val) = split ':\s*', $_;
	    $val =~ s/,$// and $val = [split ',', $val];
	    $obj->{$name} = $val;
	}
    }
    return @data;
}


=item $result = Parse_VO_Table ($data);

This subroutine (B<not> method) parses the given VOTable data,
returning a list of anonymous hashes describing the data. The $data
value is split on '<?xml' before parsing, so that you get multiple
VOTables back (rather than a parse error) if that is what the input
contains.

This is B<not> a full-grown VOTable parser capable of handling
the full spec (see L<http://www.ivoa.net/Documents/latest/VOT.html>).
It is oriented toward returning E<lt>TABLEDATAE<gt> contents, and the
metadata that can reasonably be associated with those contents.

B<NOTE> that as of version 0.026_01, the requisite modules
to support VO format are B<not> required. If you need VO format you will
need to install L<XML::Parser|XML::Parser> or L<XML::Parser::Lite>

The return is a list of anonymous hashes, one per E<lt>TABLEE<gt>. Each
hash contains two keys:

  {data} is the data contained in the table, and
  {meta} is the metadata for the table.

The {meta} element for the table is a reference to a list of data
gathered from the E<lt>TABLEE<gt> tag. Element zero is the tag name
('TABLE'), and element 1 is a reference to a hash containing the
attributes of the E<lt>TABLEE<gt> tag. Subsequent elements if any
represent metadata tags in the order encountered in the parse.

The {data} contains an anonymous list, each element of which is a row of
data from the E<lt>TABLEDATAE<gt> element of the E<lt>TABLEE<gt>, in the
order encountered by the parse. Each row is a reference to a list of
anonymous hashes, which represent the individual data of the row, in the
order encountered by the parse. The data hashes contain two keys:

 {value} is the value of the datum with undef for '~', and
 {meta} is a reference to the metadata for the datum.

The {meta} element for a datum is a reference to the metadata tag that
describes that datum. This will be an anonymous list, of which element 0
is the tag ('FIELD'), element 1 is a reference to a hash containing that
tag's attributes, and subsequent elements will be the contents of the
tag (typically including a reference to the list representing the
E<lt>DESCRIPTIONE<gt> tag for that FIELD).

All values are returned as provided by the XML parser; no further
decoding is done. Specifically, the datatype and arraysize attributes
are ignored.

This parser is based on XML::Parser.

The user would normally not call this directly, but specify it as the
parser for 'vo'-type queries:

 $simbad->set (parser => {vo => 'Parse_VO_Table'});

=cut

{	# Begin local symbol block.

    my $xml_parser;

    # TODO get rid of XML::Parser::Lite when you get rid of SOAP
    foreach (qw{XML::Parser XML::Parser::Lite}) {
	eval { _load_module( $_ ); 1 } or next;
	$xml_parser = $_;
	last;
    }

    sub Parse_VO_Table {
	my $data = shift;

	defined $xml_parser
	    or croak 'Error - No XML parser available. Need XML::Parser or XML::Parser::Lite';

	my $root;
	my @tree;
	my @table;
	my @to_strip;

#	Arguments:
#	Init ($class)
#	Start ($class, $tag, $attr => $value ...)
#	Char ($class, $text)
#	End ($class, $tag)
#	Final ($class)

	my $psr = $xml_parser->new (
	    Handlers => {
		Init => sub {
		    $root = [];
		    @tree = ($root);
		    @table = ();
		},
		Start => sub {
		    shift;
		    my $tag = shift;
		    my $item = [$tag, {@_}];
		    push @{$tree[-1]}, $item;
		    push @tree, $item;
		},
		Char => sub {
		    push @{$tree[-1]}, $_[1];
		},
		End => sub {
		    my $tag = $_[1];
		    die <<eod unless @tree > 1;
Error - Unmatched end tag </$tag>
eod
		    die <<eod unless $tag eq $tree[-1][0];
Error - End tag </$tag> does not match start tag <$tree[-1][0]>
eod

#	From here to the end of the subroutine is devoted to detecting
#	the </TABLE> tag and extracting the data of the table into what
#	is hopefully a more usable format. Any relationship of tables
#	to resources is lost.

		    my $element = pop @tree;
		    if ($element->[0] eq 'TABLE') {
			my (@meta, @data, @descr);
			foreach (@$element) {
			    next unless ARRAY_REF eq ref $_;
			    if ($_->[0] eq 'FIELD') {
				push @meta, $_;
				push @descr, $_;
			    } elsif ($_->[0] eq 'DATA') {
				foreach (@$_) {
				    next unless ARRAY_REF eq ref $_;
				    next unless $_->[0] eq 'TABLEDATA';
				    foreach (@$_) {
					next unless ARRAY_REF eq ref $_;
					next unless $_->[0] eq 'TR';
					my @row;
					foreach (@$_) {
					    next unless ARRAY_REF eq ref $_;
					    next unless $_->[0] eq 'TD';
					    my @inf = grep {!ref $_} @$_;
					    shift @inf;
					    push @row, join ' ', @inf;
					}
					push @data, \@row;
				    }
				}
			    } else {
				push @descr, $_;
			    }
			}
			foreach (@data) {
			    my $inx = 0;
			    @$_ = map { {
				    value => (defined $_ && $_ eq '~')
					? undef : $_,
				    meta => $meta[$inx++],
				} } @$_;
			}
			push @to_strip, @descr;
			push @table, {
			    data => \@data,
			    meta => [$element->[0],
				$element->[1], @descr],
			};
		    }
		},
		Final => sub {
		    die <<eod if @tree > 1;
Error - Missing end tags.
eod

##		    _strip_empty ($root);
##		    @$root;
#	If the previous two lines were uncommented and the following two
#	commented, the parser would return the parse tree for the
#	VOTable.
		    _strip_empty (\@to_strip);
		    @table;
		},
	    });
	return map {$_ ? $psr->parse ($_) : ()} split '(?=<\?xml)', $data
    }

}	# End of local symbol block.

#	_strip_empty (\@tree)
#
#	splices out anything in the tree that is not a reference and
#	does not match m/\S/.

sub _strip_empty {
    my $ref = shift;
    my $inx = @$ref;
    while (--$inx >= 0) {
	my $val = $ref->[$inx];
	my $typ = ref $val;
	if ( ARRAY_REF eq $typ ) {
	    _strip_empty ($val);
	} elsif (!$typ) {
	    splice @$ref, $inx, 1 unless $val =~ m/\S/ms;
	}
    }
    return;
}

=item $result = $simbad->query ($query => @args);

This method is B<deprecated>, and will cease to work in April 2014.
Please choose a method that does not use SOAP. See the L<NOTICE|/NOTICE>
above for details.

This method issues a web services (SOAP) query to the SIMBAD database.
The $query specifies a SIMBAD query method, and the @args are the
arguments for that method. Valid $query values and the corresponding
SIMBAD methods and arguments are:

  bib => queryObjectByBib ($bibcode, $format, $type)
  coo => queryObjectByCoord ($coord, $radius, $format, $type)
  id => queryObjectById ($id, $format, $type)

where:

  $bibcode is a SIMBAD bibliographic code
  $coord is a set of coordinates
  $radius is an angular radius around the coordinates
  $type is the type of data to be returned
  $format is a format appropriate to the data type.

The $type defaults to the value of the L<type|/type> attribute, and
the $format defaults to the value of the L<format|/format> attribute
for the given $type.

The return value depends on a number of factors:

If the query found nothing, you get undef in scalar context, and an
empty list in list context.

If a L<parser|/parser> is defined for the given type, the returned
data will be fed to the parser, and the output of the parser will be
returned. This is assumed to be a list, so a reference to the list
will be used in scalar context. Parser exceptions are not trapped,
so the caller will need to be prepared to deal with malformed data.

Otherwise, the result of the query is returned as-is.

B<NOTE> that this functionality makes use of the
L<SOAP::Lite|SOAP::Lite> module. As of version 0.026_01 of
C<Astro::SIMBAD::Client>, L<SOAP::Lite|SOAP::Lite> is not a prerequisite
of this module. If you wish to use the C<query()> method, you will have
to install L<SOAP::Lite|SOAP::Lite> separately. This can be done after
C<Astro::SIMBAD::Client> is installed.

=cut

{	# Begin local symbol block

    my %query_args = (
	id => {
	    type => 2,
	    format => 1,
	    method => 'queryObjectById',
	},
	bib => {
	    type => 2,
	    format => 1,
	    method => 'queryObjectByBib',
	},
	coo => {
	    type => 3,
	    format => 2,
	    method => 'queryObjectByCoord',
	},
    );

    my %transform = (
	txt => sub {
	    local $_ = $_[0];
	    s/\n//gm;
	    return $_
	},
	vo => sub {
	    local $_ = ref $_[0] ? join (',', @{$_[0]}) : $_[0];
	    if ( defined $_ ) {
		s/\s+/,/gms;
		s/^,+//;
		s/,+$//;
		s/,+/,/g;
	    }
	    return $_
	},
    );

    my %make_script = (
	txt	=> sub {
	    my ( $self, $query, @args ) = @_;
	    return <<"EOD";
format object "@{[ $transform{txt}->( $self->get( 'format' )->{txt} ) ]}"
query $query @args
EOD
	},
	vo	=> sub {
	    my ( $self, $query, @args ) = @_;
	    return <<"EOD";
votable myvo {
@{[ $transform{vo}->( $self->get( 'format' )->{vo} ) ]}
}
votable open myvo
query $query @args
votable close myvo
EOD
	},
    );

    sub query {
	my ( $self, $query, @args ) = @_;
	if ( $self->get( 'emulate_soap_queries' ) ) {
	    my $type = $self->get( 'type' );
	    my $code = $make_script{$type} || sub {
		my ( undef, $query, @args ) = @_;	# Invocant unused
		return "query $query @args\n";
	    };
	    return $self->_script(
		parser	=> $type,
		script	=> $code->( $self, $query, @args ),
		verbatim	=> 0,
	    );
	}
	$self->_deprecation_notice( method => 'query', 'a non-SOAP method' );
	eval { _load_module( 'SOAP::Lite' ); 1 }
	    or croak 'Error - query() requires SOAP::Lite';
	eval { _load_module(
		'Astro::SIMBAD::Client::WSQueryInterfaceService' ); 1 }
	    or croak "Programming Error - Can not load Astro::SIMBAD::Client::WSQueryInterfaceService: $@";
	croak "Error - Illegal query type '$query'"
	    unless $query_args{$query};
	my $method = $query_args{$query}{method};
	croak "Programming error - Illegal query $query method $method"
	    unless Astro::SIMBAD::Client::WSQueryInterfaceService->can ($method);
	my $debug = $self->get ('debug');
	my $parser;
	if (defined (my $type = $query_args{$query}{type})) {
	    $args[$type] ||= $self->get ('type');
	    if (defined (my $format = $query_args{$query}{format})) {
		$args[$format] ||= $self->get ('format')->{$args[$type]};
		$args[$format] = $transform{$args[$type]}->($args[$format])
		    if $transform{$args[$type]};
		warn "$args[$type] format: $args[$format]\n" if $debug;
		$args[$format] = undef unless $args[$format];
	    }
	    $parser = $self->_get_parser ($args[$type]);
	}
	SOAP::Lite->import (+trace => $debug ? 'all' : '-all');
	$self->_delay ();
##	$debug and SOAP::Trace->import ('all');
	my $resp = Astro::SIMBAD::Client::WSQueryInterfaceService->$method(
	    $self, @args);
	return unless defined $resp;
	$resp = XML::DoubleEncodedEntities::decode ($resp);
	return wantarray ? ($parser->($resp)) : [$parser->($resp)]
	    if $parser;
	return $resp;
    }

}	# End local symbol block.


=item $value = $simbad->queryObjectByBib ($bibcode, $format, $type);

This method is B<deprecated>, and will cease to work on December 31
2018. Please choose a method that does not use SOAP. See the
L<NOTICE|/NOTICE> above for details.

This method is just a convenience wrapper for

 $value = $simbad->query (bib => $bibcode, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectByBib {
    my $self = shift;
    return $self->query (bib => @_);
}

=item $value = $simbad->queryObjectByCoord ($coord, $radius, $format, $type);

This method is B<deprecated>, and will cease to work on December 31
2018. Please choose a method that does not use SOAP. See the
L<NOTICE|/NOTICE> above for details.

This method is just a convenience wrapper for

 $value = $simbad->query (coo => $coord, $radius, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectByCoord {
    my $self = shift;
    return $self->query (coo => @_);
}

=item $value = $simbad->queryObjectById ($id, $format, $type);

This method is B<deprecated>, and will cease to work on December 31
2018. Please choose a method that does not use SOAP. See the
L<NOTICE|/NOTICE> above for details.

This method is just a convenience wrapper for

 $value = $simbad->query (id => $id, $format, $type);

See the query() documentation for more information.

=cut

sub queryObjectById {
    my $self = shift;
    return $self->query (id => @_);
}

=item $release = $simbad->release ();

This method returns the current SIMBAD4 release, as scraped from the
top-level web page. This will look something like 'SIMBAD4 1.045 -
27-Jul-2007'

If called in list context, it returns ($major, $minor, $point, $patch,
$date).  The returned information corresponding to the scalar example
above is:

 $major => 4
 $minor => 1
 $point => 45
 $patch => ''
 $date => '27-Jul-2007'

The $patch will usually be empty, but occasionally you get something
like release '1.019a', in which case $patch would be 'a'.

Please note that this method is B<not> based on a published interface,
but is simply a web page scraper, and subject to all the problems such
software is heir to. What the algorithm attempts to do is to find (and
parse, if called in list context) the contents of the next E<lt>tdE<gt>
after 'Release:' (case-insensitive).

=cut

sub release {
    my $self = shift;
    my $rslt = $self->_retrieve( 'simbad/' );
    my ($rls) = $rslt->content =~
	m{Release:.*?</td>.*?<td.*?>(.*?)</td>}sxi
	or croak "Error - Release information not found";
    $rls =~ s{<.*?>}{}g;
    $rls =~ s/^\s+//;
    $rls =~ s/\s+$//;
    wantarray or return $rls;
    $rls =~ s/\s+-\s+/ /;
    my ($major, $minor, $date) = split '\s+', $rls
	or croak "Error - Release '$rls' is ill-formed";
    $major =~s/^\D+//;
    $major += 0;
    ($minor, my $point) = split '\.', $minor, 2;
    $minor += 0;
    ($point, my $patch) = $point =~ m/^(\d+)(.*)/
	or croak "Error - Release '$rls' is ill-formed: bad point";
    defined $patch or $patch = '';
    $point += 0;
    return ($major, $minor, $point, $patch, $date);
}

=item $value = $simbad->script ($script);

This method submits the given script to SIMBAD4. The $script variable
contains the text if the script; if you want to submit a script file
by name, use the script_file() method.

If the L<verbatim|/verbatim> attribute is false, the front matter of the
result (up to and including the '::data:::::' line) is stripped. If
there is no '::data:::::' line, the entire script output is raised as an
exception.

If a 'script' L<parser|/parser> was specified, the output of the script
(after stripping front matter if that was specified) is passed to it.
The parser is presumed to return a list, so if script() was called in
scalar context you get a reference to that list back.

If no 'script' L<parser|/parser> is specified, the output of the script
(after stripping front matter if that was specified) is simply returned
to the caller.

=cut

sub script {
    my ( $self, $script ) = @_;
    return $self->_script(
	parser	=> 'script',
	script	=> $script,
	verbatim	=> $self->get( 'verbatim' ),
    );
}

{
    my %dflt = (
	parser	=> sub { return 'script' },
	script	=> sub {
	    confess 'Programming error - script argument required';
	},
	verbatim	=> sub {
	    my ( $self ) = @_;
	    return $self->get( 'verbatim' );
	},
    );

    sub _script {
	my ( $self, %arg ) = @_;

	foreach my $key ( keys %dflt ) {
	    defined $arg{$key}
		or $arg{$key} = $dflt{$key}->( $self );
	}

	my $debug = $self->get( 'debug' );

	$debug
	    and warn "Debug - script\n$arg{script} ";

	my $resp = $self->_retrieve( 'simbad/sim-script', {
		submit	=> 'submit+script',
		script	=> $arg{script},
	    },
	);

	my $rslt = $resp->content
	    or return;

	unless ( $arg{verbatim} ) {
	    $rslt =~ s/.*?::data:+\s*//sm or croak $rslt;
	}

	$debug
	    and warn "Debug - result:\n$rslt ";

	$rslt = XML::DoubleEncodedEntities::decode( $rslt );
	if ( my $parser = $self->_get_parser( $arg{parser} ) ) {
	    $debug
		and warn "Debug - Parser $arg{parser}";
	    ## $rslt =~ s/.*?::data:+.?$//sm or croak $rslt;
	    my @rslt = $parser->($rslt);
	    $debug
		and eval {	## no critic (RequireCheckingReturnValueOfEval)
		require YAML;
		warn "Debug - Parsed to:\n", YAML::Dump( \@rslt ), ' ';
	    };
	    return wantarray ? @rslt : \@rslt;
	} else {
	    $debug
		and warn "Debug - No parser for $arg{parser}";
	    return $rslt;
	}
    }
}


=item $value = $simbad->script_file ($filename);

This method submits the given script file to SIMBAD, returning the
result of the script. Unlike script(), the argument is the name of the
file containing the script, not the text of the script. However, if a
parser for 'script' has been specified, it will be applied to the
output.

=cut


sub script_file {
    my ( $self, $file ) = @_;

    my $url = $self->__build_url( 'simbad/sim-script' );
    my $rqst = POST $url, 
	Content_Type => 'form-data',
	Content => [
	    submit => 'submit file',
	    scriptFile => [$file, undef],
    	    # May need to specify Content_Type => application/octet-stream.
	];
    my $resp = $self->_retrieve( $rqst );

    my $rslt = $resp->content or return;
    unless ($self->get ('verbatim')) {
	$rslt =~ s/.*?::data:+\s*//sm or croak $rslt;
    }
    if (my $parser = $self->_get_parser ('script')) {
##	$rslt =~ s/.*?::data:+.?$//sm or croak $rslt;
##	$rslt =~ s/\s+//sm;
	my @rslt = $parser->($rslt);
	return wantarray ? @rslt : \@rslt;
    } else {
	return $rslt;
    }

}

=item $simbad->set ($name => $value ...);

This method sets the value of the given L<attributes|/Attributes>. More
than one name/value pair may be specified. If called as a static method,
it sets the default value of the attribute.

=cut

{	# Begin local symbol block.

    my $ckpn = sub {
	(looks_like_number ($_[2]) && $_[2] >= 0)
	    or croak "Attribute '$_[1]' must be a non-negative number";
	+$_[2];
    };

    my %mutator = (
	format => \&_set_hash,
	parser => \&_set_hash,
	scheme	=> \&_set_scheme,
	url_args => \&_set_hash,
    );

    my %transform = (
	delay => ($have_time_hires ?
	    $ckpn :
	    sub {+sprintf '%d', $ckpn->(@_) + .5}),
	format => sub {
##	    my ( $self, $name, $val, $key ) = @_;
	    my ( $self, undef, $val ) = @_;	# Name and key unused
	    if ($val !~ m/\W/ && (my $code = eval {
			$self->_get_coderef ($val)})) {
		$val = $code->();
	    }
	    $val;
	},
	parser => sub {
##	    my ( $self, $name, $val, $key ) = @_;
	    my ( $self, undef, $val ) = @_;	# Name and key unused
	    if (!ref $val) {
		unless ($val =~ m/::/) {
		    my $pkg = $self->_parse_subroutine_name ($val);
		    $val = $pkg . '::' . $val;
		}
		$self->_get_coderef ($val);	# Just to see if we can.
	    } elsif ( CODE_REF ne ref $val ) {
		croak "Error - $_[1] value must be scalar or code reference";
	    }
	    $val;
	},
    );

    foreach my $key (keys %static) {
	$transform{$key} ||= sub {$_[2]};
	$mutator{$key} ||= sub {
	    my $hash = ref $_[0] ? $_[0] : \%static;
	    $hash->{$_[1]} = $transform{$_[1]}->(@_)
	};
    }

    sub set {
	my ($self, @args) = @_;
	croak "Error - First argument must be an @{[__PACKAGE__]} object"
	    unless eval {$self->isa(__PACKAGE__)};
	while (@args) {
	    my $name = shift @args;
	    croak "Error - Attribute '$name' is unknown"
		unless exists $mutator{$name};
	    $mutator{$name}->($self, $name, shift @args);
	}
	return $self;
    }

    sub _set_hash {
	my ($self, $name, $value) = @_;
	my $hash = ref $self ? $self : \%static;
	unless (ref $value) {
	    $value = {$value =~ m/=/ ?
		split ('=', $value, 2) : ($value => undef)};
	}
	$hash->{$name} = {} if $value->{clear};
	delete $value->{clear};
	foreach my $key (keys %$value) {
	    my $val = $value->{$key};
	    if (!defined $val) {
		delete $hash->{$name}{$key};
	    } elsif ($val) {
		$hash->{$name}{$key} =
		    $transform{$name}->($self, $name, $value->{$key}, $key);
	    } else {
		$hash->{$name}{$key} = '';
	    }
	}
	return;
    }

    sub _set_scheme {
	my ( $self, $name, $value ) = @_;
	if ( my $msg = _is_scheme_valid( $value ) ) {
	    croak $msg;
	}
	my $hash = ref $self ? $self : \%static;
	$hash->{$name} = lc $value;
	return;
    }

}	# End local symbol block.


=item $value = $simbad->url_query ($type => ...)

This method performs a query by URL, returning the results. The type
is one of:

 id = query by identifier,
 coo = query by coordinates,
 ref = query by references,
 sam = query by criteria.

The arguments depend on on the type, and are documented at
L<http://simbad.u-strasbg.fr/simbad/sim-help?Page=sim-url>. They are
specified as name => value. For example:

 $simbad->url_query (id =>
    Ident => 'Arcturus',
    NbIdent => 1
 );

Note that in an id query you must specify 'Ident' explicitly. This is
true in general, because it is not always possible to derive the first
argument name from the query type, and consistency was chosen over
brevity.

The output.format argument can be defaulted based on the object's type
setting as follows:

 txt becomes 'ASCII',
 vo becomes 'VOTable'.

Any other value is passed verbatim.

If the query succeeds, the results will be passed to the appropriate
parser if any. The reverse of the above translation is done to determine
the appropriate parser, so the 'vo' parser (if any) is called if
output.format is 'VOTable', and the 'txt' parser (if any) is called if
output.format is 'ASCII'. If output.format is 'HTML', you will need to
explicitly set up a parser for that.

The type of HTTP interaction depends on the setting of the L<post|/post>
attribute: if true a POST is done; otherwise all arguments are tacked
onto the end of the URL and a GET is done.

=cut

{	# Begin local symbol block.

    my %type_map = (	# Map SOAP type parameter to URL output.format.
	txt	=> 'ASCII',
	vo	=> 'VOTable',
    );
    my %type_unmap = reverse %type_map;

    # Perl::Critic objects to the use of @_ (rather than values 
    # unpacked from it) but the parity check lets me give a less
    # unfriendly error message. CAVEAT: do NOT modify the contents
    # of @_, since this will be seen by the caller. Modifying @_
    # itself is fine.
    sub url_query {	## no critic (RequireArgUnpacking)
	@_ % 2 and croak <<eod;
Error - url_query needs an even number of arguments after the query
        type.
eod
	my ($self, $query, %args) = @_;
###	my $debug = $self->get ('debug');
	my $dflt = $self->get ('url_args');
	foreach my $key (keys %$dflt) {
	    exists ($args{$key}) or $args{$key} = $dflt->{$key};
	}
	unless ($args{'output.format'}) {
	    my $type = $self->get ('type');
	    $args{'output.format'} = $type_map{$type} || $type;
	}
	my $resp = $self->_retrieve( "simbad/sim-$query", \%args );

	$resp = XML::DoubleEncodedEntities::decode ($resp->content);

	my $parser;
	if (my $type = $type_unmap{$args{'output.format'}}) {
	    $parser = $self->_get_parser ($type);
	    return wantarray ? ($parser->($resp)) : [$parser->($resp)]
		if $parser;
	}

	return $resp;
    }

}	# End local symbol block.


########################################################################
#
#	Utility routines
#

#	__build_url
#
#	Builds a URL based on the currently-set scheme and server, and
#	the fragment provided as an argument. If the fragment is an
#	HTTP::Request object it is simply returned.

sub __build_url {
    my ( $self, $fragment ) = @_;
    defined $fragment
	or $fragment = '';
    eval { $fragment->isa( 'HTTP::Request' ) }
	and return $fragment;
    $fragment =~ s< \A / ><>smx;	# Defensive programming
    return sprintf '%s://%s/%s', $self->get( 'scheme' ),
	$self->get( 'server' ), $fragment;
}

#	_callers_caller();
#
#	Returns the name of the subroutine that called the caller.
#	Results undefined if not called from a subroutine nested at
#	least two deep.

sub _callers_caller {
    my $inx = 1;
    my $caller;
    foreach ( 1 .. 2 ) {
	do {
	    $caller = ( caller $inx++ )[3]
	} while '(eval)' eq $caller;
    }
    return $caller;
}

#	$self->_delay
#
#	Delays the desired amount of time before issuing the next
#	query.

{
    my %last;
    sub _delay {
	my $self = shift;
	my $last = $last{$self->{server}} ||= 0;
	if ((my $delay = $last + $self->{delay} - time) > 0) {
	    sleep ($delay);
	}
	return ($last{$self->{server}} = time);
    }
}


#	$self->_deprecation_notice( $type, $name );
#
#	This method centralizes deprecation. Type is 'attribute' or
#	'method'. Deprecation is driven of the %deprecate hash. Values
#	are:
#	    false - no warning
#	    1 - warn on first use
#	    2 - warn on each use
#	    3 - die on each use.
#
#	$self->_deprecation_in_progress( $type, $name )
#
#	This method returns true if the deprecation is in progress. In
#	practice this means the %deprecate value is defined.
#	This is currently unused and commented out

{

    my %deprecate = (
	method	=> {
	    query	=> 2,
	},
    );

    sub _deprecation_notice {
	my ( undef, $type, $name, $repl ) = @_;	# Invocant unused
	$deprecate{$type} or return;
	$deprecate{$type}{$name} or return;
	my $msg = sprintf 'The %s %s is %s', $name, $type,
	    $deprecate{$type}{$name} > 2 ? 'removed' : 'deprecated';
	defined $repl
	    and $msg .= "; use $repl instead";
	$deprecate{$type}{$name} >= 3
	    and croak( $msg );
	warnings::enabled( 'deprecated' )
	    and carp( $msg );
	$deprecate{$type}{$name} == 1
	    and $deprecate{$type}{$name} = 0;
	return;
    }

=begin comment

    sub _deprecation_in_progress {
	my ( undef, $type, $name ) = @_;	# Invocant unused
	$deprecate{$type} or return;
	return defined $deprecate{$type}{$name};
    }

=end comment

=cut

}

#	$ref = $self->_get_coderef ($string)
#
#	Translates the given string into a code reference, loading
#	modules if needed. If the string is not a fully-qualified
#	subroutine name, it is assumed to be in the namespace of
#	the first caller not in this namespace. Failed loads are
#	cached so that they will not be tried again.

{

    sub _get_coderef {
	my $self = shift;
	my $parser = shift;
	if ($parser && !ref $parser) {
	    my ($pkg, $code) =
		$self->_parse_subroutine_name ($parser);
	    unless (($parser = $pkg->can ($code)) || !$self->get ('autoload')) {
		_load_module ($pkg);
		$parser = $pkg->can ($code);
	    }
	    $parser or croak "Error - ${pkg}::$code undefined";
	}
	return $parser;
    }

}

#	$parser = $self->_get_parser ($type)

#	returns the code reference to the parser for the given type of
#	data, or false if none. An exception is thrown if the value
#	is a string which does not specify a defined subroutine.

sub _get_parser {
    my ($self, $type) = @_;
    return $self->_get_coderef ($self->get ('parser')->{$type});
}

# Return false if the argument is a URI scheme we know how to deal with;
# otherwise return an error message. The optional second argument is a
# template for the message, with a single '%s' that gets the actual
# value of the scheme.

{
    my %supported;

    BEGIN {
	%supported = map { $_ => 1 } qw{ http https };
    }

    sub _is_scheme_valid {
	my ( $scheme, $msg ) = @_;
	$scheme = lc( $scheme || '' );
	$msg ||= q<Unsupported scheme '%s'>;
	$supported{$scheme}
	    or return sprintf $msg, $scheme;
	LWP::Protocol::implementor( $scheme )
	    and return;
	$msg .= "; have you installed LWP::Protocol::$scheme?";
	return sprintf $msg, $scheme;
    }
}

#	$rslt = _load_module($name)
#
#	This subroutine loads the named module using 'require'. It
#	croaks if the load fails, or returns the result of the
#	'require' if it succeeds. Results are cached, so subsequent
#	calls simply do what the first one did.

{	# Local symbol block. Oh, for 5.10 and state variables.
    my %error;
    my %rslt;
    sub _load_module {
	my  ($module) = @_;
	exists $error{$module} and croak $error{$module};
	exists $rslt{$module} and return $rslt{$module};
	$rslt{$module} = eval "require $module";
	$@ and croak ($error{$module} = $@);
	return $rslt{$module};
    }
}	# End local symbol block.

#	$ua = _get_user_agent ();
#
#	This subroutine returns an LWP::UserAgent object with its agent
#	string set to the default, with our class name and version
#	appended in parentheses.

sub _get_user_agent {
    my $ua = LWP::UserAgent->new (
    );
##    $ua->agent ($ua->_agent . ' (' . __PACKAGE__ . ' ' . $VERSION .
##	')');
    $ua->agent (&agent);
    return $ua;
}

#	($package, $subroutine) = $self->_parse_subroutine_name ($name);
#
#	This method parses the given name, and returns the package name
#	in which the subroutine is defined and the subroutine name. If
#	the $name is a bare subroutine name, the package is the calling
#	package unless that package contains no such subroutine but
#	$self->can($name) is true, in which case the package is
#	ref($self).
#
#	If called in scalar context, the package is returned.

sub _parse_subroutine_name {
    my ($self, $parser) = @_;
    my @parts = split '::', $parser;
    my $code = pop @parts;
    my $pkg = join '::', @parts;
    unless ($pkg) {
	my %tried = (__PACKAGE__, 1);
	my $inx = 1;
	while ($pkg = (caller ($inx++))[0]) {
	    next if $tried{$pkg};
	    $tried{$pkg} = 1;
	    last if $pkg->can ($code);
	}
	$pkg = ref $self if !$pkg && $self->can ($code);
	defined $pkg or croak <<eod;
Error - '$parser' yields undefined package name.
eod
	@parts = split '::', $pkg;
    }
    return wantarray ? ($pkg, $code) : $pkg;
}

#	my $resp = $self->_retrieve( $fragment, \%args );
#
#	Build a URL from the contents of the 'scheme' and 'server'
#	attributes, and the given fragment, and retrieve the data from
#	that URL.  The \%args argument is optional.
#
#	The return is an HTTP::Response object. If the response is
#	indicates that the request is unsuccessful we croak with the URL
#	(if that can be retrieved) and the status line.
#
#	The details depend on the arguments and the state of the
#	invocant as follows:
#
#	If $url is an HTTP::Request object, it is executed and the
#	response returned. Otherwise
#
#	If \%args is present and not empty, and the 'post' attribute is
#	true, an HTTP post() request is done to the URL, sending the
#	data. Otherwise
#
#	If there are arguments they are appended to the URL, and an HTTP
#	get() is done to the URL.

sub _retrieve {
    my ($self, $fragment, $args) = @_;
    my $url = $self->__build_url( $fragment );
    $args ||= {};
    my $debug = $self->get ('debug');
    my $ua = _get_user_agent ();
    $self->_delay ();
    my $resp;
    if (eval {$url->isa('HTTP::Request')}) {
	$debug
	    and print 'Debug ', _callers_caller(), 'executing ',
		$url->as_string, "\n";
	$resp = $ua->request ($url);
    } elsif ($self->get ('post') && %$args) {
	if ($debug) {
	    print 'Debug ', _callers_caller(), " posting to $url\n";
	    foreach my $key (sort keys %$args) {
		print "    $key => $args->{$key}\n";
	    }
	}
	$resp = $ua->post ($url, $args);
    } else {
	my $join = '?';
	foreach my $key (sort keys %$args) {
	    $url .= $join . _escape_uri( $key ) .  '=' . _escape_uri (
		$args->{$key} );
	    $join = '&';
	}
	$debug
	    and print 'Debug ', _callers_caller(), " getting from $url\n";
	$resp = $ua->get( $url );
    }
    $debug
	and print 'Debug - request: ', $resp->request()->as_string(), "\n";

    $resp->is_success()
	and return $resp;

    my $rq = $resp->request()
	or croak $resp->status_line();
    my $u = $rq->uri();
    croak "$u: ", $resp->status_line();
}

1;

__END__

=back

=head2 Attributes

The Astro::SIMBAD::Client attributes are documented below. The type of
the attribute is given after the attribute name, in parentheses. The
types are:

 boolean - a true/false value (in the Perl sense);
 hash - a reference to one or more key/value pairs;
 integer - an integer;
 string - any characters.

Hash values may be specified either as hash references or as strings.
When a hash value is set, the given value updates the hash rather than
replacing it. For example, specifying

 $simbad->set (format => {txt => '%MAIN_ID\n'});

does not affect the value of the vo format. If a key is set to the
null value, it deletes the key. All keys in the hash can be deleted
by setting key 'clear' to any true value.

When specifying a string for a hash-valued attribute, it must be of
the form 'key=value'. For example,

 $simbad->set (format => 'txt=%MAIN_ID\n');

does the same thing as the previous example. Specifying the key name
without an = sign deletes the key (e.g. set (format => 'txt')).

The Astro::SIMBAD::Client class has the following attributes:

=over

=item autoload (boolean)

=for html <a name="autoload"></a>

This attribute determines whether setting the parser should attempt
to autoload its package.

The default is 1 (i.e. true).

=for html <a name="debug"></a>

=item debug (integer)

This attribute turns on debug output. It is unsupported in the sense
that the author makes no claim what will happen if it is non-zero.

The default value is 0.

=for html <a name="delay"></a>

=item delay (integer)

This attribute sets the minimum delay in seconds between requests, so as
not to overload the SIMBAD server. If Time::HiRes can be loaded, you can
set delays in fractions of a second; otherwise the delays will be
rounded to the nearest second.

Delays are from the time of the last request to the server, no matter
which object issued the request. The delay can be set to 0, but not to a
negative number.

The default is 3.

=for html <a name="emulate_soap_queries">

=item emulate_soap_queries (boolean)

If this attribute is true, the methods that would normally use the SOAP
interface (that is, C<query()> and friends) use the script interface
instead.

The purpose of this attribute is to give the user a way to manage the
deprecation and ultimate removal of the SOAP interface from the SIMBAD
servers. It may go away once that interface disappears, but it will be
put through a deprecation cycle.

The default is false, but will become true once the University of
Strasbourg shuts down its SOAP server.

=for html <a name="format"></a>

=item format (hash)

This attribute holds the default format for a given query()
output type. See
L<http://simweb.u-strasbg.fr/simbad/sim-help?Page=sim-fscript> for how
to specify formats for each output type. Output type 'script' is used to
specify a format for the script() method.

The format can be specified either literally, or as a subroutine name or
code reference. A string is assumed to be a subroutine name if it looks
like one (i.e. matches (\w+::)*\w+), and if the given subroutine is
actually defined. If no namespace is specified, all namespaces in the
call tree are checked. If a code reference or subroutine name is
specified, that code is executed, and the result becomes the format.

The following formats are defined in this module:

 FORMAT_TXT_SIMPLE_BASIC -
   a simple-to-parse text format providing basic information;
 FORMAT_TXT_YAML_BASIC -
   pseudo-YAML (parsable by YAML::Load) providing basic info;
 FORMAT_VO_BASIC -
   VOTable field names providing basic information.

The FORMAT_TXT_YAML_BASIC format attempts to provide data structured
similarly to the output of L<Astro::SIMBAD>, though
Astro::SIMBAD::Client does not bless the output into any class.

A simple way to examine these formats is (e.g.)

 use Astro::SIMBAD::Client;
 print Astro::SIMBAD::Client->FORMAT_TXT_YAML_BASIC;

Before a format is actually used it is preprocessed in a manner
depending on its intended output type. For 'vo' formats, leading and
trailing whitespace are stripped. For 'txt' and 'script' formats, line
breaks are stripped.

The default specifies formats for output types 'txt' and 'vo'. The
'txt' default is FORMAT_TXT_YAML_BASIC; the 'vo' default is
FORMAT_VO_BASIC.

There is no way to specify a default format for the 'script_file'
method.

=for html <a name="parser"></a>

=item parser (hash)

This attribute specifies the parser for a given output type.

Parsers may be specified by either a code reference, or by the
text name of a subroutine. If specified as text and the name
is not qualified by a package name, the calling package is assumed.
The parser must be defined, and must take as its lone argument
the text to be parsed.

If the parser for a given output type is defined, query results of that
type will be passed to the parser, and the result returned. Otherwise
the query results will be returned verbatim.

The output types are anything legal for the query() method (i.e. 'txt'
and 'vo' at the moment), plus 'script' for a script parser. All default
to '', meaning no parser is used.

=item post (boolean)

=for html <a name="post"></a>

This attribute specifies that url_query() data should be acquired using
a POST request. If false, a GET request is used.

The default is 1 (i.e. true).

=for html <a name="scheme"></a>

=item scheme (string)

This attribute specifies the server's URI scheme to be used. As of
January 27 2017, either C<'http'> or C<'https'> is valid.

The default is the value of environment variable
C<ASTRO_SIMBAD_CLIENT_SCHEME>, or C<'http'> if the environment variable
is not set, or if it contains a value other than C<'http'> or
C<'https'>, case-insensitive.

=for html <a name="server"></a>

=item server (string)

This attribute specifies the server to be used. As of March 10 2010,
either C<'simbad.u-strasbg.fr'> or C<'simbad.cfa.harvard.edu'> is valid.

The default is the value of environment variable
ASTRO_SIMBAD_CLIENT_SERVER, or C<'simbad.u-strasbg.fr'> if the
environment variable is not set.

=for html <a name="type"></a>

=item type (string)

This attribute specifies the default output type. Note that although
SIMBAD only defined types 'txt' and 'vo', we do not validate this,
since the SIMBAD web site hints at more types to come. SIMBAD appears
to treat an unrecognized type as C<'txt'>.

The default is C<'txt'>.

=for html <a name="url_args"></a>

=item url_args (hash)

This attribute specifies default arguments for url_query method. These
will be applied only if not specified in the method call. Any argument
given in the SIMBAD documentation may be specified. For example:

 $simbad->set (url_args => {coodisp1 => d});

causes the query to return coordinates in degrees and decimals rather
than in sexagesimal (degrees, minutes, and seconds or hours, minutes,
and seconds, as the case may be.) Note, however, that VOTable output
does not seem to be affected by this.

The initial default for this attribute is an empty hash; that is, no
arguments are defaulted by this mechanism.

=for html <a name="verbatim"></a>

=item verbatim (boolean)

This attribute specifies whether script() and script_file() are to strip
the front matter from the script output. If false, everything up to and
including the '::data:::::' line is removed before passing the output to
the parser or returning it to the user. If true, the script output is
passed to the parser or returned to the user unmodified.

The default is C<0> (i.e. false).

=back

=head1 ENVIRONMENT

=head2 ASTRO_SIMBAD_CLIENT_SCHEME

If assigned a true value, this environment variable specifies the
default for the C<'scheme'> attribute. It is read when the module is
loaded. If you want to change the default after the module has been
loaded, make a static call to C<set()>.

=head2 ASTRO_SIMBAD_CLIENT_SERVER

If assigned a true value, this environment variable specifies the
default for the C<'server'> attribute. It is read when the module is
loaded. If you want to change the default after the module has been
loaded, make a static call to C<set()>.

=head2 L<LWP::UserAgent|LWP::UserAgent>

The following environment variables control use of a proxy server. They
are implemented by L<LWP::UserAgent|LWP::UserAgent>, but are documented
fairly obscurely, so I have chosen to say a few words about them here:

=head3 PERL_LWP_ENV_PROXY

If this environment variable is set to a true value,
L<LWP::UserAgent|LWP::UserAgent> will take proxy settings for each URL
scheme from environment variables named C<xxxx_proxy> (yes, lower-case),
where the C<'xxxx'> is the scheme name. The content of each
scheme-specific environment variables is the URL (scheme, host, and
port) of the proxy. The following are relevant to users of this module:

=head3 http_proxy

This environment variable is set to the URL of the C<http:> proxy
server.

=head2 https_proxy

This environment variable is set to the URL of the C<http:> proxy
server.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
