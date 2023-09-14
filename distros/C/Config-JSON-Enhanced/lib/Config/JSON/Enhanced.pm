package Config::JSON::Enhanced;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

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

	my $commentstyle = exists($params->{'commentstyle'}) && defined($params->{'commentstyle'})
		? $params->{'commentstyle'} : 'C'
	;

	my $tsubs = exists($params->{'variable-substitutions'})
		? $params->{'variable-substitutions'} : undef
	;

	# firstly, remove templated variables if any
	for my $ak (keys %$tsubs){
		my $av = $tsubs->{$ak};
		$contents =~ s/<\s*%\s*${ak}\s*%\s*>/${av}/g;
	}
	# this is a warning:
	# we can not be sure if this <% xyz %> is part of the content or a forgotten templated variable
	if( $contents =~ /<\s*%!(:?(:?begin-verbatim-section)|(:?end-verbatim-section))%\s*>/ ){ warn "--begin content:\n".$contents."\n--end content.\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : warning, there may still be remains of templated variables in the specified content, see above what remained after all template variables substitutions were done." }

	# secondly, remove the VERBATIM multiline sections and transform them
	my @verbs;
	my $idx = 0;
	while( $contents =~ s/<%\s*begin-verbatim-section\s*%>(.+?)<%\s*end-verbatim-section\s*%>/"<%verbatim-section-${idx}%>"/gs ){
		my $vc = $1;
		# remove from start and end of whole string newlines+spaces
		$vc =~ s/^[\n\t ]+//;
		$vc =~ s/[\n\t ]+$//;
		# remove newlines followed by optional spaces at the beginning of each line
		$vc =~ s/\n+[ \t]*/\\n/gs;
		# escape all double quotes (naively)
		# but not those which are already escaped (naively)
		$vc =~ s/\\"/<%QQ%>/g;
		$vc =~ s/"/\\"/g;
		$vc =~ s/<%QQ%>/\\\\\\"/g;
		# so echo "aa \"xx\""
		# becomes echo \"aa \\\"xx\\\"\"
		push @verbs, $vc;
		$idx++;
	}
	# and now substitute the transformed verbatim sections back
	for($idx=scalar(@verbs);$idx-->0;){
		$contents =~ s/<%verbatim-section-${idx}%>/$verbs[$idx]/g;
	}

	# thirdly, remove comments: 'shell' and/or 'C' and/or 'CPP'
	my $tc = $commentstyle;
	if( $tc =~ s/\bC\b//i ){
		$contents =~ s/\/\*(?:(?!\*\/).)*\*\/(\n?)/$1/sg;
	}
	if( $tc =~ s/\bCPP\b//i ){
		$contents =~ s/\/\*(?:(?!\*\/).)*\*\/(\n?)/$1/sg;
		$contents =~ s!//.*$!!mg;
	}
	if( $tc =~ s/\bshell\b//i ){
		$contents =~ s/#.*$//mg;
	}
	if( $tc =~ /[a-z]/i ){ warn __PACKAGE__.'::config2perl()'." (line ".__LINE__.") : error, comments style '${commentstyle}' was not understood, this is what was left after parsing it: '${tc}'."; return undef }

	# this is a warning:
	# we can not be sure if this <% xyz %> is part of the content or a forgotten templated variable
	if( $contents =~ /<\s*%.+?-verbatim-section\s*%\s*>/ ){ warn "--begin content:\n".$contents."\n--end content.\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : warning, there may still be remains of templated variables in the specified content, see above what remained after all verbatime sections were removed." }

	my $inhash = json2perl($contents);
	if( ! defined $inhash ){ warn $contents."\n\n".__PACKAGE__.'::config2perl()'." (line ".__LINE__.") : error, call to ".'Data::Roundtrip::json2perl()'." has failed for above json string and comments style '${commentstyle}'."; return undef }
	return $inhash
}

=head1 NAME

Config::JSON::Enhanced - JSON-based config with C/Shell-style comments, verbatim sections and variable substitutions

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module provides subroutine C<config2perl()> for parsing configuration content,
from files or strings,  based on, what I call, "enhanced JSON" (see section
L<ENHANCED JSON FORMAT> for more details). Briefly, it is standard JSON which allows:


=over 2

=item * C<C>-style, C<C++>-style or C<shell>-style comments.

=item * template variables (e.g. C<E<lt>% appdir %E<gt>>) which are substituted with user-specified data.

=item * verbatim sections which are a sort of here-doc for JSON
which may be spanning multiple
lines and contained single and double quotes are not required to be escaped.
This enhances the readbility of long JSON which may contain, in my case,
long shell scripts with lots of quotes and newlines.

=back

It has been tested with unicode data (see C<t/25-config2perl-complex-utf8.t>)
with success. But who knows ?!?!

Here is an example:

    use Config::JSON::Enhanced qw/config2perl/;

    my $configdata = 'EOJ';
    {
        "a" : "abc",
        "b" : {
          /* this is a comment */
          "c" : <%begin-verbatim-section%>
      This is a multiline string
    /* all spaces between the start of the line and
       the first char will be erased.
       Newlines are escaped and kept.
    */
      with "quoted text" and 'this also'
      and comments like /* this */ or
      # this
      will be retained in the string
    /* white space from beginning and end will be erased */

    <%end-verbatim-section%>
          ,
          "d" : [1,2,<% tempvar0 %>],
          "e" : "< % tempvar1 % > user and <%tempvar2%>!"
        }
    }
    EOJ

    my $perldata = config2perl({
        'string' => $configdata,
        'commentstyle' => "C,shell,CPP",
        'variable-substitutions' => {
            # substitutions do not add extra quotes
            'tempvar0' => 42,
            'tempvar1' => 'hello',
            'tempvar2' => 'goodbye',
        },
    });
    die "call to config2perl() has failed" unless defined $perldata;

    # and here is the dump of the perl data structure $perldata
   {
     "b" => {
       "d" => [1,2,42],
       "c" => "This is a multiline string\n\nwith \"quoted text\" and 'this also'\nand comments like  or\n# this\nwill be retained in the string\n",
       "e" => "hello user and goodbye!"
     },
     "a" => "abc"
   }

=head1 EXPORT

=over 4

=item * C<config2perl>

=back


=head1 SUBROUTINES

=head2 C<config2perl>

  my $ret = config2perl($params);

Arguments:

=over 4

=item * C<$params>

=back

Return value:

=over 4

=item * C<$ret> on success or C<undef> on failure.

=back

Given I<Enhanced JSON> content it removes any comments,
it replaces all template strings, if any, and then parses
what remains as standard JSON into a Perl data structure which
is returned.

JSON content to-be-parsed can be specified with one of the following
keys in the input parameters hashref (C<$params>):

=over 4

=item * C<filename> : content is read from a file with this name.

=item * C<filehandle> : content is read from a file which has already
been opened for reading by the caller.

=item * C<string> : content is contained in this string.

=back

Additionally, input parameters can contain the following keys:

=over 4

=item * C<commentstyle> : specify what comment style(s) to be expected
in the input content (if any) as a B<comma-separated string>. These
are the values it understands:

=over 2

=item * C<C> : comments take the form of C-style comments which
are exclusively within C</* and */>. For example C<* I am a comment */>.
This is the B<default comment style> if none specified.

=item * C<CPP> : comments can the the form of C++-style comments
which are within C</* and */> or after C<//> until the end of line.
For example C</* I am a comment */>, C<// I am a comment to the end of line>.

=item * C<shell> : comments can be after C<#> until the end of line.
For example, C<# I am a comment to the end of line>.

=back

=item * C<variable-substitutions> : a hashref whose keys are
variable names as they occur in the input I<Enhanced JSON> content
and their corresponding values should substitute them. I<Enhanced JSON>,
can contain template variables in the form C<E<lt>% my-var-1 %E<gt>>. These
must be replaced with data which is supplied to the call of C<config2perl()>
under the parameters key C<variable-substitutions>, e.g.::
  
  config2perl({
    "variable-substitutions" => {
      "my-var-1" => 42
    },
    "string" => '{ "xyz" : "<% my-var-1 %>" }',
  });

Variable substitution will be performed in keys and values of the input JSON.

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

=back

=item * B<Template variables support> : template variables in the form of C<E<lt>%HOMEDIR%E<gt>>
will be substituded with their actual values specified by the user during parsing. Note that variable
names are case sensitive, they can contain spaces, hyphens etc. and the tags enclosing such
variables can contain spaces, for example: C< % E<lt>   abc-123   xyz %E<gt>> (the variable
name is C<abc-123   xyz> (notice the multiple spaces between C<123> and C<xyz>).

=item * Unfortunately, there is not support for ignoring B<superfluous commas> in JSON,
in the manner of glorious Perl.

=back

=head2 Verbatim Sections

A B<Verbaitm Section> in this ad-hoc, so-called I<Enhanced JSON> is content
enclosed within C<E<lt>%begin-verbatim-section%E<gt>>  and C<E<lt>%end-verbatim-section%E<gt>> tags.
This content may span multiple lines (which when converted to JSON will preserve them
by escaping), can contain comments (see the beginning of this section) and can
contain template variables to be substituted with user-specified data.

Here is an example of enhanced JSON which contains comments, a verbatim section
and template variables:

  my $con = <<'EOC';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    pushd . &> /dev/null
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    popd &> /dev/null
  <%end-verbatim-section%>
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

  # the dump of $res is:
  {
    "expected result" => 42,
    "long bash script" => [
      "/usr/bin/bash",
      "pushd . &> /dev/null\necho \"My 'appdir' is \\\"/home/andreas/PROJECTS/CPAN/Config-JSON-Enhanced/t\\\"\"\necho \"My current dir: \" \$(echo \$PWD) \" and bye\"\npopd &> /dev/null"
    ]
  };


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

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
