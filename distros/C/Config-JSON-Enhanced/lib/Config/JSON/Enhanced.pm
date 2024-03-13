package Config::JSON::Enhanced;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.10';

use strict;
use warnings;

# which loads JSON::XS with a purel-perl JSON fallback
use JSON;

use Data::Roundtrip qw/json2perl perl2dump no-unicode-escape-permanently/;

use Exporter; # we have our own import() don't import it
our @ISA = qw(Exporter);
our @EXPORT = qw/
	config2perl
/;

# Convert enhanced JSON string into a Perl data structure.
# The input parameters hashref:
#  * specify where is the content to be parsed via:
#    'filename',
#    'filehandle', or,
#    'string'
#  * optional 'commentstyle' is a string of comma separated
#    commentstyles (valid styles are C, CPP, shell)
#  * optional 'variable-substitutions' is a hashref with
#    keys as template variable names to be substutited
#    inside the content with their corresponding values.
#    For example {'xx' => 'hello'} will substitute
#      <% xx %> with hello
#  * optional 'remove-comments-in-strings' to remove comments from JSON strings
#    (both keys and values), default is to KEEP anything inside a string
#    even if it looks like comments we are supposed to remove (because string
#    can be a bash script, for example).
#  * optional 'debug' for setting verbosity, default is zero.
#
# It returns the created Perl data structure or undef on failure.
sub	config2perl {
	my $params = shift // {};

	my $contents;
	if( exists($params->{'filename'}) && defined(my $infile=$params->{'filename'}) ){
		my $fh;
		if( ! open $fh, '<:encoding(UTF-8)', $infile ){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, failed to open file '$infile' for reading, $!"; return undef }
		{ local $/ = undef; $contents = <$fh> }; close $fh;
	} elsif( exists($params->{'filehandle'}) && defined(my $fh=$params->{'filehandle'}) ){
		{ local $/ = undef; $contents = <$fh> }
		# we are not closing the filehandle, it is caller-specified, so caller responsibility
	} elsif( exists($params->{'string'}) && defined($params->{'string'}) ){
		$contents = $params->{'string'};
	}
	if( ! defined $contents ){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, one of 'filename', 'filehandle' or 'string' must be specified in the parameters hash as the source of the configuration contents."; return undef }

	my $debug = exists($params->{'debug'}) && defined($params->{'debug'})
		? $params->{'debug'} : 0
	;

	my $commentstyle = exists($params->{'commentstyle'}) && defined($params->{'commentstyle'})
		? $params->{'commentstyle'} : 'C'
	;

	my ($tvop, $tvcl);
	if( exists($params->{'tags'}) && defined($params->{'tags'}) ){
		if( ref($params->{'tags'}) ne 'ARRAY' ){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, input parameter 'tags' must be an ARRAYref of exactly 2 items and not a '".ref($params->{'tags'})."'."; return undef }
		if( scalar(@{ $params->{'tags'} }) != 2 ){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, input parameter 'tags' must be an ARRAYref of exactly 2 items and not ".scalar(@{ $params->{'tags'} })."."; return undef }
		($tvop, $tvcl) = @{ $params->{'tags'} };
	} else { $tvop = '<%'; $tvcl = '%>' }

	# check that the tags for verbatim sections is not the same as comments
	while( $commentstyle =~ /\bcustom\((.+?)\)\((.*?)\)/ig ){
		my $coop = $1; my $cocl = $2;
		if( $debug > 0 ){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : checking comment tags '${coop}' and '${cocl}' not to be the same or contain verbatim/variables tags '${tvop}' and '${tvcl}' ..." }
		if( ($tvop eq $coop) || ($tvop eq $cocl)
		 || ($tvcl eq $coop) || ($tvcl eq $cocl)
		){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, there is a clash (exact match) with verbatim/variable tags ('${tvop}' and '${tvcl}') and comment tags ('${coop}' and '${cocl}')."; return undef }
		# also check if one contains the other
		if( ($tvop =~ /\Q${coop}\E/) || ($tvop =~ /\Q${cocl}\E/)
		 || ($tvcl =~ /\Q${coop}\E/) || ($tvcl =~ /\Q${cocl}\E/)
		){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, there is a clash (one contains the other) with verbatim/variable tags ('${tvop}' and '${tvcl}') and comment tags ('${coop}' and '${cocl}')."; return undef }
		if( ($coop =~ /\Q${tvop}\E/) || ($coop =~ /\Q${tvcl}\E/)
		 || ($cocl =~ /\Q${tvop}\E/) || ($cocl =~ /\Q${tvcl}\E/)
		){ warn __PACKAGE__.'::configfile2perl()'." (line ".__LINE__.") : error, there is a clash (one contains the other) with verbatim/variable tags ('${tvop}' and '${tvcl}') and comment tags ('${coop}' and '${cocl}')."; return undef }
	}

	my $tsubs = exists($params->{'variable-substitutions'})
		? $params->{'variable-substitutions'} : undef
	;

	# remove comments inside strings? default is NO, keep comments if inside strings
	# because they may not be our comments (e.g. string contains a bash script)
	my $remove_comments_in_strings = exists($params->{'remove-comments-in-strings'}) && defined($params->{'remove-comments-in-strings'})
		? $params->{'remove-comments-in-strings'} : 0
	;

	# firstly, substitute templated variables if any
	# with the user-specified data.
	# This includes ANYTHNING in the input enhanced JSON including
	# verbatim sections, keys, values, etc.
	# The opening and closing tags of vars are user-specified
	# and are NOT allowed to contain spaces in between
	# (e.g. '<  %' will not be matched if '<%' was specified)
	for my $ak (keys %$tsubs){
		my $av = $tsubs->{$ak};
		if( ($ak =~ /(?:\Q${tvop}\E)|(?:\Q${tvcl}\E)/) ){ warn __PACKAGE__.'::config2perl()'." (line ".__LINE__.") : error, variable names can not contain the specified opening ($tvop) and/or closing ($tvcl) variable name tags."; return undef }
		$contents =~ s!\Q${tvop}\E\s*${ak}\s*\Q${tvcl}\E!${av}!g;
	}
	# this is JUST a warning:
	# we can not be sure if this <% xyz %> is part of the content or a forgotten templated variable
	if( $contents =~ /\Q${tvop}\E\s*!(:?(:?begin-verbatim-section)|(:?end-verbatim-section))\s*\Q${tvcl}\E/ ){ print STDERR "--begin content:\n".$contents."\n--end content.\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : warning, there may still be remains of templated variables in the specified content (tags used: '${tvop}' and '${tvcl} -- ignore the enclosing single quotes), see above what remained after all template variables substitutions were done." }
	# this does not print contents in its warning message
	# in case Test::More gets confused:
	#if( $contents =~ /\Q${tvop}\E\s*!(:?(:?begin-verbatim-section)|(:?end-verbatim-section))\s*\Q${tvcl}\E/ ){ print STDERR __PACKAGE__.'::config2perl()'." (line ".__LINE__.") : warning, there may still be remains of templated variables in the specified content (tags used: '${tvop}' and '${tvcl}' -- ignore the enclosing single quotes), see above what remained after all template variables substitutions were done." }

	# secondly, remove the VERBATIM multiline sections and transform them.
	# Comments inside the verbatim section will NOT BE touched.
	# The only thing touched was the templated variables earlier
	# it substitutes each verbatim section with a code
	# then does the comments and then replaces the code with the verbatim section at the very end
	my @verbs;
	my $idx = 0;
	while( $contents =~ s/\Q${tvop}\E\s*begin-verbatim-section\s*\Q${tvcl}\E(.*?)\Q${tvop}\E\s*end-verbatim-section\s*\Q${tvcl}\E/"___my___verbatim-section-${idx}___my___"/s ){
		my $vc = $1;
		# remove from start and end of whole string newlines+spaces
		$vc =~ s/^[\n\t ]+//;
		$vc =~ s/[\n\t ]+$//;
		# remove newlines followed by optional spaces at the beginning of each line
		$vc =~ s/\n+[ \t]*/\\n/gs;
		# escape all double quotes (naively)
		# but not those which are already escaped (naively)
		$vc =~ s/\\"/<%__abcQQxyz__%>/g;
		$vc =~ s/"/\\"/g;
		$vc =~ s/<%__abcQQxyz__%>/\\\\\\"/g;
		# so echo "aa \"xx\""
		# becomes echo \"aa \\\"xx\\\"\"
		push @verbs, $vc;
		$idx++;
	}

	# thirdly, replace all JSON strings (keys or values) with indexed markers
	# so that their contained comments
	# to be left intact after the comment substitution which will
	# be done later on.
	my @stringsubs;
	if( $remove_comments_in_strings == 0 ){
		$idx = 0;
		while( $contents =~ s/(?<![\\])"((?:.(?!(?<![\\])"))*.?)"/___my___EJSTRING($idx)___my___/ ){
			push @stringsubs, $1;
			$idx++;
		}
	}

	# fourthly, remove comments: 'shell' and/or 'C' and/or 'CPP'
	# and/or multiple instances of 'custom()()'
	my $tc = $commentstyle;
	if( $tc =~ s/\bC\b//i ){
		$contents =~ s/\/\*(?:(?!\*\/).)*\*\/\n?//sg;
	}
	if( $tc =~ s/\bCPP\b//i ){
		$contents =~ s/\/\*(?:(?!\*\/).)*\*\/\n?//sg;
		$contents =~ s!//.*$!!mg;
	}
	if( $tc =~ s/\bshell\b//i ){
		# TODO: we must also remove the newline left!
		$contents =~ s/#.*$//mg;
	}

	# specify a custom comment style with required opening string
	# and an optional closing
	# e.g. custom(required)(optional), custom(<<)(>>) or custom(REM)()
	while( $tc =~ s/\bcustom\((.+?)\)\((.*?)\)//i ){
		# mulitple custom(opening)(closing) commentstyle are allowed
		# 'opening' and 'closing' can be any string
		# And need not be balanced e.g. <<< and >>
		# And can be the same e.g. <<< and <<<
		my $coop = $1; my $cocl = $2;
		if( $cocl =~ /^\s*$/ ){
			# TODO: we must also remove the newline left!
			$contents =~ s/\Q${coop}\E.*$//mg;
		} else {
			$contents =~ s/\Q${coop}\E(?:(?!\Q${cocl}\E\s*).)*\Q${cocl}\E\s*\n?//sg;
		}
	}
	if( $tc =~ /[a-z]/i ){ warn __PACKAGE__.'::config2perl()'." (line ".__LINE__.") : error, comments style '${commentstyle}' was not understood, this is what was left after parsing it: '${tc}'."; return undef }

	# this is JUST a warning:
	# because we can not be sure if this <% xyz %>
	# is part of the content or a forgotten templated variable
	# However, the json2perl below will return undef on any errors
	# turn it into an error?
	if( $contents =~ /\Q${tvop}\E.+?(?:begin|end)-verbatim-section\s*\Q${tvcl}\E/ ){ warn "--begin content:\n".$contents."\n--end content.\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : warning, there may still be remains of templated variables in the specified content, see above what remained after all verbatime sections were removed." }

	if( $remove_comments_in_strings == 0 ){
		$idx = 0;
		for($idx=scalar(@stringsubs);$idx-->0;){
			my $astring = $stringsubs[$idx];
			$contents =~ s/___my___EJSTRING\($idx\)___my___/"${astring}"/g
		}
	}

	# and now substitute the transformed verbatim sections back
	for($idx=scalar(@verbs);$idx-->0;){
		$contents =~ s/___my___verbatim-section-${idx}___my___/$verbs[$idx]/g;
	}

	if( $debug > 0 ){ warn $contents."\n\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : produced above standard JSON from enhanced JSON content." }

	# here $contents must contain standard JSON which we parse:
	my $inhash = json2perl($contents);
	if( ! defined $inhash ){ warn $contents."\n\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : error, call to ".'Data::Roundtrip::json2perl()'." has failed for above json string and comments style '${commentstyle}'."; return undef }
	return $inhash
}

=pod

=head1 NAME

Config::JSON::Enhanced - JSON-based config with C/Shell-style comments, verbatim sections and variable substitutions

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

This module provides subroutine C<config2perl()> for parsing configuration content,
from files or strings,  based on, what I call, "enhanced JSON" (see section
L<ENHANCED JSON FORMAT> for more details). Briefly, it is standard JSON which allows:

=over 2

=item * C<C>-style, C<C++>-style, C<shell>-style or custom comments.

=item * Template-style variables (e.g. C<E<lt>% appdir %E<gt>>)
which are substituted with user-specified data during parsing.

=item * Verbatim sections which are a sort of here-doc for JSON,
allowing strings to span multiple
lines, to contain single and double quotes unescaped,
to contain template-style variables.

=back

This module was created because I needed to include
long shell scripts containing lots of quotes and newlines,
in a configuration file which started as JSON.

The process is simple: so-called "enhanced JSON" is parsed
by L<config2perl>. Comments are removed, variables are
substituted, verbatim sections become one line again
and standard JSON is created. This is parsed with
L<JSON> (via L<Data::Roundtrip::json2perl>) to
produce a Perl data structure which is returned.

It has been tested with unicode data
(see C<t/070-config2perl-complex-utf8.t>)
with success. But who knows ?!?!

Here is an example:

    use Config::JSON::Enhanced;

    # simple "enhanced" JSON with comments in 3 styles: C,shell,CPP
    my $configdata = <<'EOJ';
     {
        /* 'a' is ... */
        "a" : "abc",
        # b is ...
        "b" : [1,2,3],
        "c" : 12 // c is ...
     }
    EOJ
    my $perldata = config2perl({
        'string' => $configdata,
        'commentstyle' => "C,shell,CPP",
    });
    die "call to config2perl() has failed" unless defined $perldata;
    # the standard JSON:
    # {"a" : "abc","b" : [1,2,3], "c" : 12}


    # this "enhanced" JSON demonstrates the use of variables
    # which will be substituted during the transformation to
    # standard JSON with user-specified data.
    # Notice that the opening and closing tags enclosing variable
    # names can be customised using the 'tags' input parameter,
    # so as to avoid clashes with content in the JSON.
    my $configdata = <<'EOJ';
     {
       "d" : [1,2,<% tempvar0 %>],
       "configfile" : "<%SCRIPTDIR%>/config/myapp.conf",
       "username" : "<% username %>"
        }
     }
    EOJ
    my $perldata = config2perl({
        'string' => $configdata,
        'commentstyle' => "C,shell,CPP",
        # optionally customise the tags enclosing the variables
        # when you want to avoid clashes with other strings in JSON
        #'tags' => ['<%', '%>'], # <<< these are the default values
        # user-specified data to replace the variables in
        # the "enhanced" JSON above:
        'variable-substitutions' => {
            'tempvar0' => 42,
            'username' => getlogin(),
            'SCRIPTDIR' => $FindBin::Bin,
        },
    });
    die "call to config2perl() has failed" unless defined $perldata;
    # the standard JSON
    # (notice how all variables in <%...%> are now replaced):
    # {"d" : [1,2,42],
    #  "username" : "yossarian",
    #  "configfile" : "/home/yossarian/B52/config/myapp.conf"
    # }


    # this "enhanced" JSON demonstrates "verbatim sections"
    # the puprose of which is to make more readable JSON strings
    # by allowing them to span over multiple lines.
    # There is also no need for escaping double quotes.
    # template variables (like above) will be substituted
    # There will be no comments removal from the verbatim sections.
    my $configdata = <<'EOJ';
     {
      "a" : <%begin-verbatim-section%>
      This is a multiline
      string
      "quoted text" and 'quoted like this also'
      will be retained in the string escaped.
      White space from beginning and end will be chomped.
 
      <%end-verbatim-section%>
      ,
      "b" = 123
     }
    EOJ
    my $perldata = config2perl({
        'string' => $configdata,
        'commentstyle' => "C,shell,CPP",
    });
    die "call to config2perl() has failed" unless defined $perldata;
    # the standard JSON (notice that "a" value is in a single line,
    # here printed broken for readability):
    # {"a" :
    #   "This is a multiline\nstring\n\"quoted text\" and 'quoted like
    #   this also'\nwill be retained in the string escaped.\nComments
    #   will not be removed.\nWhite space from
    #   beginning and end will be chomped.",
    #  "b" : 123
    # };


=head1 EXPORT

=over 4

=item * C<config2perl> is exported by default.

=back


=head1 SUBROUTINES

=head2 C<config2perl>

  my $ret = config2perl($params);
  die unless defined $ret;

Arguments:

=over 4

=item * C<$params> : a hashref of input parameters.

=back

Return value:

=over 4

=item * the parsed content as a Perl data structure
on success or C<undef> on failure.

=back

Given input content in L<ENHANCED JSON FORMAT>, this sub removes comments
(as per preferences via input parameters),
replaces all template variables, if any,
compacts L<Verbatim Sections>, if any, into a single-line
string and then parses
what remains as standard JSON into a Perl data structure
which is returned to caller. JSON parsing is done with
L<Data::Roundtrip::json2perl>, which uses L<JSON>.

Comments outside of JSON fields will always be removed,
otherwise JSON can not be parsed.

Comments inside of JSON fields, keys, values, strings etc.
will not be removed unless input parameter C<remove-comments-in-strings>
is set to 1 by the caller.

Comments (or what looks like comments with the current input parameters)
inside L<Verbatim Sections> will never be removed.

The input content to-be-parsed can be specified
with one of the following input parameters (entries in the
C<$params>):

=over 4

=item * C<filename> : content is read from a file with this name.

=item * C<filehandle> : content is read from a file which has already
been opened for reading by the caller.

=item * C<string> : content is contained in this string.

=back

Additionally, input parameters can contain the following keys:

=over 4

=item * C<commentstyle> : specify what comment style(s) to be expected
in the input content (if any) as a B<comma-separated string>. For example
C<'C,CPP,shell,custom(E<lt>E<lt>)(E<gt>E<gt>),custom(REM)()'>.
These are the values it understands:

=over 2

=item * C<C> : comments take the form of C-style comments which
are exclusively within C</* and */>. For example C<* I am a comment */>.
This is the B<default comment style> if none specified.

=item * C<CPP> : comments can the the form of C++-style comments
which are within C</* and */> or after C<//> until the end of line.
For example C</* I am a comment */>, C<// I am a comment to the end of line>.

=item * C<shell> : comments can be after C<#> until the end of line.
For example, C<# I am a comment to the end of line>.

=item * C<custom> : comments are enclosed (or preceded) by custom,
user-specified tags. The form is C<custom(OPENINGTAG)(CLOSINGTAG)>.
C<OPENINGTAG> is required. C<CLOSINGTAG> is optional meaning that
the comment extends to the end of line (just like C<shell> comments).
For example C<custom(E<lt>E<lt>)(E<gt>E<gt>)> or 
C<custom({{)(})> or C<custom(REM)()> or C<custom(E<lt>E<lt>E<lt>E<lt>)(E<gt>E<gt>)>.
C<OPENINGTAG> and C<CLOSINGTAG> do not need to be of
the same character length as it is
obvious from the previous example. A word of warning:
the regex for identifying comments (and variables and verbatim sections)
has the custom tags escaped for special regex characters
(with the C<\Q ... \E> construct). So you are pretty safe in using
any character. Please report weird behaviour.

B<Warning> : either opening or closing comment tags must not
be the same as opening or closing variables / verbatim section tags.

=back

=item * C<variable-substitutions> : a hashref whose keys are
variable names as they occur in the input I<Enhanced JSON> content
and their corresponding values should substitute them. I<Enhanced JSON>,
can contain template variables in the form C<E<lt>% my-var-1 %E<gt>>. These
must be replaced with data which is supplied to the call of C<config2perl()>
under the parameters key C<variable-substitutions>, for example:
  
  config2perl({
    "variable-substitutions" => {
      "my-var-1" => 42,
      "SCRIPTDIR" => "/home/abc",
    },
    "string" => '{"a":"<% my-var-1 %>", "b":"<% SCRIPTDIR %>/app.conf"}',
  });

Variable substitution will be performed in both
keys and values of the input JSON, including L<Verbatim Sections>.

=item * C<remove-comments-in-strings> : by default no attempt
to remove what-looks-like-comments from JSON strings
(both keys and values). However, if this flag is set to
C<1> anything that looks like comments (as per the 'C<commentstyle>'
parameter) will be removed from inside all JSON strings
(keys or values) unless they were part of verbatim section.

This does not apply for the content verbatim sections.
What looks like comments to us, inside verbatim sections
will be left intact.

For example consider the JSON string C<"hello/*a comment*/">
(which can be a key or a value). If C<remove-comments-in-strings> is
set to 1, then the JSON string will become C<hello>. If set to
0 (which is the default) it will be unchanged.

=item * C<tags> : specify the opening and closing tags for template
variables and verbatim section as an ARRAYref of exactly 2 items (the
opening and the closing tags). By default the opening tag is C<E<gt>%>
and the closing tag is C<%E<lt>>. A word of warning:
the regex for identifying variables and verbatim sections (and comments)
has the custom tags escaped for special regex characters
(with the C<\Q ... \E> construct). So you are pretty safe in using
any character. Please report weird behaviour.

If you set C<tags => [ '[::', '::]' ]>
then your template variables should look like this: C<{:: var1 ::]> and
verbatim sections like this: C<[:: begin-verbatim-section ::]>.

=item * C<debug> : set this to a positive integer to increase verbosity
and dump debugging messages. Default is zero for zero verbosity.

=back

See section L<ENHANCED JSON FORMAT> for details on the format
of B<what I call> I<enhanced JSON>.

C<config2perl> returns the parsed content as a Perl data structure
on success or C<undef> on failure.


=head1 ENHANCED JSON FORMAT

This is JSON with added reasonable, yet completely ad-hoc, enhancements
(from my point of view).

These enhancements are:

=over 4

=item * B<Comments are allowed>:

=over 2

=item * C<C>-style comments take the form of C-style comments which
are exclusively within C</* and */>. For example C<* I am a comment */>

=item * C<C++>-style comments can the the form of C++-style comments
which are within C</* and */> or after C<//> until the end of line.
For example C</* I am a comment */>, C<// I am a comment to the end of line.>

=item * C<shell>-style comments can be after C<#> until the end of line.
For example, C<# I am a comment to the end of line.>

=item * comments with C<custom>, user-specified, opening and
optional closing tags
which allows fine-tuning the process of deciding on something being a
comment.

=back

=item * B<Template variables support> : template-style
variables in the form of C<E<lt>% HOMEDIR %E<gt>>
will be substituded with values specified by the
user during parsing. Note that variable
names are case sensitive, they can contain spaces, hyphens etc.,
for example: C<E<lt>%   abc- 123 -  xyz   %E<gt>> (the variable
name is C<abc- 123 -  xyz>, notice
the multiple spaces between C<123> and C<xyz> and
also notice the absence of any spaces before C<abc> and after C<xyz>).

The tags for denoting a template variable
are controled by the 'C<tags>' parameter to the sub L<config2perl>.
Defaults are C<E<lt>%> and C<%E<gt>>.

=item * B<Verbatim Sections> : similar to here-doc, this feature allows
for string values to span over multiple lines and to contain
un-escpaed quotes. This is useful if you want a JSON value to
contain a shell script, for example. Verbatim sections can
also contain template variables which will be substituted. No
comment will be removed.

=item * Unfortunately, there is not support for ignoring B<superfluous commas> in JSON,
in the manner of glorious Perl.

B<Warning> : either opening or closing comment tags must not
be the same as opening or closing variables / verbatim section tags.

=back

=head2 Verbatim Sections

A B<Verbaitm Section> in this ad-hoc, so-called I<Enhanced JSON> is content
enclosed within C<E<lt>%begin-verbatim-section%E<gt>>
and C<E<lt>%end-verbatim-section%E<gt>> tags.
A verbatim section's content may span multiple lines (which when converted to JSON will preserve them
by escaping. e.g. by replacing them with 'C<\n>') and can
contain template variables to be substituted with user-specified data.
All single and double quotes can be left un-escaped, the program will
escape them (hopefully correctly!).

The content of Verbatim Sections will have all its
template variables substituted. Comments will
be left untouched.

The tags for denoting the opening and closing a verbatim section
are controled by the 'C<tags>' parameter to the sub L<config2perl>.
Defaults are C<E<lt>%> and C<%E<gt>>.

Here is an example of enhanced JSON which contains comments, a verbatim section
and template variables:

  my $con = <<'EOC';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    # save current dir, this comment remains
    pushd . &> /dev/null
    # following quotes will be escaped
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    # go back to initial dir
    popd &> /dev/null
  <%end-verbatim-section%>
  /* the end of the verbatim section */
    ],
    // this is an example of a template variable
    "expected result" : "<% expected-res123 %>"
  }
  EOC

  # Which, can be processed thusly:
  my $res = config2perl({
    'string' => $con,
    'commentstyle' => 'C,CPP',
    'variable-substitutions' => {
      'appdir' => Cwd::abs_path($FindBin::Bin),
      'expected-res123' => 42
    },
  });
  die "call to config2perl() has failed" unless defined $res;

  # following is the dump of $res, note the breaking of the lines
  # in the 'long bash script' is just for readability.
  # In reality, it is one long line:
  {
    "expected result" => 42,
    "long bash script" => [
      "/usr/bin/bash",
      "# save current dir, this comment remains\npushd . &> /dev/null\n
       # following quotes will be escaped\necho \"My 'appdir' is
       \\\"/home/babushka/Config-JSON-Enhanced/t\\\"\"\n
       echo \"My current dir: \" \$(echo \$PWD) \" and bye\"\n# go back to
       initial dir, this comment remains\npopd &> /dev/null"
    ]
  };

A JSON string can contain comments which
you may want to retain (note:
comments filtering will not apply to verbatim sections).

For example if the
content is a unix shell script it is
possible to contain comments like C<# comment>.
These will be removed along with all other comments
in the entire JSON input if you are using
C<shell> style comments. Another problem
is when JSON string contains comment opening
or closing tags. For example consider this
cron spec : C<*/15 * * * *> which contains
the closing string of a C-style comment and
will cass a big mess.

You have two options
in order to deal with this problem:

=over 2

=item * Set 'remove-comments-in-strings'
parameter to sub L<config2perl> to 0. This will
keep ALL comments in all strings (both keys and values).
This is a one-size-fits-all solution and it is not ideal.

=item * The B<best solution> is to change the comment style
of the input, so called Enhanced, JSON to something
different to the comments you are trying to keep in your
strings. So, for example, if you want to retain the comments
in a unix shell script then use C as the comment style for
the JSON.

Note that it is possible (since version 0.03) to
use custom tags for comments. This greatly increases
your chances to make L<config2perl> understand what
comments you want to keep as part of your data.

For example, make your comments like C<[::: comment :::]>
or even like C<E<lt>!-- comment --E<gt>> using
C<'commentstyle' =E<gt> 'custom([:::)(:::])'>
and C<'commentstyle' =E<gt> 'custom(E<lt>!--)(--E<gt>)'>,
respectively.

=back

=head1 TIPS

You can change the tags used in denoting the template variables
and verbatim sections with the C<tags> parameter to the
sub L<config2perl>. Use this feature to change tags
to something else if your JSON contains
the same character sequence for these tags and avoid clashes
and unexpected substitutions. C<E<lt>%> and C<%E<gt>> are the default
tags.

Similarly, C<custom> comment style (specifying what should be
the opening and, optionally, closing tags) can be employed if your
JSON strings contain something that looks like comments
and you want to avoid their removal.

=head1 WARNINGS/CAVEATS

In order to remove comments within strings, a simplistic regular
expression for
extracting quoted strings is employed. It finds anything
within two double quotes. It tries to handle escaped quotes within
quoted strings.
This regex may be buggy or may not
be complex enough to handle all corner cases. Therefore, it is
possible that setting parameter C<remove-comments-in-strings> to 1
to sub L<config2perl> to cause unexpected results. Please
report these cases, see L<SUPPORT>.

The regex for identifying comments, variables and verbatim sections
has the custom tags escaped for special regex characters
(with the C<\Q ... \E> construct). So you are pretty safe in using
any character. Please report weird behaviour.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 HUGS

! Almaz !


=head1 BUGS

Please report any bugs or feature requests to C<bug-config-json-enhanced at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-JSON-Enhanced>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::JSON::Enhanced


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-JSON-Enhanced>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Config-JSON-Enhanced>

=item * Search CPAN

L<https://metacpan.org/release/Config-JSON-Enhanced>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Config::JSON::Enhanced
