package Data::Roundtrip;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.30';

# import params is just one 'no-unicode-escape-permanently'
# if set, then unicode escaping will not happen at
# all, even if 'dont-bloody-escape-unicode' is set.
# Dump's filter and Dumper's qquote overwrite will be permanent
# which is more efficient but removes the flexibility
# of having unicode escaped and rendered at will.

use Encode qw/encode_utf8 decode_utf8/;
use JSON qw/decode_json encode_json/;
use Unicode::Escape qw/escape unescape/;
# YAML v1.30 fails for {"\"aaa'bbb" => "aaa","bbb" => 1,}
# while YAML::PP and YAML::XS both succeed
# YAML::PP is less restrictive so using this
# YAML v1.31 now behaves correctly, run 'make deficiencies' to see that
# but since YAML author urges not use this module, we will
# be using YAML::PP
#use YAML;
use YAML::PP qw/Load Dump/;
# this also works with the tricky cases but it needs compilation
# on M$ systems and that can be tricky :(
#use YAML::XS;

use Data::Dumper qw/Dumper/;
use Data::Dump qw/pp/;
use Data::Dump::Filtered;

use Exporter;
# the EXPORT_OK and EXPORT_TAGS is code by [kcott] @ Perlmongs.org, thanks!
# see https://perlmonks.org/?node_id=11115288
our (@EXPORT_OK, %EXPORT_TAGS);

my $_permanent_override = 0;
my $_permanent_filter = 0;

# THESE are taken verbatim from Data::Dumper (Data/Dumper.pm)
# they are required for _qquote_redefinition_by_Corion()
# which needed to access them as, e.g.  %Data::Dumper::esc
# because they are private vars, they are not coming out!
# and so here they are:
my $Data_Dumper_IS_ASCII  = ord 'A' ==  65;
my %Data_Dumper_esc = ( 
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);
my $Data_Dumper_low_controls = ($Data_Dumper_IS_ASCII) 

                   # This includes \177, because traditionally it has been
                   # output as octal, even though it isn't really a "low"
                   # control
                   ? qr/[\0-\x1f\177]/

                     # EBCDIC low controls.
                   : qr/[\0-\x3f]/;
# END verbatim from Data::Dumper (Data/Dumper.pm)

BEGIN {
	my @file = qw{read_from_file write_to_file};
	my @fh = qw{read_from_filehandle write_to_filehandle};
	my @io = (@file, @fh);
	my @json = qw{perl2json json2perl json2dump json2yaml json2json jsonfile2perl};
	my @yaml = qw{perl2yaml yaml2perl yaml2json yaml2dump yaml2yaml yamlfile2perl};
	my @dump = qw{perl2dump perl2dump_filtered perl2dump_homebrew};
	# these have now (v0.28) been removed from @dump: dump2perl dump2json dump2yaml dump2dump
	# they need to be explicitly imported *individually*
	# because of the danger that the eval() in dump2perl()
	# poses. They can not be imported with any EXPORT_TAG
	my @explicit = qw{dump2perl dump2json dump2yaml dump2dump};
	my @all = (@io, @json, @yaml, @dump);
	@EXPORT_OK = (@all, @explicit);
	%EXPORT_TAGS = (
	    file => [@file],
	    fh   => [@fh],
	    io   => [@io],
	    json => [@json],
	    yaml => [@yaml],
	    dump => [@dump],
	    all  => [@all],
	);
} # end BEGIN

sub DESTROY {
	Data::Dump::Filtered::remove_dump_filter( \& DataDumpFilterino )
		if $_permanent_filter;
}

sub import {
	# what comes here is (package, param1, param2...) = @_
	# for something like
	# use Data::Roundtrip qw/param1 params2 .../;
	# we are looking for a param, eq to 'no-unicode-escape-permanently'
	# or 'unicode-escape-permanently'
	# the rest we must pass to the Exporter::import() but in a tricky way
	# so as it injects all these subs in the proper namespace.
	# that call is at the end, but with our parameter removed from the list
	for(my $i=@_;$i-->1;){
		if( $_[$i] eq 'no-unicode-escape-permanently' ){
			splice @_, $i, 1; # remove it from the list
			$Data::Dumper::Useperl = 1;
			$Data::Dumper::Useqq='utf8';
			no warnings 'redefine';
			*Data::Dumper::qquote = \& _qquote_redefinition_by_Corion;
			$_permanent_override = 1;

			# add a filter to Data::Dump
			Data::Dump::Filtered::add_dump_filter( \& DataDumpFilterino );
			$_permanent_filter = 1;
		} elsif( $_[$i] eq 'unicode-escape-permanently' ){
			splice @_, $i, 1; # remove it from the list
			# this is the case which we want to escape unicode permanently
			# which is the default behaviour for Dump and Dumper
			$_permanent_override = 2;
			$_permanent_filter = 2;
		}
	}
	# now let Exporter handle the rest of the params if any
	# from ikegami at https://www.perlmonks.org/?node_id=1214104
	goto &Exporter::import;
}

sub	perl2json {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};
	my $pretty_printing = exists($params->{'pretty'}) && defined($params->{'pretty'})
		? $params->{'pretty'} : 0
	;
	my $escape_unicode = exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		? $params->{'escape-unicode'} : 0
	;
	my $convert_blessed = exists($params->{'convert_blessed'}) && defined($params->{'convert_blessed'})
		? $params->{'convert_blessed'} : 0
	;
	my $json_string;
	# below we check $json_string after each time it is set because of eval{} and
	# don't want to loose $@
	my $encoder = JSON->new;
	$encoder = $encoder->pretty if $pretty_printing;
	# convert_blessed will allow when finding objects to
	# ask them if they have a TO_JSON method which returns
	# the object as a perl data structure which is then converted
	# to JSON.
	# for example if your object stores the important data you
	# want to print in $self->{'data'}
	# then sub TO_JSON { shift->{'data'} }
	# see https://perldoc.perl.org/JSON::PP#2.-convert_blessed-is-enabled-and-the-object-has-a-TO_JSON-method.
	$encoder = $encoder->convert_blessed if $convert_blessed;
	if( $escape_unicode ){
		$json_string = eval { $encoder->utf8(1)->encode($pv) };
		if( ! defined($json_string) ){ print STDERR "error, call to ".'JSON->new->utf8(1)->encode()'." has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
		if ( _has_utf8($json_string) ){
			$json_string = Unicode::Escape::escape($json_string, 'utf8');
			if( ! defined($json_string) ){ print STDERR "error, call to ".'Unicode::Escape::escape()'." has failed.\n"; return undef }
		}
	} else {
		$json_string = eval { $encoder->utf8(0)->encode($pv) };
		if( ! defined($json_string) ){ print STDERR "error, call to ".'JSON->new->utf8(0)->pretty->encode()'." has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
	}
	# succeeded here
	return $json_string
}
sub	perl2yaml {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};
	my $pretty_printing = exists($params->{'pretty'}) && defined($params->{'pretty'})
		? $params->{'pretty'} : 0
	;
	print STDERR "perl2yaml() : pretty-printing is not supported for YAML output\n" and $pretty_printing=0
		if $pretty_printing;

	my $escape_unicode = exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		? $params->{'escape-unicode'} : 0
	;
	my ($yaml_string, $escaped);
	if( $escape_unicode ){
		#if( $pretty_printing ){
			# it's here just for historic purposes, this is not supported and a warning is issued
			#$yaml_string = eval { YAML::PP::Dump($pv) };
			#if( ! defined $yaml_string ){ print STDERR "error, call to ".'YAML::PP::Dump()'." has failed with this exception:\n".$@."\n"; return undef }
			# this does not work :( no pretty printing for yaml
			#$yaml_string = Data::Format::Pretty::YAML::format_pretty($pv);
		#} else {
			# intercepting a die by wrapping in an eval
			$yaml_string = eval { YAML::PP::Dump($pv) };
			if( ! defined($yaml_string) ){ print STDERR "error, call to ".'YAML::PP::Dump()'." has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
		#}
		if( ! $yaml_string ){ print STDERR "perl2yaml() : error, no yaml produced from perl variable.\n"; return undef }
		if( _has_utf8($yaml_string) ){
			utf8::encode($yaml_string);
			$yaml_string = Unicode::Escape::escape($yaml_string, 'utf8');
		}
	} else {
		#if( $pretty_printing ){
			# it's here just for historic purposes, this is not supported and a warning is issued
			#$yaml_string = Data::Format::Pretty::YAML::format_pretty($pv);
		#} else {
			$yaml_string = eval { YAML::PP::Dump($pv) };
			if( ! defined($yaml_string) ){ print STDERR "error, call to ".'YAML::PP::Dump()'." has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
		#}
		if( ! $yaml_string ){ print STDERR "perl2yaml() : error, no yaml produced from perl variable.\n"; return undef }
	}
	return $yaml_string
}
sub	yaml2perl {
	my $yaml_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	# intercepting a die by wrapping in an eval
	# Untainting YAML::PP string input because of a bug that causes it to bomb
	# see https://perlmonks.org/?node_id=11154911
	# untaint recipe by ysth, see
	#    https://www.perlmonks.org/?node_id=516862
	# but it  gives a warning:
	#    each on anonymous hash will always start from the beginning
	#($yaml_string) = each %{{$yaml_string,0}};
	# and so we do this instead
	# Also, there is a test which check yaml with tainted input (string)
	#    t/14-yaml-tainted-input.t
	($yaml_string) = keys %{{$yaml_string,0}};
	my $pv = eval { YAML::PP::Load($yaml_string) };
	if( ! defined($pv) ){ print STDERR "yaml2perl() : error, call to YAML::PP::Load() has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
	return $pv
}
sub	yamlfile2perl {
	my $yaml_file = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	my $contents = read_from_file($yaml_file);
	if( ! defined $contents ){ print STDERR "yamlfile2perl() : error, failed to read from file '${yaml_file}'.\n"; return undef }
	my $pv = yaml2perl($contents);
	if( ! defined $pv ){ print STDERR "yamlfile2perl() : error, call to yaml2perl() has failed after reading yaml string from file '${yaml_file}'.\n"; return undef }
	return $pv;
}
sub	json2perl {
	my $json_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	my $pv;
	if( _has_utf8($json_string) ){
		# intercepting a die by wrapping in an eval
		$pv = eval { JSON::decode_json(Encode::encode_utf8($json_string)) };
		if( ! defined($pv) ){ print STDERR "json2perl() :  error, call to json2perl() has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception: $@:":".")."\n"; return undef }
	} else {
		# intercepting a die by wrapping in an eval
		$pv = eval { JSON::decode_json($json_string) };
		if( ! defined($pv) ){ print STDERR "json2perl() :  error, call to json2perl() has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception: $@:":".")."\n"; return undef }
	}
	return $pv;
}
sub	jsonfile2perl {
	my $json_file = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	my $contents = read_from_file($json_file);
	if( ! defined $contents ){ print STDERR "jsonfile2perl() : error, failed to read from file '${json_file}'.\n"; return undef }
	my $pv = json2perl($contents);
	if( ! defined $pv ){ print STDERR "jsonfile2perl() : error, call to json2perl() has failed after reading json string from file '${json_file}'.\n"; return undef }
	return $pv;
}
sub	json2json {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! defined $pv ){ print STDERR "json2perl() :  error, call to json2perl() has failed.\n"; return undef }
	$json_string = perl2json($pv, $params);
	if( ! defined $json_string ){ print STDERR "json2perl() :  error, call to perl2json() has failed.\n"; return undef }

	return $json_string;
}
sub	yaml2yaml {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = yaml2perl($yaml_string, $params);
	if( ! defined $pv ){ print STDERR "yaml2perl() :  error, call to yaml2perl() has failed.\n"; return undef }
	$yaml_string = perl2yaml($pv, $params);
	if( ! defined $yaml_string ){ print STDERR "yaml2perl() :  error, call to perl2yaml() has failed.\n"; return undef }

	return $yaml_string;
}
sub	dump2dump {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! defined $pv ){ print STDERR "dump2perl() :  error, call to dump2perl() has failed.\n"; return undef }
	$dump_string = perl2dump($pv, $params);
	if( ! defined $dump_string ){ print STDERR "dump2perl() :  error, call to perl2dump() has failed.\n"; return undef }

	return $dump_string;
}
sub	yaml2json {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	# is it escaped already?
	$yaml_string =~ s/\\u([0-9a-fA-F]{4})/eval "\"\\x{$1}\""/ge;
	my $pv = yaml2perl($yaml_string, $params);
	if( ! $pv ){ print STDERR "yaml2json() : error, call to yaml2perl() has failed.\n"; return undef }
	my $json = perl2json($pv, $params);
	if( ! $json ){ print STDERR "yaml2json() : error, call to perl2json() has failed.\n"; return undef }
	return $json
}
sub	yaml2dump {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = yaml2perl($yaml_string, $params);
	if( ! $pv ){ print STDERR "yaml2json() : error, call to yaml2perl() has failed.\n"; return undef }
	my $dump = perl2dump($pv, $params);
	if( ! $dump ){ print STDERR "yaml2dump() : error, call to perl2dump() has failed.\n"; return undef }
	return $dump
}
sub	json2dump {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! $pv ){ print STDERR "json2json() : error, call to json2perl() has failed.\n"; return undef }
	my $dump = perl2dump($pv, $params);
	if( ! $dump ){ print STDERR "json2dump() : error, call to perl2dump() has failed.\n"; return undef }
	return $dump
}
sub	dump2json {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! $pv ){ print STDERR "dump2json() : error, call to dump2perl() has failed.\n"; return undef }
	my $json_string = perl2json($pv, $params);
	if( ! $json_string ){ print STDERR "dump2json() : error, call to perl2json() has failed.\n"; return undef }
	return $json_string
}
sub	dump2yaml {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! $pv ){ print STDERR "yaml2yaml() : error, call to yaml2perl() has failed.\n"; return undef }
	my $yaml_string = perl2yaml($pv, $params);
	if( ! $yaml_string ){ print STDERR "dump2yaml() : error, call to perl2yaml() has failed.\n"; return undef }
	return $yaml_string
}
sub	json2yaml {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! defined $pv ){ print STDERR "json2yaml() :  error, call to json2perl() has failed.\n"; return undef }
	my $yaml_string = perl2yaml($pv, $params);
	if( ! defined $yaml_string ){ print STDERR "json2yaml() :  error, call to perl2yaml() has failed.\n"; return undef }
	return $yaml_string
}
sub	dump2perl {
	# WARNING: we eval() input string with alleged
	# output from Data::Dump. Are you sure you trust
	# the input string ($dump_string) for an eval() ?
	# WARNING-2: I am considering removing this sub in future releases because of the eval()

	# VERSION 0.28: this now needs to be imported explicitly

	my $dump_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};

	$dump_string =~ s/^\$VAR1\s*=\s*//g;
	print STDERR "dump2perl() : WARNING, eval()'ing input string, are you sure you did check its content ?\n";
	print STDERR "dump2perl() : WARNING, this sub will be removed in future releases.\n";
	# WARNING: eval() of unknown input:
	my $pv = eval($dump_string);
	if( ! defined($pv) ){ print STDERR "input string:${dump_string}\nend input string.\ndump2perl() : error, eval() of input string (alledgedly a perl variable, see above) has failed".((defined($@)&&($@!~/^\s*$/))?" with this exception:\n".$@:".")."\n"; return undef }
	return $pv
}
# this bypasses Data::Dumper's obsession with escaping
# non-ascii characters by redefining the qquote() sub
# The redefinition code is by [Corion] @ Perlmonks and cpan
# see https://perlmonks.org/?node_id=11115271
# So, it still uses Data::Dumper to dump the input perl var
# but with its qquote() sub redefined. See section CAVEATS
# for a wee problem that may appear in the future.
# The default behaviour is NOT to escape unicode
# (which is the opposite of what Data::Dumper is doing)
# see options, below, on how to change this.
# input is the perl variable (as a reference, e.g. scalar, hashref, arrayref)
# followed by optional hashref of options which can be
#   terse
#   indent
#   dont-bloody-escape-unicode,
#   escape-unicode,
#   The last 2 control how unicode is printed, either escaped,
#   like \x{3b1} or 'a' <<< which is unicoded greek alpha but did not want to pollute with unicode this file
#   the former behaviour can be with dont-bloody-escape-unicode=>0 or escape-unicode=>1,
#   the latter behaviour is the default. but setting the opposite of above will set it.
# NOTE: there are 2 alternatives to this
# perl2dump_filtered() which uses Data::Dump filters to control unicode escaping but
# lacks in aesthetics and functionality and handling all the cases Dump and Dumper
# do quite well.
# perl2dump_homebrew() uses the same dump-recursively engine but does not involve
# Data::Dump at all.
sub	perl2dump {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	local $Data::Dumper::Terse = exists($params->{'terse'}) && defined($params->{'terse'})
		? $params->{'terse'} : 0
	;
	local $Data::Dumper::Indent = exists($params->{'indent'}) && defined($params->{'indent'})
		? $params->{'indent'} : 1
	;

	if( ($_permanent_override == 0)
        && ((
		exists($params->{'dont-bloody-escape-unicode'}) && defined($params->{'dont-bloody-escape-unicode'})
		 && ($params->{'dont-bloody-escape-unicode'}==1)
	    ) || (
		exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		 && ($params->{'escape-unicode'}==0)
	    )
	   )
	){
		# this is the case where no 'no-unicode-escape-permanently'
		# was used at loading the module
		# we have to use the special qquote each time caller
		# sets 'dont-bloody-escape-unicode'=>1
		# which will be replaced with the original sub
		# once we exit this scope.
		# make benchmarks will compare all cases if you ever
		# want to get more efficiency out of this
		local $Data::Dumper::Useperl = 1;
		local $Data::Dumper::Useqq='utf8';
		no warnings 'redefine';
		local *Data::Dumper::qquote = \& _qquote_redefinition_by_Corion;
		return Data::Dumper::Dumper($pv);
		# out of scope local's will be restored to original values
	}
	return Data::Dumper::Dumper($pv)
}
# This uses Data::Dump's filters
# The _qquote_redefinition_by_Corion() code is by [Corion] @ Perlmonks and cpan
# see https://perlmonks.org/?node_id=11115271
sub	perl2dump_filtered {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	if( ($_permanent_filter == 0)
        && ((
		exists($params->{'dont-bloody-escape-unicode'}) && defined($params->{'dont-bloody-escape-unicode'})
		 && ($params->{'dont-bloody-escape-unicode'}==1)
	    ) || (
		exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		 && ($params->{'escape-unicode'}==0)
	    )
	   )
	){
		Data::Dump::Filtered::add_dump_filter( \& DataDumpFilterino );
		my $ret = Data::Dump::pp($pv);
		Data::Dump::Filtered::remove_dump_filter( \& DataDumpFilterino );
		return $ret;
	}
	return Data::Dump::pp($pv);
}
sub	perl2dump_homebrew {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	if( ($_permanent_override == 1)
        || (
		exists($params->{'dont-bloody-escape-unicode'}) && defined($params->{'dont-bloody-escape-unicode'})
		 && ($params->{'dont-bloody-escape-unicode'}==1)
	    ) || (
		exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		 && ($params->{'escape-unicode'}==0)
	    )
	){
		return dump_perl_var_recursively($pv);
	}
	return Data::Dumper::Dumper($pv);
}
# this will take a perl var (as a scalar or an arbitrarily nested data structure)
# and emulate a very very basic
# Dump/Dumper but with rendering unicode (for keys or values or array items)
# it returns a string representation of the input perl var
# There are 2 obvious limitations:
# 1) indentation is very basic,
# 2) it supports only scalars, hashes and arrays,
#    (which will dive into them no problem)
# This sub can be used in conjuction with DataDumpFilterino()
# to create a Data::Dump filter like,
#    Data::Dump::Filtered::add_dump_filter( \& DataDumpFilterino );
#    or dumpf($perl_var, \& DataDumpFilterino);
# the input is a perl-var as a reference, so no %inp but $inp={} or $inp=[]
# the output is a, possibly multiline, string
sub dump_perl_var_recursively {
	my $inp = $_[0];
	my $depth = defined($_[1]) ? $_[1] : 0;
	my $aref = ref($inp);
	if( $aref eq '' ){
		# scalar
		return _qquote_redefinition_by_Corion($inp);
	} elsif( $aref eq 'SCALAR' ){
		# scalar
		return _qquote_redefinition_by_Corion($$inp);
	} elsif( $aref eq 'HASH' ){
		my $indent1 = ' 'x((2+$depth)*2);
		my $indent2 = $indent1 x 2;
		my $retdump= "\n".$indent1.'{'."\n";
		for my $k (keys %$inp){
			$retdump .= $indent2
				. _qquote_redefinition_by_Corion($k)
			." => "
				. dump_perl_var_recursively($inp->{$k}, $depth+1)
			.",\n"
			;
		}
		return $retdump. $indent1 . '}'
	} elsif( $aref eq 'ARRAY' ){
		my $indent1 = ' ' x ((1+$depth)*2);
		my $indent2 = $indent1 x 2;
		my $retdump= "\n".$indent1.'['."\n";
		for my $v (@$inp){
			$retdump .=
				$indent2
				. dump_perl_var_recursively($v, $depth+1)
				.",\n"
			;
		}
		return $retdump. $indent1 . ']'
	} else {
		my $indent1 = ' ' x ((1+$depth)*2);
		return $indent1 . $inp .",\n"
	}
}
sub DataDumpFilterino {
	my($ctx, $object_ref) = @_;
	my $aref = ref($object_ref);

	return {
		'dump' => dump_perl_var_recursively($object_ref, $ctx->depth)
	}
}
# opens file,
# reads all content of file and returns them on success
# or returns undef on failure
# the file is closed in either case
sub	read_from_file {
	my $infile = $_[0];
	my $FH;
	if( ! open $FH, '<:encoding(UTF-8)', $infile ){
		print STDERR "failed to open file '$infile' for reading, $!";
		return undef;
	}
	my $contents = read_from_filehandle($FH);
	close $FH;
	return $contents
}
# writes contents to file and returns 0 on failure, 1 on success
sub	write_to_file {
	my $outfile = $_[0];
	my $contents = $_[1];
	my $FH;
	if( ! open $FH, '>:encoding(UTF-8)', $outfile ){
		print STDERR "failed to open file '$outfile' for writing, $!";
		return 0
	}
	if( ! write_to_filehandle($FH, $contents) ){ print STDERR "error, call to ".'write_to_filehandle()'." has failed"; close $FH; return 0 }
	close $FH;
	return 1;
}
# reads all content from filehandle and returns them on success
# or returns undef on failure
sub	read_from_filehandle {
	my $FH = $_[0];
	# you should open INFH as '<:encoding(UTF-8)'
	# or if it is STDIN, do binmode STDIN , ':encoding(UTF-8)';
	return do { local $/; <$FH> }
}
sub	write_to_filehandle {
	my $FH = $_[0];
	my $contents = $_[1];
	# you should open $OUTFH as >:encoding(UTF-8)'
	# or if it is STDOUT, do binmode STDOUT , ':encoding(UTF-8)';
	print $FH $contents;
	return 1;
}
# todo: change to utf8::is_utf8()
sub	_has_utf8 { return $_[0] =~ /[^\x00-\x7f]/ }
# Below code is by [Corion] @ Perlmonks and cpan
# see https://perlmonks.org/?node_id=11115271
# it's for redefining Data::Dumper::qquote
# (it must be accompanied by
#  $Data::Dumper::Useperl = 1;
#  $Data::Dumper::Useqq='utf8';
# HOWEVER, I discoverd that a redefined sub can not access packages private vars
sub	_qquote_redefinition_by_Corion {
  local($_) = shift;

  return qq("") unless defined $_;
  s/([\\\"\@\$])/\\$1/g;

  return qq("$_") unless /[[:^print:]]/;  # fast exit if only printables

  # Here, there is at least one non-printable to output.  First, translate the
  # escapes.
   s/([\a\b\t\n\f\r\e])/$Data_Dumper_esc{$1}/g;
  # this is the original but it does not work because it can't find %esc
  # which is a private var in Data::Dumper, so I copied those vars above
  # and access them as Data_Dumper_XYZ
  #s/([\a\b\t\n\f\r\e])/$Data::Dumper::esc{$1}/g;

  # no need for 3 digits in escape for octals not followed by a digit.
  s/($Data_Dumper_low_controls)(?!\d)/'\\'.sprintf('%o',ord($1))/eg;

  # But otherwise use 3 digits
  s/($Data_Dumper_low_controls)/'\\'.sprintf('%03o',ord($1))/eg;


    # all but last branch below not supported --BEHAVIOR SUBJECT TO CHANGE--
  my $high = shift || "";
    if ($high eq "iso8859") {   # Doesn't escape the Latin1 printables
      if ($Data_Dumper_IS_ASCII) {
        s/([\200-\240])/'\\'.sprintf('%o',ord($1))/eg;
      }
      elsif ($] ge 5.007_003) {
        my $high_control = utf8::unicode_to_native(0x9F);
        s/$high_control/sprintf('\\%o',ord($1))/eg;
      }
    } elsif ($high eq "utf8") {
#     Some discussion of what to do here is in
#       https://rt.perl.org/Ticket/Display.html?id=113088
#     use utf8;
#     $str =~ s/([^\040-\176])/sprintf "\\x{%04x}", ord($1)/ge;
    } elsif ($high eq "8bit") {
        # leave it as it is
    } else {
      s/([[:^ascii:]])/'\\'.sprintf('%03o',ord($1))/eg;
      #s/([^\040-\176])/sprintf "\\x{%04x}", ord($1)/ge;
    }
    return qq("$_");
}
# begin pod
=pod

=encoding utf8

=head1 NAME

Data::Roundtrip - convert between Perl data structures, YAML and JSON with unicode support (I believe ...)

=head1 VERSION

Version 0.30

=head1 SYNOPSIS

This module contains a collection of utilities for converting between
JSON, YAML, Perl variable and a Perl variable's string representation (aka dump).
Hopefully, all unicode content will be handled correctly between
the conversions and optionally escaped or un-escaped. Also JSON can
be presented in a pretty format or in a condensed, machine-readable
format (not spaces, indendation or line breaks).

    use Data::Roundtrip qw/:all/;
    #use Data::Roundtrip qw/json2yaml/;
    #use Data::Roundtrip qw/:json/; # see EXPORT

    $jsonstr = '{"Songname": "Απόκληρος της κοινωνίας",'
	       .'"Artist": "Καζαντζίδης Στέλιος/Βίρβος Κώστας"}'
    ;
    $yamlstr = json2yaml($jsonstr);
    print $yamlstr;
    # NOTE: long strings have been broken into multilines
    # and/or truncated (replaced with ...)
    #---
    #Artist: Καζαντζίδης Στέλιος/Βίρβος Κώστας
    #Songname: Απόκληρος της κοινωνίας

    $yamlstr = json2yaml($jsonstr, {'escape-unicode'=>1});
    print $yamlstr;
    #---
    #Artist: \u039a\u03b1\u03b6\u03b1 ...
    #Songname: \u0391\u03c0\u03cc\u03ba ...

    $backtojson = yaml2json($yamlstr);
    # $backtojson is a string representation
    # of following JSON structure:
    # {"Artist":"Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #  "Songname":"Απόκληρος της κοινωνίας"}

    # This is useful when sending JSON via
    # a POST request and it needs unicode escaped:
    $backtojson = yaml2json($yamlstr, {'escape-unicode'=>1});
    # $backtojson is a string representation
    # of following JSON structure:
    # but this time with unicode escaped
    # (pod content truncated for readbility)
    # {"Artist":"\u039a\u03b1\u03b6 ...",
    #  "Songname":"\u0391\u03c0\u03cc ..."}
    # this is the usual Data::Dumper dump:
    print json2dump($jsonstr);
    #$VAR1 = {
    #  'Songname' => "\x{391}\x{3c0}\x{3cc} ...",
    #  'Artist' => "\x{39a}\x{3b1}\x{3b6} ...",
    #};

    # and this is a more human-readable version:
    print json2dump($jsonstr, {'dont-bloody-escape-unicode'=>1});
    # $VAR1 = {
    #   "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #   "Songname" => "Απόκληρος της κοινωνίας"
    # };

    # pass some parameters to Data::Dumper
    # like: be terse (no $VAR1):
    print json2dump($jsonstr,
      {'dont-bloody-escape-unicode'=>0, 'terse'=>1}
     #{'dont-bloody-escape-unicode'=>0, 'terse'=>1, 'indent'=>0}
    );
    # {
    #  "Artist" => "Καζαντζίδης Στέλιος/Βίρβος Κώστας",
    #  "Songname" => "Απόκληρος της κοινωνίας"
    # }

    # this is how to reformat a JSON string to
    # have its unicode content escaped:
    my $json_with_unicode_escaped =
          json2json($jsonstr, {'escape-unicode'=>1});

    # With version 0.18 and up two more exported-on-demand
    # subs were added to read JSON or YAML directly from a file:
    # jsonfile2perl() and yamlfile2perl()
    my $perldata = jsonfile2perl("file.json");
    my $perldata = yamlfile2perl("file.yaml");
    die "failed" unless defined $perldata;

    # For some of the above functions there exist command-line scripts:
    perl2json.pl -i "perl-data-structure.pl" -o "output.json" --pretty
    json2json.pl -i "with-unicode.json" -o "unicode-escaped.json" --escape-unicode
    # etc.

    # only for *2dump: perl2dump, json2dump, yaml2dump
    # and if no escape-unicode is required (i.e.
    # setting 'dont-bloody-escape-unicode' => 1 permanently)
    # and if efficiency is important,
    # meaning that perl2dump is run in a loop thousand of times,
    # then import the module like this:
    use Data::Roundtrip qw/:all no-unicode-escape-permanently/;
    # or like this
    use Data::Roundtrip qw/:all unicode-escape-permanently/;

    # then perl2dump() is more efficient but unicode characters
    # will be permanently not-escaped (1st case) or escaped (2nd case).

=head1 EXPORT

By default no symbols are exported. However, the following export tags are available (:all will export all of them):

=over 4

=item * C<:json> :
C<perl2json()>,
C<json2perl()>,
C<json2dump()>,
C<json2yaml()>,
C<json2json()>,
C<jsonfile2perl()>

=item * C<:yaml> :
C<perl2yaml()>,
C<yaml2perl()>,
C<yaml2dump()>,
C<yaml2yaml()>,
C<yaml2json()>,
C<yamlfile2perl()>

=item * C<:dump> :
C<perl2dump()>,
C<perl2dump_filtered()>,
C<perl2dump_homebrew()>

=item * C<:io> :
C<read_from_file()>, C<write_to_file()>,
C<read_from_filehandle()>, C<write_to_filehandle()>,

=item * C<:all> : everything above.

=item * Additionally, these four subs: C<dump2perl()>, C<dump2json()>, C<dump2yaml()>, C<dump2dump()>
do not belong to any export tag. However they can be imported explicitly by the caller
in the usual way (e.g. C<use Data::Roundtrip qw/dump2perl perl2json .../>).
Section CAVEATS, under L</dump2perl>, describes how these
subs C<eval()> a string possibly coming from user,
possibly being unchecked.

=item * C<no-unicode-escape-permanently> : this is not an
export keyword/parameter but a parameter which affects
all the C<< *2dump* >> subs by setting unicode escaping
permanently to false. See L</EFFICIENCY>.

=item * C<unicode-escape-permanently> : this is not an
export keyword/parameter but a parameter which affects
all the C<< *2dump* >> subs by setting unicode escaping
permanently to true. See L</EFFICIENCY>.

=back

=head1 EFFICIENCY

The export keyword/parameter C<< no-unicode-escape-permanently >>
affects
all the C<< *2dump* >> subs by setting unicode escaping
permanently to false. This improves efficiency, although
one will ever need to
use this in extreme situations where a C<< *2dump* >>
sub is called repeatedly in a loop of
a few hundreds or thousands of iterations or more.

Each time a C<< *2dump* >> is called, the
C<< dont-bloody-escape-unicode >> flag is checked
and if it is set, then  L<Data::Dumper>'s C<< qquote() >>
is overriden with C<< _qquote_redefinition_by_Corion() >>
just for that instance and will be restored as soon as
the dump is finished. Similarly, a filter for
not escaping unicode is added to L<Data::Dump>
just for that particular call and is removed immediately
after. This has some computational cost and can be
avoided completely by overriding the sub
and adding the filter once, at loading (in C<< import() >>).

The price to pay for this added efficiency is that
unicode in any dump will never be escaped (e.g. C<< \x{3b1}) >>,
but will be rendered (e.g. C<< α >>, a greek alpha). Always.
The option
C<< dont-bloody-escape-unicode >> will permanently be set to true.

Similarly, the export keyword/parameter
C<< unicode-escape-permanently >>
affects
all the C<< *2dump* >> subs by setting unicode escaping
permanently to true. This improves efficiency as well.

See L</BENCHMARKS> on how to find the fastest C<< *2dump* >>
sub.

=head1 BENCHMARKS

The special Makefile target C<< benchmarks >> will time
calls to each of the C<< *2dump* >> subs under

    use Data::Roundtrip;

    use Data::Roundtrip qw/no-unicode-escape-permanently/;

    use Data::Roundtrip qw/unicode-escape-permanently/;

and for C<< 'dont-bloody-escape-unicode' => 0 >> and
C<< 'dont-bloody-escape-unicode' => 1 >>.

In general, L</perl2dump> is faster by 25% when one of the
permanent import parameters is used
(either of the last two cases above).

=head1 SUBROUTINES

=head2 C<perl2json>

  my $ret = perl2json($perlvar, $optional_paramshashref)

Arguments:

=over 4

=item * C<$perlvar>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$perlvar> (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent JSON string. In C<$optional_paramshashref>
one can specify whether to escape unicode with
C<< 'escape-unicode' => 1 >>
and/or prettify the returned result with C<< 'pretty' => 1 >>
and/or allow conversion of blessed objects with C<< 'convert_blessed' => 1 >>.

The latter is useful when the input (Perl) data structure
contains Perl objects (blessed refs!). But in addition to
setting it, each of the Perl objects (their class) must
implement a C<TO_JSON()> method which will simply convert
the object into a Perl data structure. For example, if
your object stores the important data in C<< $self->data >>
as a hash, then use this to return it

    sub TO_JSON { shift->data }

the converter will replace what is returned with the blessed
object which does not know what to do with it.
See L<https://perldoc.perl.org/JSON::PP#2.-convert_blessed-is-enabled-and-the-object-has-a-TO_JSON-method.>
for more information.

The output can be fed back to L</json2perl>
for getting the Perl variable back.

It returns the JSON string on success or C<undef> on failure.

=head2 C<json2perl>

Arguments:

=over 4

=item * C<$jsonstring>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$jsonstring> as a string, it will return
the equivalent Perl data structure using
C<JSON::decode_json(Encode::encode_utf8($jsonstring))>.

It returns the Perl data structure on success or C<undef> on failure.

=head2 C<perl2yaml>

  my $ret = perl2yaml($perlvar, $optional_paramshashref)

Arguments:

=over 4

=item * C<$perlvar>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$perlvar> (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent YAML string. In C<$optional_paramshashref>
one can specify whether to escape unicode with
C<< 'escape-unicode' => 1 >>. Prettify is not supported yet.
The output can be fed to L</yaml2perl>
for getting the Perl variable back.

It returns the YAML string on success or C<undef> on failure.

=head2 C<yaml2perl>

    my $ret = yaml2perl($yamlstring);

Arguments:

=over 4

=item * C<$yamlstring>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$yamlstring> as a string, it will return
the equivalent Perl data structure using
C<YAML::PP::Load($yamlstring)>

It returns the Perl data structure on success or C<undef> on failure.

=head2 C<yamlfile2perl>

    my $ret = yamlfile2perl($filename)

Arguments:

=over 4

=item * C<$filename>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$filename> which points to a file containing YAML content,
it will return the equivalent Perl data structure.

It returns the Perl data structure on success or C<undef> on failure.

=head2 C<perl2dump>

  my $ret = perl2dump($perlvar, $optional_paramshashref)

Arguments:

=over 4

=item * C<$perlvar>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$perlvar> (which can be a simple scalar or
a nested data structure, but not an object), it will return
the equivalent string (via L<Data::Dumper>).
In C<$optional_paramshashref>
one can specify whether to escape unicode with
C<< 'dont-bloody-escape-unicode' => 0 >>,
(or C<< 'escape-unicode' => 1 >>). The DEFAULT
behaviour is to NOT ESCAPE unicode.

Additionally, use terse output with C<< 'terse' => 1 >> and remove
all the incessant indentation with C<< 'indent' => 1 >>
which unfortunately goes to the other extreme of
producing a space-less output, not fit for human consumption.
The output can be fed to L</dump2perl>
for getting the Perl variable back.

It returns the string representation of the input perl variable
on success or C<undef> on failure.

The output can be fed back to L</dump2perl>.

CAVEAT: when not escaping unicode (which is the default
behaviour), each call to this sub will override L<Data::Dumper>'s
C<qquote()> sub then
call L<Data::Dumper>'s C<Dumper()> and save its output to
a temporary variable, restore C<qquote()> sub to its original
code ref and return the
contents. This exercise is done every time this C<perl2dump()>
is called. It may be expensive. The alternative is
to redefine C<qquote()> once, when the module is loaded, with
all the side-effects this may cause.

Note that there are two other alternative subs which offer more-or-less
the same functionality and their output can be fed back to all the C<< dump2*() >>
subs. These are
L</perl2dump_filtered> which uses L<Data::Dump::Filtered>
to add a filter to control unicode escaping but
lacks in aesthetics and functionality and handling all the
cases Dump and Dumper do quite well.

There is also C<< perl2dump_homebrew() >> which
uses the same dump-recursively engine as
L</perl2dump_filtered>
but does not involve Data::Dump at all.

=head2 C<perl2dump_filtered>

  my $ret = perl2dump_filtered($perlvar, $optional_paramshashref)

Arguments:

=over 4

=item * C<$perlvar>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

It does the same job as L</perl2dump> which is
to stringify a perl variable. And takes the same options.

It returns the string representation of the input perl variable
on success or C<undef> on failure.

It uses L<Data::Dump::Filtered> to add a filter to
L<Data::Dump>.


=head2 C<perl2dump_homebrew>

  my $ret = perl2dump_homebrew($perlvar, $optional_paramshashref)

Arguments:

=over 4

=item * C<$perlvar>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

It does the same job as L</perl2dump> which is
to stringify a perl variable. And takes the same options.

It returns the string representation of the input perl variable
on success or C<undef> on failure.

The output can be fed back to L</dump2perl>.

It uses its own basic dumper. Which is recursive.
So, beware of extremely deep nested data structures.
Deep not long! But it probably is as efficient as
it can be but definetely lacks in aesthetics
and functionality compared to Dump and Dumper.


=head2 C<dump_perl_var_recursively>

    my $ret = dump_perl_var_recursively($perl_var)

Arguments:

=over 4

=item * C<$perl_var>, a Perl variable like
a scalar or an arbitrarily nested data structure.
For the latter, it requires references, e.g.
hash-ref or arrayref.

=back

Return value:

=over 4

=item * C<$ret>, the stringified version of the input Perl variable.

=back

This sub will take a Perl var (as a scalar or an arbitrarily nested data structure)
and emulate a very very basic
Dump/Dumper but with enforced rendering unicode (for keys or values or array items),
and not escaping unicode - this is not an option,
it returns a string representation of the input perl var

There are 2 obvious limitations:

=over 4

=item 1. indentation is very basic,

=item 2. it supports only scalars, hashes and arrays,
(which will dive into them no problem)
This sub can be used in conjuction with DataDumpFilterino()
to create a Data::Dump filter like,

     Data::Dump::Filtered::add_dump_filter( \& DataDumpFilterino );
or
     dumpf($perl_var, \& DataDumpFilterino);

the input is a Perl variable as a reference, so no C<< %inp >> but C<< $inp={} >> 
and C<< $inp=[] >>. 

This function is recursive.
Beware of extremely deep nested data structures.
Deep not long! But it probably is as efficient as
it can be but definetely lacks in aesthetics
and functionality compared to Dump and Dumper.

The output is a, possibly multiline, string. Which it can
then be fed back to L</dump2perl>.

=back

=head2 C<dump2perl>

    # CAVEAT: it will eval($dumpstring) internally, so
    #         check $dumpstring for malicious code beforehand
    #         it is a security risk if you don't.
    #         Don't use it if $dumpstring comes from
    #         untrusted sources (user input for example).
    my $ret = dump2perl($dumpstring)

Arguments:

=over 4

=item * C<$dumpstring>, this comes from the output of L<Data::Dump>,
L<Data::Dumper> or our own L</perl2dump>,
L</perl2dump_filtered>,
L</perl2dump_homebrew>.
Escaped, or unescaped.

=back

Return value:

=over 4

=item * C<$ret>, the Perl data structure on success or C<undef> on failure.

=back

CAVEAT: it B<eval()>'s the input C<$dumpstring> in order to create the Perl data structure.
B<eval()>'ing unknown or unchecked input is a security risk. Always check input to B<eval()>
which comes from untrusted sources, like user input, scraped documents, email content.
Anything really.

=head2 C<json2perl>

    my $ret = json2perl($jsonstring)

Arguments:

=over 4

=item * C<$jsonstring>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$jsonstring> as a string, it will return
the equivalent Perl data structure using
C<JSON::decode_json(Encode::encode_utf8($jsonstring))>.

It returns the Perl data structure on success or C<undef> on failure.

=head2 C<jsonfile2perl>

    my $ret = jsonfile2perl($filename)

Arguments:

=over 4

=item * C<$filename>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input C<$filename> which points to a file containing JSON content,
it will return the equivalent Perl data structure.

It returns the Perl data structure on success or C<undef> on failure.

=head2 C<json2yaml>

  my $ret = json2yaml($jsonstring, $optional_paramshashref)

Arguments:

=over 4

=item * C<$jsonstring>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input JSON string C<$jsonstring>, it will return
the equivalent YAML string L<YAML>
by first converting JSON to a Perl variable and then
converting that variable to YAML using L</perl2yaml>.
All the parameters supported by L</perl2yaml>
are accepted.

It returns the YAML string on success or C<undef> on failure.

=head2 C<yaml2json>

  my $ret = yaml2json($yamlstring, $optional_paramshashref)

Arguments:

=over 4

=item * C<$yamlstring>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back

Given an input YAML string C<$yamlstring>, it will return
the equivalent YAML string L<YAML>
by first converting YAML to a Perl variable and then
converting that variable to JSON using L</perl2json>.
All the parameters supported by L</perl2json>
are accepted.

It returns the JSON string on success or C<undef> on failure.

=head2 C<json2json> C<yaml2yaml>

Transform a json or yaml string via pretty printing or via
escaping unicode or via un-escaping unicode. Parameters
like above will be accepted.

=head2 C<json2dump> C<dump2json> C<yaml2dump> C<dump2yaml>

These subs offer similar functionality as their counterparts
described above.

Section CAVEATS, under L</dump2perl>, describes how
C<dump2*()> subs C<eval()> a string possibly coming from user,
possibly being unchecked.

=head2 C<dump2dump>

  my $ret = dump2dump($dumpstring, $optional_paramshashref)

Arguments:

=over 4

=item * C<$dumpstring>

=item * C<$optional_paramshashref>

=back

Return value:

=over 4

=item * C<$ret>

=back
Given an input string C<$dumpstring>, which can
have been produced by e.g. C<perl2dump()>
and is identical to L<Data::Dumper>'s C<Dumper()> output,
it will roundtrip back to the same string,
possibly with altered format via the parameters in C<$optional_paramshashref>.

For example:

  my $dumpstr = '...';
  my $newdumpstr = dump2dump(
    $dumpstr,
    {
      'dont-bloody-escape-unicode' => 1,
      'terse' => 0,
    }
  );


It returns the a dump string similar to 


=head2 C<read_from_file>

  my $contents = read_from_file($filename)

Arguments:

=over 4

=item * C<$filename> : the input filename.

=back

Return value:

=over 4

=item * C<$contents>

=back

Given a filename, it opens it using C<< :encoding(UTF-8) >>, slurps its
contents and closes it. It's a convenience sub which could have also
been private. If you want to retain the filehandle, use
L</read_from_filehandle>.

It returns the file contents on success or C<undef> on failure.

=head2 C<read_from_filehandle>

  my $contents = read_from_filehandle($filehandle)

Arguments:

=over 4

=item * C<$filehandle> : the handle to an already opened file.

=back

Return value:

=over 4

=item * C<$contents> : the file contents slurped.

=back

It slurps all content from the specified input file handle. Upon return
the file handle is still open.
It returns the file contents on success or C<undef> on failure.

=head2 C<write_to_file>

  write_to_file($filename, $contents) or die

Arguments:

=over 4

=item * C<$filename> : the output filename.

=item * C<$contents> : any string to write it to file.

=back

Return value:

=over 4

=item * 1 on success, 0 on failure

=back

Given a filename, it opens it using C<< :encoding(UTF-8) >>,
writes all specified content and closes the file.
It's a convenience sub which could have also
been private. If you want to retain the filehandle, use
L</write_to_filehandle>.

It returns 1 on success or 0 on failure.

=head2 C<write_to_filehandle>

  write_to_filehandle($filehandle, $contents) or die

Arguments:

=over 4

=item * C<$filehandle> : the handle to an already opened file (for writing).

=back

Return value:

=over 4

=item * 1 on success or 0 on failure.

=back

It writes content to the specified file handle. Upon return
the file handle is still open.

It returns 1 on success or 0 on failure.

=head1 SCRIPTS

A few scripts have been put together and offer the functionality of this
module to the command line. They are part of this distribution and can
be found in the C<script> directory.

These are: C<json2json.pl>,  C<json2yaml.pl>,  C<yaml2json.pl>,
C<json2perl.pl>, C<perl2json.pl>, C<yaml2perl.pl>

=head1 CAVEATS

I have to apologise here to the authors of L<YAML::PP>
for defaming them because I clumsily wrote L<YAML::PP>
when I wanted to write L<YAML>.

So, the reality is that L<YAML::PP> does not have any
problem in handling the edge-case below.

A valid Perl variable may kill L<YAML>'s C<Load()> because
of escapes and quotes. For example this:

    my $yamlstr = <<'EOS';
    ---
    - 682224
    - "\"w": 1
    EOS
    my $pv = eval { YAML::Load($yamlstr) };
    if( $@ ){ die "failed(1): ". $@ }
    # it's dead

Strangely, there is no problem for this:

    my $yamlstr = <<'EOS';
    ---
    - 682224
    - "\"w"
    EOS
    # this is OK also:
    # - \"w: 1
    my $pv = eval { YAML::Load($yamlstr) };
    if( $@ ){ die "failed(1): ". $@ }
    # it's OK! still alive.

I have provided an author-only test (C<make deficiencies>) which
tests all three of them on the edge cases. Both L<YAML::PP>
and L<YAML::XS> pass the tests.

This L<YAML issue|https://github.com/ingydotnet/yaml-pm/issues/224> is
relevant. Many thanks to CPAN authors L<TINITA|https://metacpan.org/author/TINITA>
and L<INGY|https://metacpan.org/author/INGY> for their work on this, and
on C<YAML*> too.

For now, the plan is to still use L<YAML::PP> and avoid explicitly requiring
L<YAML::XS> until L<YAML::Any> is ready.

Be warned that sub C<dump2perl()> C<eval()>'s
its input. If this comes from the user and
it is not checked then it is considered a security
problem. Subs C<dump2json()>, C<dump2yaml()>, C<dump2dump()>
use C<dump2perl()>. The four subs will issue a warning whenever
you call them. Additionally, as from version 0.28, they need
to be explicitly imported like:

    use Data::Roundtrip qw/... dump2perl .../

They are no longer part of export tag C<:dump> nor C<:all>.
If their input comes from the user please check the input
not to contain malicious code which when C<eval()>'ed
can create security concerns.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> / <andreashad2 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-roundtrip at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Roundtrip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item L<Convert JSON to Perl and back with unicode|https://perlmonks.org/?node_id=11115241>

=item L<RFC: PerlE<lt>-E<gt>JSONE<lt>-E<gt>YAMLE<lt>-E<gt>Dumper : roundtripping and possibly with unicode|https://perlmonks.org/?node_id=11115280>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Roundtrip


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Roundtrip>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Roundtrip>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<https://metacpan.org/release/Data-Roundtrip>

=back

=head1 ACKNOWLEDGEMENTS

Several Monks at L<PerlMonks.org | https://PerlMonks.org> (in no particular order):

=over 4

=item L<haukex|https://perlmonks.org/?node_id=830549>

=item L<Corion|https://perlmonks.org/?node_id=5348> (the
C<< _qquote_redefinition_by_Corion() >> which harnesses
L<Data::Dumper>'s incessant unicode escaping)

=item L<kcott|https://perlmonks.org/?node_id=861371>
(The EXPORT section among other suggestions)

=item L<jwkrahn|https://perlmonks.org/?node_id=540414>

=item L<leszekdubiel|https://perlmonks.org/?node_id=1164259>

=item L<marto|https://perlmonks.org/?node_id=324763>

=item L<Haarg|https://perlmonks.org/?node_id=306692>

=item and an anonymous monk

=item CPAN author Slaven ReziE<263>
(L<SREZIC|https://metacpan.org/author/SREZIC>) for testing
the code and reporting numerous problems.

=item CPAN authors L<TINITA|https://metacpan.org/author/TINITA>
and L<INGY|https://metacpan.org/author/INGY>
for working on an issue related to L<YAML>.

=back

=head1 DEDICATIONS

Almaz!

=head1 LICENSE AND COPYRIGHT

This software, EXCEPT the portions created by [Corion] @ Perlmonks
and [kcott] @ Perlmonks,
is Copyright (c) 2020 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Data::Roundtrip
