package CGI::XMLForm;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use CGI;
use CGI::XMLForm::Path;
use XML::Parser;

@ISA = qw(CGI);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.10';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	bless ($self, $class);          # reconsecrate
	return $self;
}

sub readXML {
	my $self = shift;
	my $xml = shift;

	my @queries = @_;

	my @Requests;

	my $req = new CGI::XMLForm::Path();
	do {
		$req = new CGI::XMLForm::Path(shift @queries, $req);
		push @Requests, $req;
	} while @queries;

	my $currenttree = new CGI::XMLForm::Path();

	my $p = new XML::Parser(Style => 'Stream',
		_parseresults => [],
		_currenttree => $currenttree,
		_requests => \@Requests,
		);

	my $results;
	eval {
		$results = $p->parse($xml);
#		warn "Parse returned ", @{$results}, "\n";
	};
	if ($@) {
		return $@;
	}
	else {
		return @{$results};
	}
}

sub StartTag {
	my $expat = shift;
	return $expat->finish() if $expat->{_done};
	my $element = shift;
#	my %attribs = %_;

#warn "Start: $element\n";
	$expat->{_currenttree}->Append($element, %_);
	my $current = $expat->{_currenttree};

#warn "Path now: ", $expat->{_currenttree}->Path, "\n";

	foreach (0..$#{$expat->{_requests}}) {
		next unless defined $expat->{_requests}->[$_]->Attrib;
# warn "Looking for attrib: ", $expat->{_requests}->[$_]->Attrib, "\n";
		if (defined $_{$expat->{_requests}->[$_]->Attrib}) {
			# Looking for attrib
			if ($expat->{_requests}->[$_]->isEqual($current)) {
				# We have equality!
				found($expat, $expat->{_requests}->[$_], $_{$expat->{_requests}->[$_]->Attrib});
				splice(@{$expat->{_requests}}, $_, 1) unless $expat->{_requests}->[$_]->isRepeat;
				$expat->{_done} = 1 if (@{$expat->{_requests}} == 0);
				return;
			}
		}
	}
}

sub EndTag {
	my $expat = shift;
	return $expat->finish() if $expat->{_done};
# warn "End: $_\n";

	$expat->{_currenttree}->Pop();
}

sub Text {
	my $expat = shift;
	my $text = $_;

	return $expat->finish() if $expat->{_done};

	my @Requests = @{$expat->{_requests}};
	my $current = $expat->{_currenttree};

	foreach (0..$#Requests) {
		if (!$Requests[$_]->Attrib) {
			# Not looking for an attrib
#			warn "Comparing : ", $Requests[$_]->Path, " : ", $expat->{_currenttree}->Path, "\n";
			if ($Requests[$_]->isEqual($current)) {
				found($expat, $Requests[$_], $text);
				splice(@{$expat->{_requests}}, $_, 1) unless $Requests[$_]->isRepeat;
				$expat->{_done} = 1 if (@Requests == 0);
				return;
			}
		}
	}
}

sub found {
	my $expat = shift;
	my ($request, $found) = @_;

#warn "Found: ", $request->Path, " : $found\n";

	if ($request->Path =~ /\.\*/) {
		# Request path contains a regexp
		my $match = $request->Path;
		$match =~ s/\[(.*?)\]/\\\[$1\\\]/g;

#		warn "Regexp: ", $expat->{_currenttree}->Path, " =~ |$match|\n";
		$expat->{_currenttree}->Path =~ /$match/;
		push @{$expat->{_parseresults}}, $&, $found;
	}
	else {
		push @{$expat->{_parseresults}}, $request->Path, $found;
	}

}

sub EndDocument {
	my $expat = shift;
	delete $expat->{_done};
	delete $expat->{_currenttree};
	delete $expat->{_requests};
	return $expat->{_parseresults};
}

sub formatElement($$) {
	# Properly formats elements whether opening or closing.

	my $cgi = shift;
	my $open = shift;
	my $element = shift;
	my $level = shift;

	$element =~ s/&slash;/\//g;

	$element =~ /^(.*?)(\[(.*)\])?$/;
	my $output = $1;
	my $attribs = $3 || "";

	if (!$open) {
		if (!$cgi->{'.closetags'}) {
			$cgi->{'.closetags'} = $level;
			return "</$output>\n";
		}
		else {
			return ("\t" x --$cgi->{'.closetags'}) . "</$output>\n";
		}
	}

	# If we have attributes
	while ($attribs =~ /\@(\w+?)=([\"\'])(.*?)\2(\s+and\s+)?/g) {
		$output .= " $1=\"$3\"";
	}
	my $save = $cgi->{'.closetags'};
	$cgi->{'.closetags'} = 0;
	return ($save ? '' : "\n") . ("\t" x $level) . "<$output>";
}

sub ToXML {
	shift()->toXML(@_);
}

sub toXML {
	my $self = shift;
	my $filename = shift;

	if (defined $filename) {
		local *OUTPUT;
		open(OUTPUT, ">$filename") or die "Can't open $filename for output: $!";
		print OUTPUT $self->{".xml"};
		close OUTPUT;
	}

	defined wantarray && return $self->{".xml"};
}

sub parse_params {
    my($self,$tosplit) = @_;
    my(@pairs) = split('&',$tosplit);
    my($param,$value);
	my $output = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>";

	my @prevStack;
	my @stack;
	my @rawParams;
	my $relative;
	$self->{'.closetags'} = 0;

    foreach (@pairs) {
		($param,$value) = split('=',$_,2);
		$param = $self->unescape($param);
		$value = $self->unescape($value);

		$self->add_parameter($param);
		push (@{$self->{$param}},$value);

		next if $param =~ /^xmlcgi:ignore/;
		next if $param =~ /^\.\w/; # Skip CGI.pm ".submit" and other buttons

		push @rawParams, $param, $value;

		# Encode values
		$value =~ s/&/&amp;/g;
		$value =~ s/</&lt;/g;
		$value =~ s/>/&gt;/g;
		$value =~ s/'/&apos;/g;
		$value =~ s/"/&quot;/g;

		$value =~ s/\//\&slash;/g; # We decode this later...
		$param =~ s/\[(.*?)\/(.*?)\]/\[$1\&slash;$2\]/g;

		# Here we make the attribute into an internal attrib
		# so that tree compares work properly
		my $attrib = 0;
		if($param =~ s/(\])?\/(\@\w+)$/(($1 && " and ")||"[").qq($2="$value"])/e) {
			$attrib = 1;
		}

		# Do work here
		if ($param =~ s/^\///) {
			# If starts with a slash it's a root element
			@stack = split /\//, $param;
			$relative = 0;
		}
		else {
			# Otherwise it's a relative path

			# - We don't need to do this, but it's here commented out
			# to show what we're implying.
			# @stack = @prevStack;


			# We don't want the last element if the previous param
			# was also a relative param.
			my $top = pop @stack if ($relative);

			foreach ( split(/\//, $param)) {
				if ($_ eq "..") {
					if ($top) {
						$output .= $self->formatElement(0, $top, scalar @stack);
						$top = '';
						pop @prevStack;
					}
					$output .= $self->formatElement(0, pop(@stack), scalar @stack);
					pop @prevStack;
				}
				else {
					push @stack, $_;
				}
			}
			$relative++;
		}

	#	print STDERR "Prev Stack: ", join(", ", @prevStack), "\n";
	#	print STDERR "New  Stack: ", join(", ", @stack), "\n----------\n";

		foreach my $i (0..$#stack) {

			if (defined $prevStack[$i]) {

				# We've travelled along this branch of the tree before.
				if (($i == $#stack) || ($prevStack[$i] ne $stack[$i])) {

					# If we've reached the end of the branch, or the branch has changed...
					while ($i <= $#prevStack) {
						# Close the previous branch
						$output .= $self->formatElement(0, pop(@prevStack),
							scalar @prevStack);
					}

					# And add this new branch
					$output .= $self->formatElement(1, $stack[$i], scalar
						@prevStack);
					push @prevStack, $stack[$i];
				}
			}

			else {
				# here we're traversing out into the tree where we've not travelled before.
				$output .= $self->formatElement(1, $stack[$i], scalar @prevStack);
				push @prevStack, $stack[$i];
			}
		}

		# Finally, we output the contents of the form field, unless it's an attribute form field
		if (!$attrib) {
			$output .= $value;
		}

		# Store the previous stack.
		@prevStack = @stack;
	}

	# Finish by completely popping the stack off.
	while (@prevStack) {
		$output .= $self->formatElement(0, pop(@prevStack), scalar @prevStack);
	}

	$self->{".xml"} = $output;
	$self->{rawParams} = \@rawParams;

	1;
}

1;
__END__

=head1 NAME

CGI::XMLForm - Extension of CGI.pm which reads/generates formated XML.

NB: This is a subclass of CGI.pm, so can be used in it's place.

=head1 SYNOPSIS

  use CGI::XMLForm;

  my $cgi = new CGI::XMLForm;

  if ($cgi->param) {
  	print $cgi->header, $cgi->pre($cgi->escapeHTML($cgi->toXML));
  }
  else {
  	open(FILE, "test.xml") or die "Can't open: $!";
	my @queries = ('/a', '/a/b*', '/a/b/c*', /a/d');
    print $cgi->header,
	      $cgi->pre($cgi->escapeHTML(
		  join "\n", $cgi->readXML(*FILE, @queries)));
  }

=head1 DESCRIPTION

This module can either create form field values from XML based on XQL/XSL style
queries (full XQL is _not_ supported - this module is designed for speed), or it
can create XML from form values. There are 2 key functions: toXML and readXML.

=head2 toXML

The module takes form fields given in a specialised format,
and outputs them to XML based on that format. The idea is that you
can create forms that define the resulting XML at the back end.

The format for the form elements is:

  <input name="/body/p/ul/li">

which creates the following XML:

  <body>
    <p>
	  <ul>
	    <li>Entered Value</li>
	  </ul>
	</p>
  </body>

It's the user's responsibility to design appropriate forms to make
use of this module. Details of how come below...

Also supported are attribute form items, that allow creation
of element attributes. The syntax for this is:

  <input name="/body/p[@id='mypara' and @onClick='someFunc()']/@class">

Which creates the following XML:

  <body>
    <p id="mypara" onClick="someFunc()" class="Entered Value"></p>
  </body>

Also possible are relative paths. So the following form elements:

  <input type="hidden" name="/table/tr">
  <input type="text" name="td">
  <input type="text" name="td">
  <input type="text" name="../tr/td">

Will create the following XML:

  <table>
    <tr>
	  <td>value1</td>
	  <td>value2</td>
	</tr>
	<tr>
	  <td>value3</td>
	</tr>
  </table>

=head1 SYNTAX

The following is a brief syntax guideline

Full paths start with a "/" :

  "/table/tr/td"

Relative paths start with either ".." or just a tag name.

  "../tr/td"
  "td"

B<Relative paths go at the level above the previous path, unless the previous
path was also a relative path, in which case it goes at the same level.> This
seems confusing at first (you might expect it to always go at the level above
the previous element), but it makes your form easier to design. Take the
following example: You have a timesheet (see the example supplied in the
archive) that has monday,tuesday,etc. Our form can look like this:

  <input type="text" name="/timesheet/projects/project/@Name">
  <input type="text" name="monday">
  <input type="text" name="tuesday">
  ...

Rather than:

  <input type="text" name="/timesheet/projects/project/@Name">
  <input type="text" name="monday">
  <input type="text" name="../tuesday">
  <input type="text" name="../wednesday">
  ...

If unsure I recommend using full paths, relative paths are great for repeating
groups of data, but weak for heavily structured data. Picture the following
paths:

  /timesheet/employee/name/forename
  ../surname
  title
  ../department

This actually creates the following XML:

  <timesheet>
    <employee>
	  <name>
	    <forename>val1</forname>
		<surname>val2</surname>
		<title>val3></title>
	  </name>
	  <department>val4</department>
	</employee>
  </timesheet>

Confusing eh? Far better to say:

  /timesheet/employee/name/forename
  /timesheet/employee/name/surname
  /timesheet/employee/name/title
  /timesheet/employee/department

Or alternatively, better still:

  /timesheet/employee/name (Make hidden and no value)
  forename
  surname
  title
  ../department

Attributes go in square brackets. Attribute names are preceded with an "@",
and attribute values follow an "=" sign and are enclosed in quotes. Multiple
attributes are separated with " and ".

  /table[@bgcolor="blue" and @width="100%"]/tr/td

If setting an attribute, it follows after the tag that it is associated with,
after a "/" and it's name is preceded with an "@".

  /table/@bgcolor

=head2 readXML

readXML takes either a file handle or text as the first parameter and a list of
queries following that. The XML is searched for the queries and it returns a
list of tuples that are the query and the match.

It's easier to demonstrate this with an example. Given the following XML:

  <a>Foo
    <b>Bar
	  <c>Fred</c>
	  <c>Blogs</c>
	</b>
	<b>Red
	  <c>Barbara</c>
	  <c>Cartland</c>
	</b>
	<d>Food</d>
  </a>

And the following queries:

  /a
  /a/b*
  c*
  /a/d

it returns the following result as a list:

  /a
  Foo
  /a/b
  Bar
  c
  Fred
  c
  Blogs
  /a/b
  Red
  c
  Barbara
  c
  Cartland
  /a/d
  Food

(NB: This is slightly incorrect - for /a and /a/b it will return "Foo\n    " and
"Bar\n      " respectively).

The queries support relative paths like toXML (including parent paths), and
they also support wildcards using ".*" or ".*?" (preferably ".*?" as it's
probably a better match). If a wildcard is specified the results will have the
actual value substituted with the wildcard. Wildcards are a bit experimental,
so be careful ;-)

=head2 Caveats

There are a few caveats to using this module:

=over
=item * Parameters must be on the form in the order they will appear in the XML.
=item * There is no support for multiple attribute setting (i.e. you can only
set one attribute for an element at a time).
=item * You can't set an attribute B<and> a value for that element, it's one or the
other.
=item * You can use this module in place of CGI.pm, since it's a subclass.
=item * There are bound to be lots of bugs! Although it's in production use
right now - just watch CPAN for regular updates.
=back

=head1 AUTHOR

Matt Sergeant msergeant@ndirect.co.uk, sergeant@geocities.com

Based on an original concept, and discussions with, Jonathan Eisenzopf.
Thanks to the Perl-XML mailing list for suggesting the XSL syntax.

Special thanks to Francois Belanger (francois@sitepak.com) for
his mentoring and help with the syntax design.

=head1 SEE ALSO

CGI(1), CGI::XML

=cut
