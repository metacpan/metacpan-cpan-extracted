use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd;
our $VERSION = '0.98';
use Apache::Wyrd::Services::SAK qw (token_parse slurp_file);
use Apache::Wyrd::Services::Tree;
use Apache::Util;
use Apache::Constants qw(:common);

###############################################################################
#Globals
###############################################################################

my $_dbl = undef;

my %_loglevel = (
	'fatal'		=>	0,
	'error'		=>	1,
	'warn'		=>	2,
	'info'		=>	3,
	'debug'		=>	4,
	'verbose'	=>	5,
);

###############################################################################
#Error Handling Anonymous Subroutines
###############################################################################

my %_error_handler = ();

my $_disabled_error_handler = sub {
	return undef
};

my $_enabled_error_handler = sub {
	my ($self, $value) = @_;
	my @caller = caller();
	$caller[0] =~ s/.+://;
	$caller[2] =~ s/.+://;
	my $id = "($caller[0]:$caller[2])";
	$value = join(':', $id, $value);
	$_dbl->log_event($value) if ($_dbl);
	print STDERR "$value\n";
};

my $_fatal_error_handler = sub {
	my ($self, $value) = @_;
	die "_raise_exception called without object.  Always call _raise_exception as a method, not a subroutine."
		unless UNIVERSAL::isa($self, 'Apache::Wyrd');
	my @caller = caller();
	$caller[0] =~ s/.+://;
	$caller[2] =~ s/.+://;
	my $processing = undef;
	$processing = $self->dbl->self_path if ($_dbl);
	$processing ||= "{COULD NOT PROCESS PATH TO PERL OBJECT}";#assume self_path could be erroneously null
	my $id = "($processing -- $caller[0]:$caller[2])";
	$value = join(':', $id, $value , "\n". $self->{'_as_html'} . "\n");
	if ($_dbl) {
		my $htmlvalue = join(':', $id, $value , "<BR>\n". Apache::Util::escape_html($self->{'_as_html'}) . "<BR>\n");
		$_dbl->log_event($htmlvalue);
	}
	die $value;
};

sub _verbose {
	goto $_error_handler{$_loglevel{'verbose'}};
}

sub _debug {
	goto $_error_handler{$_loglevel{'debug'}};
}

sub _info {
	goto $_error_handler{$_loglevel{'info'}};
}

sub _warn {
	goto $_error_handler{$_loglevel{'warn'}};
}

sub _error {
	goto $_error_handler{$_loglevel{'error'}};
}

sub _fatal {
	goto $_error_handler{$_loglevel{'fatal'}};
}

sub _raise_exception {
	goto $_fatal_error_handler;
}

=pod

=head1 NAME

Apache::Wyrd - HTML embeddable perl objects under mod_perl

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Apache::Wyrd is the core module in a collection of interoperating
modules that allow the rapid object-oriented development of web sites in
Apache's mod_perl environment (LAMP).  This collection includes a very
flexible, HTML-friendly method of defining dynamic items on a web page,
and interfacing directly to perl objects with them.  It comes with many
pre-built objects to support a web site such as an authentication
module, an reverse-lookup database, granular debugging, and smart
forms/inputs and their interfaces to a DBI-compliant SQL application.

The collection is not meant to be a drop-in replacement for PHP,
ColdFusion, or other server-side parsed content creation systems, but to
provide a more flexible framework for organic custom perl development
for an experienced perl programmer who favors an object-oriented
approach.  It has been designed to simplify the transition from static
to dynamic web content by allowing the design of objects that can be
operated by a non-perl programmer through the modification of the HTML
page on which the content is to be delivered.

The Apache::Wyrd module itself is an abstract class used to create
HTML-embeddable perl objects (I<Wyrds>).  The embedded objects are
interpreted from HTML files by an instance of the abstract class
C<Apache::Wyrd::Handler>. Most Wyrds also require an instance of an
C<Apache::Wyrd::DBL> object to store connection information and to
provide intermediary access to the Apache request and any DBI-style
database interfaces.

Each Wyrd has a corresponding perl module which performs work and
generates any output at the Wyrd's location on the HTML page.  Each
of these objects is a derived class of Apache::Wyrd, and consequently
draws on the existing methods of the abstract class as well as
implements methods of its own.  A few "hook" methods (C<_setup>,
C<_format_output>, and C<_generate_output> in particular) are defined in
the abstract class for this purpose.

The modules in this distribution are not meant to be used directly.
Instead, instances of the objects are created in another namespace (in
all POD synopses called BASENAME, but it can be any string acceptable as
a single namespace of a perl class) where the Handler object has been
configured to use that namespace in interpreting HTML pages (see
C<Apache::Wyrd::Handler>).

=head2 SETUP

At the minimum, BASENAME::Wyrd needs to be defined, C<BASENAME::Handler>
needs to be defined and properly configured and able to properly invoke
an instance of C<BASENAME::DBL>.  [N.B: A sample minimal installation,
C<TESTCLIENT> can be found in the t/lib directory of this package].

When a BASENAME::FOO Wyrd is invoked, and no BASENAME::FOO perl object can
be found, the object Apache::Wyrd::FOO will be tried.  This allows the use
of any Apache::Wyrd::FOO objects derived from this module to be used in a
web page as BASENAME::FOO objects without explicitly subclassing them.  If
neither a BASENAME::FOO nor an Apache::Wyrd::FOO object exists, a generic
(do-nothing) Apache::Wyrd object will be used rather than an error occur.

As one would expect, one namespace can also instantiate another namespace's
objects as long as the other namespace can be found in the local perl
installation's @INC array.

=head2 SYNTAX IN HTML

Wyrds are embedded in HTML documents as if they were specialized tags. 
These tags are assigned attributes in a manner very similar to HTML
tags, in that they are formed like HTML tags with named attributes and
(optionally) with enclosed text, i.e.:

    <NAME ATTRIBUTENAME="ATTRIBUTE VALUE">ENCLOSED TEXT</NAME>

They follow the XHTML syntax somewhat in that they require a terminating
whitespace followed by a forward-slash (/) before the enclosing brace
when they are embedded as "stand-alone" tags, and require quotes around
all attributes. Therefore:

    <BASENAME::WyrdName name=imasample>

must either be written:

    <BASENAME::WyrdName name="imasample"></BASENAME::WyrdName>

or as:

    <BASENAME::WyrdName name="imasample" />

to be valid.  Invalid Wyrds are ignored and do not get processed, but
may cause errors in other Wyrds if malformed, so it often pays to "view
source" on your browser while debugging.

Unlike (X)HTML, however, Wyrds are named like perl modules with the double-colon
syntax (BASENAME::SUBNAME::SUBSUBNAME) and these names are B<case-sensitive>. 
Furthermore, either single or double quotes MUST be used around attributes, and
these quotes must match on either side of the enclosed attribute value.  Single
quotes may be used, however, to enclose double quotes and vice-versa unless the
entire attribute value is quoted.  When in doubt, escape quotes by preceding
them with a backslash (\).  B<HTML tags should not appear inside attributes.> 
See C<Apache::Wyrd::Template> and C<Apache::Wyrd::Attribute> for common ways
around this limitation.

Also unlike (X)HTML, one Wyrd of one type cannot be embedded in another of the
same type.  We believe this is a feature(TM).

=head2 LIFE CYCLE

The "normal" behavior of a Wyrd is simply to disappear, leaving its enclosed
text behind after interpreting all the Wyrds within that text.  It is through
"hook" methods that manipulation and output of perl-generated material is
accomplished.

Just as nested HTML elements produce different outcomes on a web page depending
on the order which they are nested in, Wyrds are processed relative to their
nesting.  The outermost Wyrd is created (with the C<new> method) first from a
requested page and processes its enclosed text, spawning the next enclosing tag
within it, and so on.  When the final nested Wyrd is reached, that Wyrd's
C<output> method is called and the resulting text replaces it on the page.  The
C<output> method of each superclosing tag is called in turn, repeating the
process.  Between C<new> and C<output> are several stages.  In these stages,
"hooks" for Wyrd specialization are called:

=over

=item 1.

C<new> calls C<_setup> which allows initialization of the Wyrd B<before> it
processes itself, spawning enclosed Wyrds.

=item 2.

C<_setup> returns the object, which waits for the C<output> call to be
performed on it by it's parent or by the Handler.

=item 3.

When the C<output> method is called, it processes itself, meaning that
it goes through the enclosed text (if any), finding embedded Wyrds. 
When such a Wyrd is found, it spawns a new object based on itself,
inheriting the same C<Apache::Wyrd::DBL>, the same C<Apache> request
object, the same loglevel (see attributes, below), and so on.  Prior to
spawning, the hook method C<_pre_spawn> is called to allow changes to
the new Wyrd before it is created.

=item 4.

C<output> then calls the two hooks, C<_format_output> which is meant to handle
changes to the enclosing text and C<_generate_output> which returns the actual
text to replace the Wyrd at that point in the HTML page.

=back

In most cases, there will not be any need to override non-hook methods.  For minor variations on Wyrd behavior, most
of the built-in Wyrds can be quickly extended by overriding the method with a method that calls the SUPER class:

  sub _setup {
    my $self = shift;
    
    ...do something here...
    
    return $self->SUPER::_setup();
  }

=head2 HTML ATTRIBUTES

Any legal attribute can generally be used.  Some, however, are important
and are be reserved.

=head3 RESERVED ATTRIBUTES

=over

=item loglevel

A value, defining the degree to which the Wyrd will spew debugging
information into STDERR (normally the Apache error log).  You may use
the keywords C<fatal>, C<error>, C<warn>, C<info>, C<debug>, and
C<verbose> or their corresponding numerical value (0-5).

=item dielevel

The degree of error which will trigger a server error.  Corresponds to
the loglevels and defaults to 'fatal'.

=item flags

A list of optional modifiers, separated by whitespace or commas, which
can be used to modify the behavior of the Wyrd.  Flags should contain no
whitespace.  One builtin flag exists: B<disable> keeps the Wyrd and all
enclosed data from being processed or generated at all.

=back

Additionally, any attributes corresponding to the reserved public
methods below will be discarded.

=head3 PRIVATE ATTRIBUTES

=over

Any attribute beginning with an underline is reserved  for future
development. Two of these are created at the time of generation which
are particularly important and deserve mention:

=item _data

At the time of spawning a new Wyrd, the enclosed text is stored in the
attribute _data.  This attribute is the data processed during the first
phase of the C<output> method, and is available to the hook methods.  If
one hook method changes this value, however, it is important that the
other hooks take this into account.  The default C<_generate_output>
simply returns this value, for example.

=item _flags

Also at the time of spawning, the flags attribute is translated into an
C<Apache::Wyrd::Services::Tree> object.  This object is used to keep
track of whether a flag is set or not, for example:

    $self->_flags->reverse;

will return the value "1" if the flags attribute contains the flag token
"reverse", and undef if it does not.  Flags can be (un)set by providing
the appropriate argument, for example:

    $self->_flags->reverse(0);

=back

=head2 PERL METHODS

Unlike most perl modules, modules derived from Apache::Wyrd attempt to
leave public methods open to the developer so that they can appear as
attributes in the corresponding HTML.  Hence, most important Wyrd
methods are private and are denoted as such by a leading underscore (_).
 Some methods are public, usually for obvious or traditional reasons.

=head3 PUBLIC METHODS

In most cases, a given HTML attribute will be available to the Wyrd directly by
accessing C<$self-E<gt>{attribute}>.  For convenience, these can be accessed via
a method call to the name of the attribute (I<example:> C<$value =
$self-E<gt>attributename>).  If the method call has an argument, it means to set
rather than retrieve the attribute (I<example:>
C<$self-E<gt>attributename($value)>).

B<Important Documentation Note:> Since the paragraph above describes the
default behavior for attributes, a perl method is not described in the
POD for these modules for any attributes UNLESS the method has been
explicitly defined, for example, to make the attribute read-only or be a
value other than scalar.

=cut

###############################################################################
#Public Methods
###############################################################################

#autoload will return the value of a variable unless provided with a value,
#in which case it will set it.  It will raise an exception if the variable has not
#been defined beforehand.
sub AUTOLOAD {
	no strict 'vars';
	my ($self, $newval) = @_;
	#Catch destruction events gracefully
	return undef if ($AUTOLOAD =~ /DESTROY$/);
	$AUTOLOAD =~ s/.*:://;
	#warn ("Auto-Loading $AUTOLOAD");
	if ($AUTOLOAD =~ /_format_(.+)/){
		#_format_HTMLTAGNAME allows an object to "entag" items in a simplified version
		#of what the CGI module does
		return $self->_generate_tag($1, $newval);
	}
	if (ref($self)) {
		if(defined($self->{$AUTOLOAD})){
			#if the method is called with no argument it's a GET value request
			return $self->{$AUTOLOAD} unless (scalar(@_) == 2);
			#if the method is called with an argument, it's a SET value request
			$self->{$AUTOLOAD} = $newval;
			#set always returns the value it is set to (no reason, may be useful for catching
			#errors down the road).
			return $newval;
		} elsif (ref($self) && &UNIVERSAL::can($self, '_raise_exception')) {
			$self->_error("Dead because of \$self->" . $AUTOLOAD . " being called.  You probably need to define this function/attribute or import it from somewhere else.");
			return $self->_raise_exception("Undefined variable was accessed in AUTOLOAD: $AUTOLOAD at " . join(':', caller()));
		}
	}
	die ("Dead because an undefined subroutine in a non-method call was executed: " . $AUTOLOAD . "() at " . join(':', caller()) . ".  You probably need to correct/define this subroutine or import it from somewhere else.  This error was reported by Wyrd.pm");
}

=pod

Note: methods are described I<(format: (returned value/s) C<methodname>
(arguments))>, where the first argument, representing the object itself, is
assumed, since the method is called using the standard notation
C<$object-E<gt>method>.

=over

=item (Apache::Wyrd ref) C<new> (Apache::Wyrd::DBL ref, hashref)

create and return a Wyrd object

=cut

sub new {
	my ($class, $dbl, $init) = @_;
	my $data = _init($dbl, $init);
	bless ($data, $class);
	$data->{'_class_name'} = $class;
	my $base_class = $dbl->base_class;
	$base_class ||= $init->{'_parent'}->{'_base_class'};
	unless ($base_class) {
		$class =~ s/([^:]+)::.+/$1/;
		$base_class ||= $class;
		$base_class ||= 'Apache::Wyrd';
	}
	$data->{'_base_class'} = $base_class;
	$data->_setup unless ($data->_flags->disable);
	return ($data);
}

=pod

=item (Apache::Wyrd ref) C<clone> (void)

make an identical copy of this Wyrd

=cut

sub clone {
	my ($self) = @_;
	my $data = {map {$_, $self->{$_}} keys %$self};
	bless $data, $self->_class_name;
	return $data;
}

=pod

=item (Apache::Wyrd::DBL ref) C<dbl> (void)

the current DBL

=cut

#defined to make this a read-only method
sub dbl {
	return $_dbl;
}


=pod

=item (scalar) C<class_name> (void)

The full name of this Wyrd.

=cut

#defined to make this a read-only method
sub class_name {
	my $self = shift;
	return $self->{'_class_name'};
}

=pod

=item (scalar) C<base_class> (void)

The BASENAME of the currently executing installation of Apache::Wyrd.

=cut

#defined to make this a read-only method
sub base_class {
	my $self = shift;
	return $self->{'_base_class'};
}

=pod

=item (scalar) C<output> (void)

produce the text this Wyrd is meant to produce.

=cut

sub output {
	my $self = shift;
	$self->_process_self unless ($self->_flags->disable);
	$self->_format_output unless ($self->_flags->disable);
	return $self->_generate_output unless ($self->_flags->disable);
	my $redirect = $self->{'_redirect_to_file'};
	if ($redirect) {
		warn "redirecting to $redirect";
		$self->_flags->disable(0);
		$self->{'_redirect_to_file'} = undef;
		my $data = slurp_file($redirect);
		$self->{'_data'} = $$data;
		$self->_setup;
		return $self->output;
	}
}

=pod

=item (void) C<abort> (Apache::Constant response code)

End all processing and return a response code with no output.  Defaults to
Apache::Constants::SERVER_ERROR.

=cut

sub abort {
	my ($self, $response) = @_;
	$self->_flags->disable(1);
	return $self->{'_parent'}->abort($response) if (UNIVERSAL::can($self->{'_parent'}, 'abort'));
	$response ||= SERVER_ERROR;
	$self->dbl->set_response($response);
	return;
}

=pod

=item (void) C<abort_redirect> (scalar location)

End the processing of the page this wyrd is on and redirect to another.  The
redirection is an internal one, so the location argument must be another
page on the same site, with an absolute pathname.

=cut

sub abort_redirect {
#	my ($self, $redirection) = @_;
#	$self->_flags->disable(1);
#	return $self->{'_parent'}->abort_redirect($redirection) if (UNIVERSAL::can($self->{'_parent'}, 'abort_redirect'));
#	my $response = 'internal_redirect:' . $self->dbl->req->document_root . $redirection;
#	$self->dbl->set_response($response);
#	$self->dbl->req->internal_redirect_handler($redirection);
#	return;
	my ($self, $redirection) = @_;
	$self->_flags->disable(1);
	return $self->{'_parent'}->abort_redirect($redirection) if (UNIVERSAL::can($self->{'_parent'}, 'abort_redirect'));
	$self->dbl->{'self_path'} = $redirection;
	$self->dbl->{'file_path'} = $self->dbl->req->document_root . $redirection;
	$self->{'_redirect_to_file'} = $self->dbl->{'file_path'};
	my @stats = stat $self->dbl->{'file_path'};
	$self->dbl->{'mtime'} = $stats[9];
	$self->dbl->{'size'} = $stats[7];
	return;
}

=pod

=head3 HOOK METHODS

=item (void) C<_setup> (void)

Set-up the Wyrd before processing enclosed "child" Wyrds.  Useful in particular
for setting up data structures the child Wyrds will refer to.

=cut

###############################################################################
#Private Methods
###############################################################################

sub _setup {
	return;
}


=pod

=item (scalar) C<_format_output> (void)

Format/change any enclosed text.  The main hook for Wyrd processing.  Generally
should be confined to preparing for and performing the modification of and the
_data attribute.

=cut

#Dummy - does no formatting
sub _format_output {
	return;
}


=pod

=item (scalar) C<_generate_output> (void)

Return the resulting text from the Wyrd, finishing all processing.  Generally
used when the output should return something other than the _data attribute.

=cut

#Dummy - does no generating, simply returns enclosed text
sub _generate_output {
	my ($self) = @_;
	return $self->{'_data'};
}

=item (scalar) C<_shutdown> (void)

Do any last-minute housekeeping, such as closing database connections,
filehandles.

=cut

#Dummy - does no cleanup
sub _shutdown {
	return;
}

=pod

=item (scalar, hashref) C<_pre_spawn> (scalar classname, hashref initialization)

Pre-spawn allows the classname or initialization hash to be modified before a
child Wyrd is generated.

=cut

sub _pre_spawn {
	#hook for child object init manipulations
	my ($self, $class, $init_hash) = @_;
	return ($class, $init_hash);
}

=pod

=back

=item (scalar) C<_generate_xxx> (scalar)

If the method _generate_xxx is called where xxx is an HTML tagname and no such
method is defined, the Wyrd will attempt to return the value given enclosed by
tags of the type xxx:

	<xxx>given value</xxx>

I<This behavior has proven of limited value and is depreciated.>

=cut

sub _generate_tag {
#used to auto-generate tags when _format_TAG is undefined
	my ($self, $tag, $value) = @_;
	if ($tag eq 'output') {
		#$self->_format_output was called on an item that failed to compile.
		$self->_raise_exception("Compilation error in " . $self->_class_name);
	}
	return "<$tag>$value</$tag>";
}

=pod

=item (void) C<_fatal/_error/_warn/_info/_debug/_verbose> (scalar)

These methods all log an error at the given loglevel.  See
C<Apache::Wyrd::Handler> for a discussion of loglevels and their affect on
Apache.

=head3 OTHER RESERVED METHODS

The methods _init, _process_self, _spawn, _process_flags, and
_return_object are also reserved and provide the "natural" behavior for
Apache::Wyrd objects.  No documentation of them is provided, as they are
not meant to be modified.  Please contact the author if you feel some
documentation is needed.

=head1 BUGS/CAVEATS

=head2 FREE SOFTWARE

Apache::Wyrd is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or any later
version.

Apache::Wyrd is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

=head2 (GENERALLY) UNIX-Only

This software has only tested under Linux and Darwin, but should work
for any *nix-style system.  This software is not intended for use on
windows or other delicate glassware.

=head2 Cross Scripting

This software is meant to run on mod_perl, which, unlike PHP for example, is
not a separate language.  It is a direct interface to Apache internals. 
Although Apache::Wyrd supports multiple namespaces and consequently,
multiple sites on different virtual server definitions of an Apache
installation, it has not, and the author believes cannot, be designed to
prevent cross-scripting attacks.  Consequently, Apache::Wyrd is not
appropriate for a shared hosting environment where different site
contributors must be protected from each other.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

A few modules provide some of the basic services of the Library.  They
often have, and list in their SEE ALSO sections, the modules which
support them.

=over

=item Apache::Wyrd::Handler, Apache::Wyrd::DBL

For information on setting up the Apache::Wyrd abstract classes

=item Apache::Wyrd::Form

For information on smart form processing

=item Apache::Wyrd::Services::Auth

For information on the built-in authorization system

=item Apache::Wyrd::Services::Index

For information on the reverse-key indexing engine

=item Apache::Wyrd::Services::Debug

For information on the debugging sub-system

=item Apache::Wyrd::Services::SAK

The "swiss army knife" of useful methods/subroutines which are collected in one
library to improve standardization of behaviors.

=item Apache::Wyrd::Site

A collection of inter-related Wyrds which can be used to quickly implement
an integrated site with self-maintaining navigation, search engine, subject
cross-references, publication management, and dynamic state-tracked
elements.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

You should have received a copy of the GNU General Public License along
with Apache::Wyrd (see LICENSE); if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=cut

sub _init{
	my ($dbl, $init) = @_;
	#NOTE: Because DBL is tested here for DBL compatibility, it does not need to be tested again anywhere else
	#in a Wyrd.  If it is defined, it is a DBL.
	my $not_hash = (ref($init) ne 'HASH');
	if (ref($dbl) and UNIVERSAL::can($dbl, 'verify_dbl_compatibility')) {
		$_dbl = $dbl;
		$dbl->log_bug("ERROR: Invalid data (non-hashref) apparently given to object as Initial Value -- Ignoring")
			if ($not_hash);
	}
	$init = {} if ($not_hash);
	foreach my $level (values %_loglevel) {
		$_error_handler{$level} = $_disabled_error_handler;
	}
	#must test for existence, since a loglevel can be 0 and, therefore, false
	$init->{'loglevel'} = ($dbl->loglevel || 1) unless (exists($init->{'loglevel'}));
	$init->{'loglevel'} = ($_loglevel{$init->{'loglevel'}} || $init->{'loglevel'} || 0);
	for (my $level=0; $init->{'loglevel'} >= $level; $level++) {
		$_error_handler{$level} = $_enabled_error_handler;
	}
	#set the dielevel (level lower than which, execution will terminate.  The _raise_exception() method will
	#always terminate.
	$init->{'dielevel'} = ($_loglevel{$init->{'dielevel'}} || $init->{'dielevel'} || 0);
	for (my $level=0; $init->{'dielevel'} >= $level; $level++) {
		$_error_handler{$level} = $_fatal_error_handler;
	}
	$init->{'_flags'}=Apache::Wyrd::Services::Tree->new unless ($init->{'_flags'});
	return $init;
}

#Called by output, the start of the recursive chain which interprets embedded
#Apache::Wyrd, calling their output methods in returning
sub _process_self {
	my ($self) = @_;
	my $depth = ($self->{'_depth'} || 10);
	my ($test, $temp) = (1, undef);
	my $class = $self->base_class;
	#warn "base class is $class";
	do {
		#Replace each tag with its spawned contents
		#$1 = whole Object
		#$2 = class
		#$4/$5 = params
		#$6 = Enclosed Data
		$temp = $self->{'_data'};
		$test = ($temp =~
				s[
					(						#$1
						<					#tag beginning
							$class
							::
							(				#$2 v
								[:\w]+		#class
							)
						(					#$3
							(				#$4 v
								[^>]*		#params and
							)
							\s/>			#endpoint
						|					#or
							(				#5 v
								[^>]*		#params and
							)
							>				#closure plus...
								(			#$6 v
									.*?		#data
								)
							</
								$class
								::
								\2			#matched class
							>
						)
					)
				]
				[
					$self->_invoke_html_wyrd($2, ($5 || $4), $6, $1)#(real) object id, parameters, enclosed data, complete expr.
				]gexis);
		$test = 0 if ($self->_flags->disable);
		$self->{'_depth_counter'}++;
		$self->{'_data'} = $temp;
		#warn "after iteration " . $self->_depth_counter . " test is " . $test . " values are ID='$2' params='$3' data='$4'...";
	} while ($test and ($self->{'_depth_counter'} < $depth));
	return;
}

#_spawn produces the child object, returns an error message if it can't be generated.
sub _spawn {
	my ($self, $class, $init) = @_;

	$init->{'_parent'} = $self;

	#Convert the flags attribute to a flags Tree object
	$init->{'_flags'} = $self->_process_flags($init->{'flags'});
	#Why delete it?  It may be useful.
	#delete $init->{'flags'};

	#allow user-defined filters on all Wyrds
	($class, $init) = $self->_pre_spawn($class, $init);

	#loglevel/dielevel will be inherited if it exists, but not if the object explicitly has it defined
	$init->{'loglevel'} = $self->{'loglevel'} unless(exists($init->{'loglevel'}));
	$init->{'dielevel'} = $self->{'dielevel'} unless(exists($init->{'dielevel'}));

	#Temporarily "hide" the global so that loglevel changes in children do not
	#propagate back up into their parents.
	my %_error_handler_temp = %_error_handler;

	my ($child) = ();
	#first attempt to find a perl class which is in the base_class hierarchy
	eval('require ' . $self->base_class . '::' . $class);
	eval('$child = ' . $self->base_class . '::' . $class . '->new($self->dbl, $init)');
	if ($@) {
		if ($@ =~ /^Can't locate object method "new"/) {
			$self->_info("No direct implementation of $class in " . $self->base_class . " Looking in core class...");
		} else {
			$self->_raise_exception("Compilation Error in " . $self->base_class . "::" . $class . ":" . $@);
		}
	} else {
		$self->_info("Using $class from " . $self->base_class);
	}
	#if that doesn't work, go into the Apache::Wyrd class
	unless (ref($child)) {
		eval('require Apache::Wyrd::' . $class);
		eval('$child = Apache::Wyrd::' . $class . '->new($self->dbl, $init)');
		if ($@) {
			if ($@ =~ /^Can't locate object method "new"/) {
				$self->_error("No direct or indirect implementation of $class...");
			} else {
				$self->_raise_exception("Compilation Error while spawning a new Wyrd: " . $@);
			}
		}
		unless (ref($child)) {
			$self->_raise_exception("Giving up!  Don't know how to make a $child") if ($self->dbl->strict);
			$child = Apache::Wyrd->new($self->dbl, $init);
			$child->{'_attempted'} = $self->base_class . '::' . $class;
		}
	}

	#Restore the loglevel of this parent so that it's child's changes to the
	#global variable do not affect it.
	%_error_handler = %_error_handler_temp;

	return (undef, $self->base_class . "$class could not be generated.") unless ref($child);
	return $child, undef;
}

sub _invoke_html_wyrd {
	my ($self, $class, $params, $data, $original) = @_;
	my $base_class = $self->base_class;
	$self->_debug("$original is the original\n");
	$self->_debug("$base_class is the base class\n");
	$self->_debug("$class is the class\n");
	$self->_debug("$params is the params\n");
	$self->_debug("$data is the data\n");
	my $match = 0;
	my (%init, $init_ref, $unescape) = ();
	$self->_error("Attempted recursion of $class") if ($data =~ /<$base_class\:\:$class[\s>]/);
	#drop the nest identifier
	$class =~ s/([^:]):([^:]+)$/$1/ && $self->_info("dropped the nest identifier $2");
	#encode the escaped-out " and '
	$params =~ s/\\'/<!apostrophe!>/g;
	$params =~ s/\\"/<!quote!>/g;
	#escape-out special characters when they are the only attribute
	$params =~ s/\$/<!dollar!>/g;
	$params =~ s/\@/<!at!>/g;
	$params =~ s/\%/<!percent!>/g;
	$params =~ s/\&/<!ampersand!>/g;
	#nullify the blank attributes
	$params =~ s/""/"<!null!>"/g;
	$params =~ s/''/'<!null!>'/g;
	#zerofy the numerical zero attributes
	$params =~ s/"0"/"<!zero!>"/g;
	$params =~ s/'0'/'<!zero!>'/g;
	#Process Params:
	do {
		$match = 0;
		$match = ($params =~ m/
			\G					#last search match
			[^\w-]*				#any amount of non-word space
			(?:					#non-capturing cluster 1
				([^=]+)			#non-equals
				\s*=\s*			#an equals with or without whitespace around it
					(?:			#non-capturing cluster 2
					"([^"]+)"	#non-double-quotes surrounded by double-quotes
					|			#or
					'([^']+)'	#non-single-quotes surrounded by single quotes
					)			#end of non-capturing cluster 2
				|				#or
					([\w-]+)	#plain word
			)					#end of non-matching cluster 1
			\W*					#and any amount of non-word space
			/xmsg);
		if ($match) {
			#warn "1: $1 2: $2 3: $3 4: $4";
			if ($1) {
				$init{lc($1)} = ($2 || $3);
				$self->_debug(lc($1) . " is '" . $init{$1} . "'\n");
			} else {
				$init{lc($4)} = 1;
				$self->_debug(lc($4) . " is '1'\n");
			}
		}
	} while $match;
	foreach my $i (keys(%init)) {
		$init{$i} =~ s/<!apostrophe!>/'/g;
		$init{$i} =~ s/<!quote!>/"/g;
		$init{$i} =~ s/<!null!>//g;
		$init{$i} =~ s/<!zero!>/0/g;
		$init{$i} =~ s/<!dollar!>/\$/g;
		$init{$i} =~ s/<!at!>/\@/g;
		$init{$i} =~ s/<!percent!>/\%/g;
		$init{$i} =~ s/<!ampersand!>/\&/g;
	}

	#store the HTML of the wyrd
	$init{'_as_html'} = $original;
	$init{'_data'} = $data || '';

	#spawn the new object
	my ($wyrd, $err) = $self->_spawn($class, \%init);

	#Either call output on the object or give up
	if ($err) {
		$self->_error($err);
		return $original;
	} else {
		$self->_debug("newly spawned object reference is " . ref($wyrd) . "\n");
		my $output = $wyrd->output;
		$wyrd->_shutdown;
		return $output;
	}
}

sub _invoke_wyrd {
	my ($self, $class, $init) = @_;

	my ($wyrd, $err) = $self->_spawn($class, $init);

	if ($err) {
		$self->_error($err);
		return join(':', 'Error when invoked from Wyrd at', caller);
	} else {
		$self->_debug("newly spawned object reference is " . ref($wyrd) . "\n");
		my $output = $wyrd->output;
		return $output;
	}
}

#process_flags makes a lightweight Tree object which can be accessed
#using $wo_ref->_flags->n where n is the flag
sub _process_flags {
	my ($self, $flags) = @_;
	my (%init) = ();
	my @flags = token_parse($flags);
	foreach my $i (@flags) {
		$init{$i} = 1;
	}
	$flags = Apache::Wyrd::Services::Tree->new(\%init);
	return $flags;
}

1;
