########################################################################
# CVS     : $Header: /home/cvs/software/cvsroot/configuration/lib/Config/Wrest.pm,v 1.36 2006/08/22 14:09:50 mattheww Exp $
########################################################################

package Config::Wrest;
use strict;
use Carp;
use constant MAX_INCLUDES => 1000;
use constant MAX_SER_DEPTH => 500;
use constant ERR_HASH => 'Data structure is not a hash reference';
use constant ERR_VARIABLES_HASH => 'The value of the Variables option must be a hash reference';
use constant ERR_BADREF => 'Data structure is not a hash or array reference';
use constant ERR_BADTOK => 'Found hash key with bad characters in it. Only \w, - and . are ok. Offending key was: "';
use constant ERR_BADLISTITEM => 'Found list value with bad characters in it. Try setting the UseQuotes option. Offending value was: "';
use constant ERR_BADLISTITEM_QUOTE => 'Found list value with bad characters in it, even though UseQuotes is set. Offending value was: "';
use constant ERR_MAX_SER_DEPTH_EXCEEDED => 'Recursed more than '.MAX_SER_DEPTH.' levels into the data structure, which exceeds recursion limit. Possible cyclic data structure - try setting the WriteWithReferences option to fix';
use constant ERR_DESER_STRING_REF => 'The deserialize() method takes a string or a string reference, but was given a reference of type ';
use constant ERR_SER_STRING_REF => 'The serialize() method takes a string reference, but was given a reference of type ';
use constant ERR_NO_FILENAME => 'You must supply a filename';
use constant VAR_CHECK_TOP_LEVEL => 1;

use vars qw($VERSION $RE_DATASING $RE_DATASINGQUOTE);

$VERSION = sprintf('%d.%03d', q$Revision: 1.36 $ =~ /: (\d+)\.(\d+)/);
$RE_DATASING = q/^([^\[\(\{\<\:\@\%\/][\S]*)$/;	# unquoted list item values - no spaces...
$RE_DATASINGQUOTE = q/^([\'\"].*[\'\"])$/;		# quoted list item values _may_ have spaces

########################################################################
# Public Interface
########################################################################

sub new {
	my ($class, %options) = @_;
	my $self = {
		UniqueIdCounter => 0,
	};
	TRACE(__PACKAGE__."::new");

	# set defaults for various options
	# these default to false...
	for my $o (qw(IgnoreInvalidLines Subs TemplateBackend WriteWithEquals WriteWithReferences IgnoreUnclosedTags)) {
		$self->{'options'}{$o} = $options{$o} || 0;
	}
	# ...copy these as-is
	for my $o (qw(TemplateOptions)) {
		$self->{'options'}{$o} = $options{$o};
	}
	# ...and these default to true
	for my $o (qw(AllowEmptyValues Escapes UseQuotes WriteWithHeader Strict DieOnNonExistantVars)) {
		$self->{'options'}{$o} = ( exists $options{$o} ? $options{$o} : 1 );
	}
	$self->{'options'}{'Variables'} = $options{'Variables'};
	if ($self->{'options'}{'Variables'} && ref($self->{'options'}{'Variables'}) ne 'HASH') {
		croak(ERR_VARIABLES_HASH);
	}

	$self->{'errorprefix'} = '';
	bless($self, $class);
	$self->_restore_options;
	TRACE(__PACKAGE__."::new successful");
	return $self;
}

sub deserialize {
	my ($self, $string) = @_;
	TRACE(__PACKAGE__."::deserialize");

	$self->_restore_options;
	$self->{'errorprefix'} = (__PACKAGE__ . ":");
	my $linearray;
	if (! ref($string)) {
		TRACE(__PACKAGE__."::deserialize - string literal");
		$linearray = _str2array(\$string);
	} elsif (ref($string) eq 'SCALAR') {
		TRACE(__PACKAGE__."::deserialize - string reference");
		$linearray = _str2array($string);
	} else {
		croak(ERR_DESER_STRING_REF.ref($string));
	}
	return _parse($self, $linearray, $self->{'current_options'});
}

sub deserialise { return deserialize(@_); }

sub serialize {
	my ($self, $vars, $string) = @_;
	TRACE(__PACKAGE__."::serialize");

	croak(ERR_HASH) unless (ref($vars) eq 'HASH');
	croak(ERR_SER_STRING_REF.ref($string))
		if defined $string && ref($string) ne 'SCALAR';

	$self->_restore_options;
	$self->{'errorprefix'} = (__PACKAGE__ . ":");

	# copy current_options to pass to _serialise()
	my $c_options = $self->{'current_options'} || {};
	my $options = { %$c_options };
	my $rv = _serialise($self, $vars, $options);

	if ($options->{'WriteWithHeader'}) {
		# create header
		my $prep = '# Created by ' . __PACKAGE__ . " $VERSION at " .
			localtime() . "\n";
		for my $i ([qw/set AllowEmptyValues IgnoreInvalidLines Strict DieOnNonExistantVars/],
					 [qw/option Escapes UseQuotes/]) {
			my($type, @names) = @$i;
			$prep .= sprintf("\@%s %s %d\n", $type, $_, $options->{$_} ? 1 : 0)
				for @names;
		}
		$prep .= "# End of header\n";
		$rv = $prep.$rv;
	}
	if ($string) {
		$$string = $rv;
		return undef;
	} else {
		return $rv;
	}
}

sub serialise { return serialize(@_); }

sub parse_file {
	my ($self, $filename) = @_;
	TRACE(__PACKAGE__."::parse_file '$filename'");
	croak(ERR_NO_FILENAME) unless ( defined $filename );

	$self->_restore_options;
	$self->{'errorprefix'} = (__PACKAGE__ . ": File '$filename':");
	my $linearray = _file2array($filename);
	return _parse($self, $linearray, $self->{'current_options'});
}

sub write_file {
	my ($self, $filename, $vars) = @_;
	TRACE(__PACKAGE__."::write_file '$filename'");
	croak(ERR_NO_FILENAME) unless ( defined $filename );

	my $str = $self->serialize($vars);
	require File::Slurp::WithinPolicy;
	File::Slurp::WithinPolicy::write_file($filename, $str);
}

########################################################################
# Private routines
########################################################################

sub _restore_options {
	my $self = shift;
	TRACE(__PACKAGE__."::_restore_options");
	delete $self->{'current_options'};
	for my $k (keys %{ $self->{'options'} }) {
		$self->{'current_options'}{$k} = $self->{'options'}{$k};
	}

	if ($self->{'options'}{'Variables'}) {
		TRACE(__PACKAGE__."::_restore_options cloning Variables");
		require Storable;
		my $copy = Storable::dclone( $self->{'options'}{'Variables'} );
		$self->{'current_options'}{'Variables'} = $copy;
	}
}

sub _file2array {
	my $filename = shift;
	TRACE(__PACKAGE__."::_file2array '$filename'");

	require File::Slurp::WithinPolicy;
	my $contents = File::Slurp::WithinPolicy::read_file( $filename );
	return _str2array(\$contents);
}

sub _str2array {
	my $contents = shift;
	TRACE(__PACKAGE__."::_str2array");

	my @linearray;
	if ($$contents =~ m/\x0D\x0A/) {
		# handle 2-character line break sequences from DOS
		@linearray = split(/\x0D\x0A/, $$contents);
	} else {
		# handle single-character line breaks
		@linearray = split(/[\n\r]/, $$contents);
	}
	TRACE(__PACKAGE__."::_str2array returns ".@linearray." lines");
	return \@linearray;	
}

sub _parse {
	my $self = shift;
	my ($linearray, $options) = @_;
	TRACE(__PACKAGE__."::_parse");
	
	#ensure we have a hashref to prevent Any::Template errors
	$options->{'Variables'} ||= {};

	#reset the hash which counts how many times we have used files
	$options->{'__includeguard'} = {};

	#regular expressions that we'll use many times
	my $re_nuke = q/[\n\r]/;
	my $re_skipcomment = q/^\s*#/;
	my $re_skipblank = q/^\s*$/;
	my $re_trimcomment = q/#.*$/;
	my $re_trimtrailsp = q/\s*$/;
	my $re_trimleadsp = q/^\s*/;
	
	# Also see the top of this module for other regular expressions
	my $re_datapair = q/^([\w\-\.]+)\s*[\s=]\s*(.*)/;

	my $re_openhash = q/^(\<)([\w\-\.]+)\>$/;
	my $re_openlist = q/^(\[)([\w\-\.]+)\]$/;
	my $re_closhash = q/^(\<)\/([\w\-\.]*)\>$/;
	my $re_closlist = q/^(\[)\/([\w\-\.]*)\]$/;
	
	my $re_command = q/^\s*\@\s*(\w+)\s*(.*?)\s*$/;
	
	my %vars;
	my @stack = (\%vars);	# stack of references to each level of nesting
	my @level = ('');		# stack holding the names of all enclosing blocks

	my $LINE = 0;
	while (@$linearray) {
		$LINE++;
		local $_ = shift @$linearray;
		chomp;
		s/$re_nuke//g;
		next if /$re_skipcomment/;		# skip comments

		#Interpolate values if required
		if ($options->{'Subs'} && length($_)) {
			my $linestring = $_;
			require Any::Template;
			my $backend = $options->{'TemplateBackend'};
			my $backendoptions = $options->{'TemplateOptions'};
			my $t = new Any::Template({ Backend => $backend, Options => $backendoptions, String => $linestring });
			my $string = $t->process( { %ENV, %vars, %{$options->{'Variables'}} } );
			my @lines;
			my $include_lines = _str2array(\$string);
			($_, @lines) = @$include_lines;
			unshift @$linearray, @lines;
		}

		next if /$re_skipcomment/;		# skip comments again, in case the interpolation has created any
		next if /$re_skipblank/;		# skip blank lines

		#Remove comments, & surrounding space
		s/$re_trimcomment//;
		s/$re_trimtrailsp//;
		s/$re_trimleadsp//;

		#Block opening tags: <FOO> and [BAR]
		if (/$re_openhash/ || /$re_openlist/) {
			my ($type, $block) = ($1, $2);
			my $struct = (( $type eq '<' ) ? {} : [] );
			if (ref($stack[$#stack]) eq 'HASH') {
				$stack[$#stack]->{$block} = $struct;
			} else {
				push(@{$stack[$#stack]}, $struct);
			}
			
			push(@level, $block);
			push(@stack, $struct);
		}
		#Block closing tags: </FOO>, </>, [/BAR] or [/]
		elsif ( /$re_closhash/ || /$re_closlist/)
		{
			my ($type, $block) = ($1, $2);
			# ensure that the tag matches the item we popped off the stack
			my $popped = pop(@stack);
			if (ref $popped eq 'HASH') {
				die("$self->{'errorprefix'} Nesting Error - hash block closed with array-style tag - Line $LINE: $_\n") if ($type ne '<');
			} elsif (ref $popped eq 'ARRAY') {
				die("$self->{'errorprefix'} Nesting Error - array block closed with hash-style tag - Line $LINE: $_\n") if ($type ne '[');
			} else {
				die("$self->{'errorprefix'} Internal Error - Stack contained '$popped' - Line $LINE: $_\n")
			}
			unless ($popped && ($#stack >= 0)) { die("$self->{'errorprefix'} Stack underflow error - Line $LINE: $_"); }
			if ((pop(@level) ne $block) && $block) { die("$self->{'errorprefix'} Nesting Error - Line $LINE: $_"); }
		}
		#Lines for use in hashes, like: NAME = VALUE
		elsif (/$re_datapair/)
		{
			my ($name, $value) = ($1, $2);
			$value = _strip_and_unquote ( $value, $options );
			
			if (ref($stack[$#stack]) eq 'HASH') {
				$stack[$#stack]->{$name} = $value;
			} else {
				$self->_invalid_line ( "this line not valid in a list block: Line $LINE: $_\n" );
			}
		}
		#Lines for use in lists, like: VALUE or 'VALUE WITH SPACES'
		elsif (/$RE_DATASING/ or /$RE_DATASINGQUOTE/)
		{
			my $value = $1;
			$value = _strip_and_unquote ( $value, $options );
			if (ref($stack[$#stack]) eq 'ARRAY') {
				push(@{$stack[$#stack]}, $value);
			} else {
				if (!$options->{AllowEmptyValues}) {
					$self->_invalid_line ( "this line only valid in a list block: Line $LINE: $_\n" );
				} else {
					# it's a blank element
					$stack[$#stack]->{$value} = "";
				}
			}
		}
		# directives to the parser, like: @set suffix .jpg  - or - @option Escapes 1
		elsif (/$re_command/)
		{
			my $cmd = lc($1);
			my $text = $2;
			if ($cmd eq 'option') {
				my ($name, $value) = ($text =~ /^\s*(\w+)\s*(.*?)\s*$/);
				# check to make sure that name can be overridden with @option
				if ( $name !~ m/^(UseQuotes|Escapes|Subs|TemplateBackend)$/i ) {
					warn ( $self->{'errorprefix'} .
						"unable to set " . $name . " with \@option" );
				} else {
					$value = _strip_and_unquote ( $value, $options );
					$options->{$name} = $value;
				}
			} elsif ($cmd eq 'set') {
				my ($name, $value) = ($text =~ /^\s*(\w+)\s*(.*?)\s*$/);
				$value = _strip_and_unquote ( $value, $options );
				$options->{'Variables'}->{$name} = $value;
			} elsif ($cmd eq 'include') {
				$text = _strip_and_unquote ( $text, $options );
				if ($options->{'__includeguard'}{$text}++ > MAX_INCLUDES) {
					die "$self->{'errorprefix'} the file $text has been included too many times - probably a recursive include. Line $LINE\n";
				}
				my $lines = _file2array($text);
				unshift @$linearray, @$lines;
			} elsif ($cmd eq 'reference') {
				# the 'name' is optional in list blocks - this regex matches with and without the 'name'
				my ($name, $path) = ($text =~ /^\s*(?:([\w\-\.]+)?\s+)?(\S+)\s*$/);
				$path = _strip_and_unquote ( $path, $options );
				if (ref($stack[$#stack]) eq 'HASH') {
					die "$self->{'errorprefix'} You must give the new value a name inside hash blocks: Line $LINE: $_\n" unless (defined($name) && length($name));
					$stack[$#stack]->{$name} = _var($self, $path, \%vars);
				} else { # we're in an array block
					push(@{$stack[$#stack]}, _var($self, $path, \%vars));
				}
			} else {
				$self->_invalid_line ( "could not understand directive: Line $LINE: $_\n" );
			}
		}
		else
		{
			$self->_invalid_line ( "skipping invalid line: Line $LINE: $_\n" );
		}
	}
	
	# did we needed to implicitly close some tags?
	unless ($#stack == 0) {
		my $error = "$self->{'errorprefix'} There were $#stack open tags implicitly closed";
		if ($options->{IgnoreUnclosedTags}) {
			warn($error);
		} else {
			die($error);
		}
	}
	
	return \%vars
}

sub _strip_and_unquote {
	my ($text, $options) = @_;
	my $re_quotes = q/^([\'\"])(.*)\1$/;
	my $re_escape = q/%((?:[0-9a-fA-F]{2})|(?:\{[0-9a-fA-F]+\}))/;
	if ($options->{UseQuotes}) { $text =~ s/$re_quotes/$2/; }
	if ($options->{Escapes}) { $text =~ s/$re_escape/_unescape($1)/ge; }
	return $text;
}

# fetch the value of $name from $vars (array or hashref)
# $name may contain dereferences of the form zzz->yyy
sub _var {
	my ($self, $name, $vars) = @_;
	TRACE(__PACKAGE__."::_var '$name'");
	my $ref = $vars;
	my $found = 0;

	# split $name on arrow operator '->'
	my @levels = ($name);
	@levels = split /->/, $name if $name =~ /[\w\-\.]+->[\w\-\.]+/;

	for my $i (0..$#levels) {
		my $k = $levels[$i];
		my($val, @allowed, $keystr);
		last unless defined $ref;
		if(ref $ref eq 'HASH') {
			$found = exists $ref->{$k};
			$val = $ref->{$k};
			@allowed = keys %$ref;
			$keystr = 'key';
		} else {
			$found = defined($val = $ref->[$k]);
			$keystr = 'subscript';
		}
		$found = 1 if @levels == 1 && !VAR_CHECK_TOP_LEVEL;
		unless($found) {
			my $error = "trying to use nonexistent $keystr $k";
			$error .= "(We would have allowed: ".
				(join ",", @allowed).")" if @allowed;
			$self->_nonexistant_var($error);
		}
		$ref = $val if $found;
	}
	return $found ? $ref : undef;
}

sub _unescape {
	my $str = shift;
	if ($str =~ m/[{}]/) {
		$str =~ s/[{}]//g;
	}
	return chr(hex($str));
}

sub _escape {
	my $str = shift;
	unless (defined $str) {
		return undef;
	}

	my $packstr = "U*";
	if ($] && $] < 5.006001) {
		$packstr = "C*";	# earlier version of perl didn't have the 'U' pack template
	}
	if ($^V && $^V lt chr(5).chr(8)) {
		# perl 5.6 doesn't like us to unpack a string of single-byte characters
		# which contains a character in the 128-255 range with U*. So, we have to revert to
		# the C* template if all the characters are bytes.
		# Note that this code only executes on perl 5.6
		my $strlen = length($str);     # in 5.6, this is character oriented, so UTF8 characters are counted as 1 character.
		my @nbytes = split(//, $str);  # in 5.6, this is byte-oriented, so UTF8 sequences get split into their component bytes.
		if ($strlen == @nbytes) {
			$packstr = "C*";
		}
		# otherwise the string has more bytes than characters, hence some characters are wide, hence we can use the U* template safely.
	}

	my @ords = unpack($packstr, $str);
	my $rv = '';
	foreach my $ordn (@ords) {
		if ($ordn < 256) {
			if (
				($ordn >= 0x30 && $ordn <= 0x39) ||   # 0 to 9, Unicode code points.
				($ordn >= 0x41 && $ordn <= 0x5A) ||   # A to Z
				($ordn >= 0x61 && $ordn <= 0x7A)      # a to z
			) {
				$rv .= chr($ordn);	# the literal character
			} else {
				$rv .= sprintf("%%%02X", $ordn);      # use the %ff escape
			}
		} else {
			$rv .= sprintf("%%{%X}", $ordn);          # use the %{fff...} escape
		}
	}
	return $rv;
}

sub _str_indent {
	my($depth, @items) = @_;
	return ("\t"x$depth).join('', grep defined $_, @items);
}
sub _wraptag {
	my($name, $v, $depth, $content) = @_;
	my $wrapc = ref $v eq 'ARRAY' ? [qw/[ ]/] : [qw/< >/];
	my $str = '';
	$depth ||= 0;
	$str .= _str_indent($depth, $wrapc->[0], $name, $wrapc->[1], "\n");
	$str .= defined $content ? $content : '';
	$str .= _str_indent($depth, $wrapc->[0].'/', $name, $wrapc->[1], "\n");
	return $str;
}

sub _serialise_type {
	my($self, $data, $opt, $depth) = @_;
	my $type = ref($data);
	my @list = $type eq 'HASH' ? (sort keys %$data) : @$data;
	my($pathstack, $referencelut, $use_quotes, $use_equals, $useref) =
		map $opt->{$_}, qw/pathstack referencelut UseQuotes WriteWithEquals
				WriteWithReferences/;
	my $equals_string = $use_equals ? '= ' : '';
	my $quote_mark = $use_quotes ? "'" : '';
	my $string = '';
	my $i = -1;

	foreach my $k (@list) {
		my($v, $el_str);

		if($type eq 'HASH') { # hash
			$v = $data->{$k};
			_ok_token($k);
			push(@$pathstack, $k);
			$el_str = qq/key '$k'/;
		} else {              # array
			$v = $k;
			$k = $self->_unique_id();
			_ok_listitem($v, $use_quotes);
			push(@$pathstack, ++$i);
			$el_str = qq/element index $i/;
		}
		my $path = join('->', @$pathstack);
		TRACE(__PACKAGE__."::_serialise Path: $path is " . (defined($v) ? $v : 'undef'));

		if (defined $v and ref $v) {
			if ($useref && exists($referencelut->{$v}) && length($referencelut->{$v})) {
				$string .= _str_indent
					($depth, sprintf("\@reference %s%s\n",
									 $type eq 'HASH' ? "$k " : "",
									 $referencelut->{$v}));
			} else {
				my $tagname = $k;
				$tagname = (ref $v eq 'HASH' ? 'hash' : 'list').$tagname
					if $type eq 'ARRAY';  # prefix tagname
				$referencelut->{$v} = $path;
				$string .= join
					('', _wraptag($tagname, $v, $depth,
									_serialise($self, $v, $opt, $depth+1)));
			}
		} else {
			my $localv = $opt->{Escapes} ? _escape($v) : $v;
			my $flag = 1;

			if (!defined($localv) || !length($localv)) {
				if ($opt->{AllowEmptyValues}) {
					$localv = '';
				} else {
					$self->_invalid_line ( "not writing an empty value for $el_str (full path '$path') because the AllowEmptyValues option is false\n" );
					$flag = 0;
				}
			}
			if ($flag) {
				my @el = ($quote_mark, $localv, $quote_mark, "\n");
				unshift @el, ($k, " ", $equals_string) if $type eq 'HASH';
				$string .= _str_indent($depth, @el);
			}
		}
		pop(@$pathstack);
	} #end foreach

	return $string;
}

sub _serialise {
	my ($self, $data, $opt, $depth) = @_;

	$opt->{referencelut} ||= {};
	$opt->{pathstack} ||= [];
	$depth ||= 0;

	TRACE(__PACKAGE__."::_serialise depth $depth");
	croak(ERR_MAX_SER_DEPTH_EXCEEDED) if $depth > MAX_SER_DEPTH;

	return $self->_serialise_type($data, $opt, $depth);
}

sub _nonexistant_var {
	my ($self, $error) = @_;

	return unless $self->{'current_options'}{'DieOnNonExistantVars'};
		
	die ($self->{'errorprefix'} . $error);
}

sub _invalid_line {
	my ($self, $error) = @_;

	# should we be ignoring invalid lines?
	return if $self->{'current_options'}{'IgnoreInvalidLines'};
	
	TRACE("Strict = " . $self->{'current_options'}{'Strict'} );
	if ($self->{'current_options'}{'Strict'})
	{
		die ($self->{'errorprefix'} . $error);
	}
	else
	{
		warn ($self->{'errorprefix'} . $error . " [warning]");
	}
}

# block elements inside lists have their names discarded, so we need to recreate a name
sub _unique_id {
	my $self = shift;
	return ++$self->{'UniqueIdCounter'};
}

# hash, list and item names must be \w\-\. only, so let's stop ConfigWriter creating bad file
sub _ok_token {
	my $str = $_[0];
	croak(ERR_BADTOK . $str . '"') if (!defined($str) || $str !~ m/^[\w\-\.]+$/);
}

sub _ok_listitem {
	my ($str, $quo) = @_;
	if ($quo) {
		croak(ERR_BADLISTITEM_QUOTE . $str . '"') if ("'$str'" !~ m/$RE_DATASINGQUOTE/);
	} else {
		croak(ERR_BADLISTITEM . $str . '"') if ($str !~ m/$RE_DATASING/);
	}
}

# Debugging stubs
sub TRACE {}
sub DUMP {}

1;

########################################################################
# POD
########################################################################

=head1 NAME

Config::Wrest - Read and write Configuration data With References, Environment variables, Sections, and Templating

=head1 SYNOPSIS

	use Config::Wrest;
	my $c = new Config::Wrest();

	# Read configuration data from a string, or from a reference to a string
	my $vars;
	$vars = $c->deserialize($string);
	$vars = $c->deserialize(\$string);

	# Write configuration data as a string
	my $string = $c->serialize(\%vars);
	# ...write the data into a specific scalar
	$c->serialize(\%vars, \$string);

	# Convenience methods to interface with files
	$vars = $c->parse_file($filename);
	$c->write_file($filename, \%vars);

=head1 DESCRIPTION

This module allows you to read configuration data written in a human-readable and easily-editable text format
and access it as a perl data structure. It also allows you to write configuration data from perl back to this format.

The data format allows key/value pairs, comments, escaping of unprintable or problematic characters,
sensible whitespace handling, support for Unicode data,
nested sections, or blocks, of configuration data (analogous to hash- and array-references), and the optional
preprocessing of each line through a templating engine. If you choose to use a templating engine then, depending
on the engine you're using, you can interpolate other values into the data, interpolate environment variables,
and perform other logic or transformations. The data format also allows you to use directives to alter the behaviour
of the parser from inside the configuration file, to set variables, to include other files, and for other
actions.

Here's a brief example of some configuration data. Note the use of quotes, escape sequences, and nested blocks:

	Language =  perl
	<imageinfo>
		width = 100     # This is an end-of-line comment
		height  100
		alt_text " square red image, copyright %A9 2001 "
		<Nestedblock>
			colour red
		</>
		[Suffixes]
			.jpg
			.jpeg
		[/]
	</imageinfo>
	@include path/to/file.cfg
	[Days]
		Sunday
		Can%{2019}t
		'Full Moon'
		<weekend>
			length 48h
		</>
		# and so on... This is a full-line comment
	[/]

This parses to the perl data structure:

	{
		Language => 'perl',
		imageinfo => {
			width => '100',
			height => '100',
			alt_text => " square red image, copyright \xA9 2001 ",
			Nestedblock => {
				colour => 'red'
			},
			Suffixes => [
				'.jpg',
				'.jpeg'
			],
		},
		Days => [
			'Sunday',
			"Can\x{2019}t",	# note the Unicode character in this string
			'Full Moon',
			{
				'length' => '48h'
			}
		],
		# ...and of course, whatever data was read from the included file "path/to/file.cfg"
	}

Of course, your configuration data may not need to use any of those special features, and might simply be key/value pairs:

	Basedir   /usr/local/myprogram
	Debug     0
	Database  IFL1

This parses to the perl data structure:

	{
		Basedir => '/usr/local/myprogram',
		Debug => '0',
		Database => 'IFL1',
	}

These data structures can be serialized back to a textual form using this module.

For details of the data format see L</DATA FORMAT> and L</DIRECTIVES>. Also see L</CONSTRUCTOR OPTIONS> for options
which affect the parsing of the data. All file input and output goes through L<File::Slurp::WithinPolicy>.

=head2 MODULE NAME

Although the "Wrest" in the module's name is an abbreviation for its main features, it also means
"a key to tune a stringed instrument" or "active or moving power". (Collaborative International Dictionary of English)
You can also think of it wresting your configuration data from human-readable form into perl. 

=head1 METHODS

=over 4

=item new( %OPTIONS )

Return a new object, configured with the given options - see L</CONSTRUCTOR OPTIONS>.

=item deserialize( $STRING ) or deserialize( \$STRING )

Given either a string containing configuration data, or a reference to such a string, attempts to parse it
and returns the configuration information as a hash reference.
See L</READING DATA> for details of warnings and errors.

=item serialize( \%VARS ) or serialize( \%VARS, \$STRING )

Given a reference to a hash of configuration data, turns it back into its textual representation.
If no string reference is supplied then this text string is returned, otherwise it is written into the
given reference. See L</WRITING DATA> for details of warnings and errors.

=item deserialise()

An alias for deserialize()

=item serialise()

An alias for serialize()

=item parse_file( $FILEPATH )

Read the specified file, deserialize the contents and return the configuration data.

=item write_file( $FILEPATH, \%VARS )

Serializes the given configuration data and writes it to the specified file.

=back

=head1 CONSTRUCTOR OPTIONS

These are the options that can be supplied to the constructor, and some may meaningfully be modified by the
@option directive - namely the UseQuotes, Escapes, Subs and TemplateBackend options.
Some of these option are turned on by default.

=over 4

=item AllowEmptyValues

Default is 1. 
In this configuration data, one of the keys - "Wings" - has no value against it:

	Species cod
	Category fish
	Wings

By default this will be interpreted as the empty string. If this option is set to false then
the line will be skipped. A warning will also be emitted unless the IgnoreInvalidLines option is true.

This option also affects the serialization of data. When it's true it will also allow the serializer
to create a configuration line like the "Wings" example, i.e. a key with an empty value, and
allow serialization of empty values in arrays.
However, if AllowEmptyValues was false then the serializer would see that the
value for "Wings" was empty and would skip over it, emitting a warning by default.
See the 'IgnoreInvalidLines' option for a way to suppress these warnings.

If you want to read an empty value in a list it needs to be quoted (see the UseQuotes option) otherwise it'll
look like a completely blank line:

	[valid]
		'green'
		''
	[/]

Similarly, the UseQuotes option should be in effect if you wish to write out empty values in list blocks, so that they
do not appear as blank lines.

=item DieOnNonExistantVars

Default is 1.
Usually the parser will die() if the configuration data references a variable
that has not been previously declared. However, setting this option to 0 will
disable this behaviour and silently continue parsing.

=item Escapes

Default is 1. 
Translates escape sequences of the form '%[0-9a-fA-F][0-9a-fA-F]' or '%{[0-9a-fA-F]+}'into the character represented by the given hex number.
E.g. this is useful for putting in newlines (%0A) or carriage-returns (%0D), or otherwise storing arbitrary data.
The two-character form, %FF, is of course only useful for encoding characters in the range 0 to 255. The multi-character form
can be used for a hex number of any length, e.g. %{A}, %{23}, %{A9}, %{153}, %{201C}. See L</UNICODE HANDLING>
for more information.

This value is also used when serializing data. If true then the serialized data will have non-alphanumeric characters escaped.

=item IgnoreInvalidLines

Default is 0.
Disables warn()'ings that would normally occur when the parser encountered a line that couldn't be 
understood or was invalid. Also disables the warning when 'AllowEmptyValues' is false and you are
attempting to serialize() an empty or undefined value.

=item IgnoreUnclosedTags

Default is 0.

By default, should the configuration data have an unbalanced number of opening
and closing tags, an error will be generated to this effect. If
IgnoreUnclosedTags is set to 1 then this error will be downgraded to a
warning.

=item Strict

Default is 1.

By default any errors in the configuration will result in an error being
thrown containing related details. To override this behaviour set the "Strict"
option to 0, this will convert these errors into warnings and processing will
continue.

=item Subs

Default is 0. By default the configuration lines are read verbatim. However, sometimes you want to be able to pick data from
the environment, or you want to set a common string e.g. at the top of the file or in the Variables option (see below).
This re-use or interpolation of values can save lots of repetition, and improve portability of configuration files.
This module implements this kind of interpolation and re-use by giving you the ability to pass each line through
a templating engine.

Simply set this option to 1 to make every line pass through Any::Template (which is loaded on demand) before being parsed.
As each line is read it is turned into a new Any::Template object, and then the process() method is given all of the configuration
data that has been read so far, and whatever data was provided in the Variables option (see below).

Here's an example of how you could use the feature, using a templating engine which looks in the data structure (mentioned above) and
in the environment for its values. The template syntax is simply C<[INSERT I<variable>]> to insert a value, and let's assume that
the environment variable DOCROOT is set to '/home/system'. So if Subs is true then the following lines:

	Colour = 'red'
	@set FILE_SUFFIX cfg
	Filename	[INSERT DOCROOT]/data/testsite/[INSERT Colour]/main.[INSERT FILE_SUFFIX]

will be parsed into:

	{
		'Colour' => 'red',
		'Filename' => '/home/system/data/testsite/red/main.cfg'
	}

Obviously that's a simple example but shows how this feature can be used to factor out common values.
Your Any::Template-compatible templating engine may provide far more advanced features which you're also free to use.

Note that keys in the Variables option override the keys derived from the configuration data so far.
If the configuration data contains blocks then these will be available in the template's data structure as the appropriate
hash- or array-references, just as would be returned by the deserialize() method.
Also note that after the templating step, the "line" may now actually contain line breaks - and if it does the parser will
continue to work through each line, parsing each line separately. The current line will of course not be passed
through the templating engine again, but any subsequent lines will be.

You can always use the Escapes feature to include unusual characters in your data if your templating engine is able to
escape data in the right way.

After the templating step, the line is then parsed as usual. See the @reference directive (L</DIRECTIVES>) for a related concept,
where you can refer back to earlier values and blocks in their entirety.

=item TemplateBackend

Only relevant if 'Subs' is true. Choose which 'Backend' to use with Any::Template. The default is empty, which means
that Any::Template will use an environment variable to determine the default Backend - see L<Any::Template> for details.

=item TemplateOptions

Only relevant if 'Subs' is true.
Some Any::Template backends take a hash-reference as an 'Options' constructor parameter. Set this option to the required
hash-reference and it will be passed to the Any::Template constructor. Note that if the backend is changed
by using a directive like '@set TemplateBackend Foo' this TemplateOptions will still be used.

=item UseQuotes

Default is 1. 
If a value read from the config file is quoted (with matching C<'> or C<">), remove the quotes. Useful for including explicit whitespace.
This option is also used when serializing data - if this option is true then values will always be written out with quotes.

=item Variables

A reference to a hash which contains the names of some variables and their appropriate values. Only used when the Subs option
is in effect. Note that this copied before use (using dclone() from L<Storable>, loaded on demand) which means
that the original data structure should be unaffected by @set directives, and that you can use the Config::Wrest
object multiple times and the same data structure is used every time.

=item WriteWithEquals

Default is 0. When serializing data, keys and values will be separated by '='.

=item WriteWithHeader

Default is 1. When serializing data, the default behaviour is to emit lines at the start indicating the
software that serialized the data and the specific settings of the AllowEmptyValues, Escapes, and UseQuotes
directives. This option suppresses those lines.

=item WriteWithReferences

Default is 0. If true then an appropriate '@reference' directive will be emitted during serialization
whenever a perl data structure is referred to for the second, or subsequent, times.

=back

=head1 DATA FORMAT

The data is read line-by-line. Comments are stripped and blank lines are ignored.
You can't have multiple elements (key/value pairs, values in a list block, block opening tags,
block closing tags, or directives) on a single line - you may only have one such element per line.
Both the newline and carriage return characters (\n and \r) are considered as line breaks, and hence
configuration files can be read and written across platforms (see L</UNICODE HANDLING>).

Data is stored in two ways: as key/value pairs, or as individual values when inside a "list block".
Hash or list blocks may be nested inside other blocks to arbitrary depth.

=head2 KEY VALUE PAIRS

Lines such as these are used at the top level of the configuration file, or inside L</HASH BLOCKS>.
The line simply has a key and a value, separated by whitespace or an '=' sign:

	colour=red
	name  =   "Scott Tiger"
	Age 23
	Address foo%40example.com

The 'key' can consist of "\w" characters, "." and "-".
VALUE can include anything but a '#' to the end of the line.
See Escapes and UseQuotes in L</CONSTRUCTOR OPTIONS>.

=head2 SINGLE VALUES

Lines such as these are used inside L</LIST BLOCKS>. The value is simply given:

	Thursday
	"Two Step"
	apple%{2019}s

These may not begin with these characters: '[', 'E<lt>', '(', '{', ':', '@', '%', '/'
because they are the first thing in a line and such characters would be confused
with actual tags and reserved characters. See Escapes and UseQuotes in L</CONSTRUCTOR OPTIONS>
if your value begins with any of these, or if you want to include whitespace.

=head2 COMMENTS

Comments may be on a line by themselves:

	# Next line is for marketing...
	Whiteness = Whizzy Whiteness!

or at the end of a line:

	Style=Loads of chrome	  # that's what marketing want

Note that everything following a '#' character (in Unicode that's called a "NUMBER SIGN") is taken to be a comment, so if you want
to have an actual '#' in your data you must have the Escapes option turned on (see L</CONSTRUCTOR OPTIONS>) e.g.:

	Colour   %23FF9900

even if the '#' is in the middle of a quoted string:

	Foo "bar#baz" # a comment

is equivalent to:

	Foo "bar

=head2 HASH BLOCKS

A block which contains L</KEY VALUE PAIRS>, or other blocks. They look like:

	<Blockname>
		colour red
		# contents go here
	</Blockname>

For convenience you can omit the block's name in the closing tag, like this:

	<Anotherblock>
		Age 23
		# contents go here
	</>

The name of the block can consist of "\w" characters, "." and "-".

=head2 LIST BLOCKS

A block which contains a list of L</SINGLE VALUES>, or other blocks. They look like:

	[Instruments]
		bass
		guitar
	[/Instruments]

and you can omit the name in the closing tag if you wish:

		# ...
		guitar
	[/]

The name of the block can consist of "\w" characters, "." and "-".

=head2 WHITESPACE RULES

In L</KEY VALUE PAIRS> the '=' between the Name and Value is optional, but it can have whitespace before and/or after it. If 
there's no '=' you need whitespace to separate the Name and Value.

Block opening and closing tags cannot have whitespace inside them.

Lines may be indented by arbitrary whitespace. Trailing whitespace is stripped from values (but 
see the UseQuotes and Escapes entries in L</CONSTRUCTOR OPTIONS>).

=head2 ESCAPING

Sometimes you want to specify data with characters that are unprintable, hard-to type or have special meaning to Config::Wrest.
You can escape such characters using two forms. Firstly, the '%' symbol followed by two hex digits, e.g. C<%A9>, for
characters up to 255 decimal. Secondly you can write '%' followed by any hex number in braces, e.g. C<%{201c}> to specify
any character by its Unicode code point.
See 'Escapes' under L</CONSTRUCTOR OPTIONS>.

=head2 DIRECTIVES

The configuration file itself can contain lines which tell the parser how to behave.
All directive lines begin with an '@'. For example you can turn on
the URL-style escaping, you can set variables, and so on. 
These are recognized directives:

=over 4

=item @include FILENAME

Insert a file into the current configuration in place of this directive, and continue reading configuration information.
This file is simply another file of Config::Wrest lines. If any options are set in the include, or in any nested includes,
the effect of them will persist after the end of that file - i.e. when a file is included it is effectively merged with 
the parent file's contents.
The filename is treated according to the current setting of the UseQuotes and Escapes options.

=item @option NAME VALUE

Allows you to alter the VALUE of the parser option called NAME that is otherwise set in the perl interface. See L</CONSTRUCTOR OPTIONS>.
The value is treated according to the current setting of the UseQuotes and Escapes options.

=item @reference [ NAME ] PATH

Allows you to tell the parser to re-use a previous data value and put it in the current location against the given key 'NAME'
- inside hash blocks the 'NAME' is required, but inside list blocks the 'NAME' is optional and effectively ignored. This feature allows you to 
have a block or value in your config file which is re-used many times further on in the file. The 'NAME' has the same restriction
as for all other key names. The 'PATH' is a string which specified the data item (which may be a plain value or a block)
that you wish to reference, and is built up by joining a sequence of hash keys and array indexes together with '->' arrows.
E.g. if you look at the example in L</DESCRIPTION> then the path 'imageinfo->Nestedblock' refers to that hash block,
'imageinfo->Nestedblock->colour' refers the value 'red', and 'Days->0' is the value 'Sunday'.
The 'PATH' is treated according to the current setting of the UseQuotes and Escapes options.

Note that this is a different
operation to using the 'Subs' feature because this directive uses actual perl data references, rather than inserting
some text which is then parsed into data structures, and hence can deal simply with complex structures. It is possible
to construct circular data structures using this directive.

=item @set NAME VALUE

Set a variable with the given NAME to any given VALUE, so that you may use that variable later on, if you've set the Subs option.
The variable name must consist of alphanumeric and underscore characters only.
The value is treated according to the current setting of the UseQuotes and Escapes options.

=back

=head2 UNICODE HANDLING

This section has been written from the point-of-view of perl 5.8, although the concepts translate to perl 5.6's
slightly different Unicode handling.

First it's important to differentiate between configuration data that is given to deserialize() as a string which contains
wide characters (i.e. code point >255), and data which contains escape sequences for wide characters. Escape sequences
can only occur in certain places, whereas actual wide characters can be used in key names, block names, directives and
in values. This is because the parser uses regular expressions which use metacharacters such as "\w", and these can
match against some wide characters.

Although you can use wide characters in directives, it may make no sense to try to "@include" a filename which contains
wide characters.

Configuration data will generally be read to or written from a file at some stage. You should be aware that
File::Slurp::WithinPolicy uses File::Slurp which reads files in byte-oriented fashion. 
If this is not what you want, e.g. if your config files contain multi-byte characters such as UTF8,
then you should either read/write the file yourself using the appropriate layer
in the arguments to open(), or use the Encode module to go between perl's Unicode-based strings and the required
encoding (e.g. your configuration files may be stored on disk as ISO-8859-1, but you want it to be read into perl
as the Unicode characters, not as a stream of bytes). Similarly, you may wish to use Encode or similar to turn
a string into the correct encoding for your application to use.

Unicode specifies a number of different characters that should be considered as line endings: not just u000A and u000D,
but also u0085 and several others. However, to keep this module compatible with perl versions before 5.8 this
module splits data into lines on the sequence "\x0D\x0A" B<or> on the regular expression C</[\n\r]/>, and does B<not>
split on any of the other characters given in the Unicode standard. If you want your configuration data to use any of the
other line endings you must read the file yourself, change the desired line ending to C<\n> and pass that string
to deserialize(). Reverse the process when using serialize() and writing files. E.g. on an OS/390 machine a
configuration file may be stored with C<NEL> (i.e. "\x85") line endings which need to be changed when reading it
on a Unix machine.

This module has not been tested on EBCDIC platforms.

=head1 READING DATA

If you try to deserialize configuration data that has the wrong syntax (e.g. mis-nested blocks, or too many closing tags)
a fatal error will be raised.

Unrecognized directives cause a warning, as will key/value lines appearing in a list block, or list items appearing in a
hash block (see AllowEmptyValues in L</CONSTRUCTOR OPTIONS>). You also get a warning if there were too few closing tags
and the parse implicitly closed some for you.

=head1 WRITING DATA

The data structure you want to serialize must be a hash reference. The values may be strings, arrayrefs or hashrefs,
and so on recursively. Any bad reference types cause a fatal croak().

You are only allowed to use a restricted set of characters as hash keys, i.e. the names of block elements
and the key in key/value pairs of data. If your data structure has a hash key that could create bad
config data a fatal error is thrown with croak(). Values in list blocks are also checked, and a fatal error is raised
if the value would create bad config data.

In general you will want to use the 'Escapes' option described above. This makes it hard to produce bad configuration files.

If you want to dump out cyclic / self-referential data structures you'll need to set the 'WriteWithReferences' option, otherwise the deep recursion
will be detected and the serialization will throw a fatal error.

=head1 SEE ALSO

parse_file(), write_file() and the '@include' directive load L<File::Slurp::WithinPolicy> on demand to perform the file input/output operations.
See L<perlunicode> for more details on perl's Unicode handling, and L<Encode> for character recoding.
See L<Any::Template>, and the relevant templating modules, if the 'Subs' option is true.

Although this module can read and write data structures it is not intended as an all-purpose serialization system. For that
see L<Storable>.

Unicode Newline Guidelines from http://www.unicode.org/versions/Unicode4.0.0/ch05.pdf#G10213

=head1 VERSION

$Revision: 1.36 $ on $Date: 2006/08/22 14:09:50 $ by $Author: mattheww $

=head1 AUTHOR

IF&L Software Engineers <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
