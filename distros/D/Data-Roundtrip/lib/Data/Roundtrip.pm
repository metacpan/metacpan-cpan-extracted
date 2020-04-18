package Data::Roundtrip;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.06';

use Encode qw/encode_utf8 decode_utf8/;
use JSON qw/decode_json encode_json/;
use Unicode::Escape qw/escape unescape/;
use YAML;
use Sub::Override;
use Data::Dumper qw/Dumper/;
use Data::Dump qw/pp/;
use Data::Dump::Filtered;

use Exporter qw(import);
use Exporter 'import';
# the EXPORT_OK and EXPORT_TAGS is code by [kcott] @ Perlmongs.org, thanks!
# see https://perlmonks.org/?node_id=11115288
our (@EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    my @file = qw{read_from_file write_to_file};
    my @fh = qw{read_from_filehandle write_to_filehandle};
    my @io = (@file, @fh);
    my @json = qw{perl2json json2perl json2dump json2yaml json2json};
    my @yaml = qw{perl2yaml yaml2perl yaml2json yaml2dump yaml2yaml};
    my @dump = qw{perl2dump dump2perl dump2json dump2yaml dump2dump};
    my @all = (@io, @json, @yaml, @dump);
    @EXPORT_OK = @all;
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

sub	perl2json {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};
	my $pretty_printing = exists($params->{'pretty'}) && defined($params->{'pretty'})
		? $params->{'pretty'} : 0
	;
	my $escape_unicode = exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		? $params->{'escape-unicode'} : 0
	;
	my $json_string;
	if( $escape_unicode ){
		if( $pretty_printing ){
			$json_string = JSON->new->utf8(1)->pretty->encode($pv);
		} else { $json_string = JSON->new->utf8(1)->encode($pv) }
		if ( _has_utf8($json_string) ){
			$json_string = Unicode::Escape::escape($json_string, 'utf8');
		}
	} else {
		if( $pretty_printing ){
			$json_string = JSON->new->utf8(0)->pretty->encode($pv);
		} else { $json_string = JSON->new->utf8(0)->encode($pv) }
	}
	if( ! $json_string ){ warn "perl2json() : error, no json produced from perl variable"; return undef }
	return $json_string
}
sub	perl2yaml {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};
	my $pretty_printing = exists($params->{'pretty'}) && defined($params->{'pretty'})
		? $params->{'pretty'} : 0
	;
	warn "perl2yaml() : pretty-printing is not supported for YAML output" and $pretty_printing=0
		if $pretty_printing;

	my $escape_unicode = exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		? $params->{'escape-unicode'} : 0
	;
	my ($yaml_string, $escaped);
	if( $escape_unicode ){
		if( $pretty_printing ){
			$yaml_string = YAML::Dump($pv);
			# this does not work :( no pretty printing for yaml
			#$yaml_string = Data::Format::Pretty::YAML::format_pretty($pv);
		} else { $yaml_string = YAML::Dump($pv) }
		if( _has_utf8($yaml_string) ){
			utf8::encode($yaml_string);
			$yaml_string = Unicode::Escape::escape($yaml_string, 'utf8');
		}
	} else {
		if( $pretty_printing ){
			#$yaml_string = Data::Format::Pretty::YAML::format_pretty($pv);
		} else { $yaml_string = YAML::Dump($pv) }
	}
	if( ! $yaml_string ){ warn "perl2yaml() : error, no yaml produced from perl variable"; return undef }

	return $yaml_string
}
sub	yaml2perl {
	my $yaml_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	my $pv = YAML::Load($yaml_string);
	if( ! $pv ){ warn "yaml2perl() : error, call to YAML::Load() has failed"; return undef }
	return $pv
}
sub	json2perl {
	my $json_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};
	my $pv = JSON::decode_json(Encode::encode_utf8($json_string));
	if( ! defined $pv ){ warn "json2perl() :  error, call to json2perl() has failed"; return undef }
	return $pv;
}
sub	json2json {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! defined $pv ){ warn "json2perl() :  error, call to json2perl() has failed"; return undef }
	$json_string = perl2json($pv, $params);
	if( ! defined $json_string ){ warn "json2perl() :  error, call to perl2json() has failed"; return undef }

	return $json_string;
}
sub	yaml2yaml {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = yaml2perl($yaml_string, $params);
	if( ! defined $pv ){ warn "yaml2perl() :  error, call to yaml2perl() has failed"; return undef }
	$yaml_string = perl2yaml($pv, $params);
	if( ! defined $yaml_string ){ warn "yaml2perl() :  error, call to perl2yaml() has failed"; return undef }

	return $yaml_string;
}
sub	dump2dump {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! defined $pv ){ warn "dump2perl() :  error, call to dump2perl() has failed"; return undef }
	$dump_string = perl2dump($pv, $params);
	if( ! defined $dump_string ){ warn "dump2perl() :  error, call to perl2dump() has failed"; return undef }

	return $dump_string;
}
sub	yaml2json {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	# is it escaped already?
	$yaml_string =~ s/\\u([0-9a-fA-F]{4})/eval "\"\\x{$1}\""/ge;
	my $pv = yaml2perl($yaml_string, $params);
	if( ! $pv ){ warn "yaml2json() : error, call to yaml2perl() has failed"; return undef }
	my $json = perl2json($pv, $params);
	if( ! $json ){ warn "yaml2json() : error, call to perl2json() has failed"; return undef }
	return $json
}
sub	yaml2dump {
	my $yaml_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = yaml2perl($yaml_string, $params);
	if( ! $pv ){ warn "yaml2json() : error, call to yaml2perl() has failed"; return undef }
	my $dump = perl2dump($pv, $params);
	if( ! $dump ){ warn "yaml2dump() : error, call to perl2dump() has failed"; return undef }
	return $dump
}
sub	json2dump {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! $pv ){ warn "json2json() : error, call to json2perl() has failed"; return undef }
	my $dump = perl2dump($pv, $params);
	if( ! $dump ){ warn "json2dump() : error, call to perl2dump() has failed"; return undef }
	return $dump
}
sub	dump2json {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! $pv ){ warn "dump2json() : error, call to dump2perl() has failed"; return undef }
	my $json_string = perl2json($pv, $params);
	if( ! $json_string ){ warn "dump2json() : error, call to perl2json() has failed"; return undef }
	return $json_string
}
sub	dump2yaml {
	my $dump_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = dump2perl($dump_string, $params);
	if( ! $pv ){ warn "yaml2yaml() : error, call to yaml2perl() has failed"; return undef }
	my $yaml_string = perl2yaml($pv, $params);
	if( ! $yaml_string ){ warn "dump2yaml() : error, call to perl2yaml() has failed"; return undef }
	return $yaml_string
}
sub	json2yaml {
	my $json_string = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	my $pv = json2perl($json_string, $params);
	if( ! defined $pv ){ warn "json2yaml() :  error, call to json2perl() has failed"; return undef }
	my $yaml_string = perl2yaml($pv, $params);
	if( ! defined $yaml_string ){ warn "json2yaml() :  error, call to perl2yaml() has failed"; return undef }
	return $yaml_string
}
sub	dump2perl {
	my $dump_string = $_[0];
	#my $params = defined($_[1]) ? $_[1] : {};

	$dump_string =~ s/^\$VAR1\s*=\s*//g;
	my $pv = eval($dump_string);
	if( $@ || ! defined $pv ){ warn "error, failed to eval() input string alledgedly a perl variable: $@"; return undef }
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
	if( (
		exists($params->{'dont-bloody-escape-unicode'}) && defined($params->{'dont-bloody-escape-unicode'})
		 && ($params->{'dont-bloody-escape-unicode'}==1)
	    ) || (
		exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		 && ($params->{'escape-unicode'}==0)
	    )
	){
		local $Data::Dumper::Useperl = 1;
		local $Data::Dumper::Useqq='utf8';
		my $override = Sub::Override->new(
			'Data::Dumper::qquote' => \& _qquote_redefinition_by_Corion
		);
		my $ret = Data::Dumper::Dumper($pv);
		# not really...
		#$ret = Data::Dumper::AutoEncode::eDumper($pv);
		# restore the overriden sub
		$override->restore;
		return $ret
	}
	return Data::Dumper::Dumper($pv)
}
# This uses Data::Dump's filters
# The _qquote_redefinition_by_Corion() code is by [Corion] @ Perlmonks and cpan
# see https://perlmonks.org/?node_id=11115271
#
sub	perl2dump_filtered {
	my $pv = $_[0];
	my $params = defined($_[1]) ? $_[1] : {};

	if( (
		exists($params->{'dont-bloody-escape-unicode'}) && defined($params->{'dont-bloody-escape-unicode'})
		 && ($params->{'dont-bloody-escape-unicode'}==1)
	    ) || (
		exists($params->{'escape-unicode'}) && defined($params->{'escape-unicode'})
		 && ($params->{'escape-unicode'}==0)
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

	if( (
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
		warn "failed to open file '$infile' for reading, $!";
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
		warn "failed to open file '$outfile' for writing, $!";
		return 0
	}
	if( ! write_to_filehandle($FH, $contents) ){ warn "error, call to ".'write_to_filehandle()'." has failed"; close $FH; return 0 }
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

Version 0.06

=head1 SYNOPSIS

This module contains a collection of utilities for converting between
JSON, YAML, Perl variable and a Perl variable's string representation (aka dump).
Hopefully, all unicode content will be handled correctly between
the conversions and optionally escaped or un-escaped. Also JSON can
be presented in a pretty format or in a condensed, machine-readable
format (not spaces, indendation or line breaks).


    use Data::Roundtrip qw/:all/;

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

    # For some of the above functions there exist command-line scripts:
    perl2json.pl -i "perl-data-structure.pl" -o "output.json" --pretty
    json2json.pl -i "with-unicode.json" -o "unicode-escaped.json" --escape-unicode
    # etc.

=head1 EXPORT

By default no symbols are exported. However, the following export tags are available (:all will export all of them):

=over 4

=item * C<:json> :
C<perl2json()>,
C<json2perl()>,
C<json2dump()>,
C<json2yaml()>,
C<json2json()>

=item * C<:yaml> :
C<perl2yaml()>,
C<yaml2perl()>,
C<yaml2dump()>,
C<yaml2yaml()>,
C<yaml2json()>

=item * C<:dump> :
C<perl2dump()>,
C<dump2perl()>,
C<dump2json()>,
C<dump2yaml()>

=item * C<:io> :
C<read_from_file()>, C<write_to_file()>,
C<read_from_filehandle()>, C<write_to_filehandle()>,

=item * C<:all> : everything above

=back

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
and/or prettify the returned result with C<< 'pretty' => 1 >>.
The output can be fed back to L<Data::Roundtrip>'s C<< json2perl() >>
for getting the Perl variable back.

Returns the JSON string on success or C<undef> on failure.

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

Returns the Perl data structure on success or C<undef> on failure.

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
The output can fed to L<Data::Roundtrip>'s C<< yaml2perl() >>
for getting the Perl variable back.

Returns the YAML string on success or C<undef> on failure.

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
C<YAML::Load($yamlstring)>

Returns the Perl data structure on success or C<undef> on failure.

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
The output can fed to L<Data::Roundtrip>'s C<< dump2perl() >>
for getting the Perl variable back.

It returns the string representation of the input perl variable
on success or C<undef> on failure.

The output can be fed back to L<Data::Roundtrip>'s C<< dump2perl() >>.

CAVEAT: when not escaping unicode (which is the default
behaviour), each call to this sub will override L<Data::Dumper>'s
C<qquote()> sub (with a call to L<Sub::Override>' C<< new() >>),
call L<Data::Dumper>'s C<Dumper()> and save its output to
a temporary variable, restore C<qquote()> sub (with
a call to L<Sub::Override>'s C<< restore() >> and return the
contents. This exercise is done every time this C<perl2dump()>
is called. It can be expensive. The alternative is
to redefine C<qquote()> once, when the module is loaded.

Note that there are two other alternatives to this sub,
L<Data::Roundtrip>'s C<< perl2dump_filtered() >> which uses L<Data::Dump>
filters to control unicode escaping but
lacks in aesthetics and functionality and handling all the
cases Dump and Dumper do quite well.

There is also C<< perl2dump_homebrew() >> which
uses the same dump-recursively engine as
L<Data::Roundtrip>'s C<< perl2dump_filtered() >>
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

It does the same job as L<Data::Roundtrip>'s C<< perl2dump() >> which is
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

It does the same job as L<Data::Roundtrip>'s C<< perl2dump() >> which is
to stringify a perl variable. And takes the same options.

It returns the string representation of the input perl variable
on success or C<undef> on failure.

The output can be fed back to L<Data::Roundtrip>'s C<< dump2perl() >>.

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

=item 1) indentation is very basic,

=item 2) it supports only scalars, hashes and arrays,
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
then be fed back to L<Data::Roundtrip>'s C<< dump2perl() >>.

=back

=head2 C<dump2perl>

    my $ret = dump2perl($dumpstring)

Arguments:

=over 4

=item * C<$dumpstring>, this comes from the output of L<Data::Dump>,
L<Data::Dumper> or our own L<Data::Roundtrip>'s C<< perl2dump() >>,
L<Data::Roundtrip>'s C<< perl2dump_filtered() >>,
L<Data::Roundtrip>'s C<< perl2dump_homebrew() >>.
Escaped, or unescaped.

=back

Return value:

=over 4

=item * C<$ret>, the Perl data structure on success or C<undef> on failure.

=back

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

Returns the Perl data structure on success or C<undef> on failure.

In C<$optional_paramshashref>
one can specify whether to escape unicode with
C<< 'escape-unicode' => 1 >>
and/or prettify the returned result with C<< 'pretty' => 1 >>.

Returns the yaml string on success or C<undef> on failure.

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
converting that variable to YAML using L<Data::Roundtrip>'s C<< perl2yaml() >>.
All the parameters supported by L<Data::Roundtrip>'s C<< perl2yaml() >>
are accepted.

Returns the YAML string on success or C<undef> on failure.

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
converting that variable to JSON using L<Data::Roundtrip>'s C<< perl2json() >>.
All the parameters supported by L<Data::Roundtrip>'s C<< perl2json() >>
are accepted.

Returns the JSON string on success or C<undef> on failure.

=head2 C<json2json> C<yaml2yaml>

Transform a json or yaml string via pretty printing or via
escaping unicode or via un-escaping unicode. Parameters
like above will be accepted.

=head2 C<json2dump> C<dump2json> C<yaml2dump> C<dump2yaml>

similar functionality as their counterparts described above.

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
L<Data::Roundtrip>'s C<< read_from_filehandle() >>.

Returns the file contents on success or C<undef> on failure.

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
Returns the file contents on success or C<undef> on failure.

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
L<Data::Roundtrip>'s C<< write_to_filehandle() >>.

Returns 1 on success or 0 on failure.

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

Returns 1 on success or 0 on failure.

=head1 SCRIPTS

A few scripts have been put together and offer the functionality of this
module to the command line. They are part of this distribution and can
be found in the C<script> directory.

These are: C<json2json.pl>,  C<json2yaml.pl>,  C<yaml2json.pl>,
C<json2perl.pl>, C<perl2json.pl>, C<yaml2perl.pl>

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

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-Roundtrip>

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

=item L<marto|https://perlmonks.org/?node_id=https://perlmonks.org/?node_id=324763>

=item and an anonymous monk

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
