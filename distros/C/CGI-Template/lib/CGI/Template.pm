package CGI::Template;

use 5.012004;
use strict;
use warnings;
use Carp;

require Exporter;


use vars qw(
	$VERSION $FORM_CHECK @ISA @EXPORT @EXPORT_OK $DOCTYPE $STRICT
	$TRANSITIONAL $FRAMESET $HTML5
);



our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Template ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';


# These variables just define standard HTML DOCTYPEs. We'll use them throughout.
$STRICT       = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n\n};
$TRANSITIONAL = qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"\n"http://www.w3.org/TR/html4/loose.dtd">\n\n};
$FRAMESET     = qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"\n"http://www.w3.org/TR/html4/frameset.dtd">\n\n};
$HTML5	      = qq{<!DOCTYPE html>};

# Use HTML5 by default.
$DOCTYPE = $HTML5;




#
#
#
sub new {
	my $class = shift;

	my %passed_hash = @_;

	my $doctype        = $passed_hash{doctype};
	my $request_method = $passed_hash{request};
	my $template_dir   = $passed_hash{templates};

	$template_dir = "templates" unless $template_dir;

	my $crm = $ENV{'REQUEST_METHOD'};

	if( $request_method ){
		if( $request_method =~ /^get$/i ){
			unless( $crm =~ /^get$/i ){
				&error("Incorrect request method");
			}

		} elsif( $request_method =~ /^post$/i ){
			unless( $crm =~ /^post$/i ){
				&error("Incorrect request method");
			}

		} else {
			croak "CGI::Template : Invalid request argument passed to new(): $request_method";
		}
	}
		

	$doctype = "" unless $doctype;

	if( $doctype =~ /^transitional$/i || $doctype =~ /^loose$/i ){
		$DOCTYPE = $TRANSITIONAL;

	} elsif( $doctype =~ /^frameset$/i ){
		$DOCTYPE = $FRAMESET;

	} elsif( $doctype =~ /^strict$/i ){
		$DOCTYPE = $STRICT;

	} elsif( $doctype =~ /^html5$/i ){
		$DOCTYPE = $HTML5;

	} elsif( $doctype =~ /^none$/i ){
		$DOCTYPE = "";

	} elsif( $doctype =~ /^$/i ){
		$DOCTYPE = $HTML5;

	} else {
		croak "CGI::Template : Invalid doctype argument passed to new(): $doctype";
	}

	my $path = $ENV{PATH_INFO};
	if( $path ){
		$path =~ s/^\/+//;
		$path =~ s/\/+$//;
	}

	my $self = {
		path      => $path, 
		templates => $template_dir,
	};
	my $template = &_check_template( $template_dir );
	$self->{template} = $template if( $template );

	bless($self, $class);
	return $self;

}




sub header {
	my $self = shift;
	my %passed_hash = @_;

	my $header = "Content-type: text/html\n";

	my $redirect = 0;
	foreach my $i (keys %passed_hash){
		if( $i =~ /-cookie/ ){
			$header .= "Set-Cookie: " . $passed_hash{$i} . "\n";

		} elsif( $i =~ /-content-type/ ) {
			$header =~ s/text\/html/$passed_hash{$i}/;		

		} elsif( $i =~ /-redirect/ ) {
			$header =~ s/Content-type: .*?\n/Status: 302 Found\nLocation: $passed_hash{$i}\n/m;
			$redirect++;

		} else {
			$header .= "$i: " . $passed_hash{$i} . "\n";
		}
	}

	$header .= "\n";
	$header .= $DOCTYPE unless $redirect;

	return $header;
}

sub path {
	my $self = shift;
	return $self->{path};
}


sub content {
	my $self = shift;
	my %hash = @_;

	croak "CGI::Template : No template set!" unless defined $self->{template};

	my $data = $self->{template};

	foreach my $i (keys %hash){
		$data =~ s/#!$i!#/$hash{$i}/g;
	}

	return $data;
}

sub replace_template {
	my $self = shift;
	my $template = shift;
	$self->{template} = $template;
}

sub error {
	my $self = shift;
	my $message = shift;

	my $template_dir = $self->{templates};

	my $error_template = '';
	if( -e "$template_dir/error.html" ){
		my $fail = 0;
		open INFILE, "$template_dir/error.html" or $fail = 1;
		if( $fail ) { croak "CGI::Template : Couldn't open error template: $template_dir/error.html"; return 0; }
		{
			local $/;
			$error_template = <INFILE>;
		}
		close INFILE;
	}

	$error_template = qq{
		<html>
			<head><title>Error</title></head>
			<body>
				<h1>Oops!</h1>
				<p>#!MESSAGE!#</p>
				<p></p>
				<hr>
			</body>
		</html>
	} unless( $error_template );

	$error_template =~ s/#!MESSAGE!#/$message/g;
	print &header;
	print $error_template;
	exit;

}


sub get_template {
	my $self = shift;
	my $file = shift;
	my %passed_hash = @_;
	my $fail = 0;

	my $template_dir = $self->{templates};

	my @templates = (
		"$template_dir/$file.html",
		"$template_dir/$file",
	);

	my $tn = '';
	foreach my $i (@templates){
		if( -e $i ){
			$tn = $i;
			last;
		}
	}

	unless($tn){
		carp "CGI::Template : Couldn't find valid template: ".join(", ", @templates)." called by $tn"; 
		return (0) unless $tn;
	}


	open INFILE, $tn or $fail = 1;
	if( $fail ) { carp "CGI::Template : Couldn't open template: $file, called by $tn"; return 0; }

	my $data = '';
	{
		local $/;
		$data = <INFILE>;
	}
	close INFILE;

	foreach my $i (keys %passed_hash){
		$i = uc($i);
		$data =~ s/#!$i!#/$passed_hash{$i}/g;
	}

	return $data;


}

sub template {
	my $self = shift;
	return $self->{template};
}



###########################################################
# PRIVATE METHODS
###########################################################

sub _check_template {
	my $template_dir = shift;

	my $name = $0;
	
	$name =~ s/\/$//;
	$name =~ s/^.*\///;
	$name =~ s/\.cgi$//;
	$name =~ s/\.pl$//;

	my @templates = (
		"$template_dir/$name.html",
		"$template_dir/$name",
		"$template_dir/default.html"
	);


	my $head_template = '';
	if( -e "$template_dir/head.html" ){
		my $fail = 0;
		open INFILE, "$template_dir/head.html" or $fail = 1;
		if( $fail ) { croak "CGI::Template : Couldn't open general template: $template_dir/head.html, called by $name"; return 0; }
		{
			local $/;
			$head_template = <INFILE>;
		}
		close INFILE;
	}

	my $tn = '';
	foreach my $i (@templates){
		if( -e $i ){
			$tn = $i;
			last;
		}
	}

	return (0) unless $tn;

	my $fail = 0;
	open INFILE, $tn or $fail = 1;

	if( $fail ) { carp "CGI::Template : Couldn't open template: $tn, called by $name"; return 0; }

	my $data = '';
	{
		local $/;
		$data = <INFILE>;
	}
	close INFILE;

	my $template = "";

	if( $head_template ){
		$template = $head_template;
		$template =~ s/#!DATA!#/$data/;
	} else {
		$template = $data;
	}

	return $template;

}







1;
__END__

=head1 NAME

CGI::Template - An easy to use and intuitive template system for Perl web application development.

=head1 SYNOPSIS

  use CGI::Template;
  my $t = new CGI::Template;

  ...

  print $t->header();
  print $t->content(
     PLACEHOLDER  => $value,
     PLACEHOLDER2 => $value2,
     ...
  );


=head1 DESCRIPTION

CGI::Template simplifies and speeds up the development of web applications by providing 
an easy to use system that inherently keeps web design and code separate.

Each time a script that uses CGI::Template is executed, CGI::Template will automatically grab the appropriate template, and then replace any placeholders with their new values and finally output the finished page.

Furthermore, CGI::Template provides an easy error-handling system with the C<error()> method.

=head2 EXPORT

None by default.

=head1 SETUP

=head2 Directory Structure

The easiest way to get started with CGI::Template is to create a new directory within your cgi-bin directory called C<templates>.  

=head2 Template Files

Create a new HTML file within the templates directory called C<default.html> containing your site design.  Any text within the template that will need to be filled in by CGI scripts should be replaced with placeholders.

Create a second HTML file within the templates directory called C<error.html> containing the template for your application's error messages.  This HTML file must contain a placeholder titled MESSAGE.

=head2 Placeholders

A placeholder is designated within a template by beginning with the characters C<#!> and ending with the characters C<!#>.  For example:

  #!PLACEHOLDER!#

It is convention to use all caps for placeholder names.  No spaces may be used within placeholder names.  Additionally, a placeholder may be used multiple times within a template.

=head2 CGI Scripts

Any CGI script using CGI::Template will now output the content of C<default.html>.  If a script needs a different template, then simply create a new HTML file within the C<templates> directory with the same name as the CGI script.  For instance, if you are using the script C<cgi-bin/search> then its template would be C<cgi-bin/templates/search.html>. 

Note that CGI::Template disregards extensions of CGI scripts.  Therefore, C<search.cgi> or C<search.pl> would also use the C<templates/search.html> template.


=head1 METHODS

=head2 new()

The constructor method for CGI::Template.  Options are passed in key/value pairs.
The following key/value pairs are recognized: 

=over 4

=item doctype
  
Specifies the DOCTYPE to use for the document.  Possible values are: none, html5, strict, frameset, or transitional.  If no doctype is specified, the html5 doctype is used.

=item templates

Sets the path to the templates directory.  By default this is a directory called C<templates> under the directory from which the script is being executed (typically C<cgi-bin>).

=item request

Specifies the request method to be used.  Possible values are C<get> or C<post>.  If set, CGI::Template will require that all requests to the script be of the type specified.  Any other types of requests will result in a call to error().

=back 

=head2 $t->header()

Returns an HTTP Content-type header.  By default, the mimetype returned is C<text/html> but this can be specified.  C<header()> accepts options in the form of key/value pairs:

=over 4

=item -content-type

Sets the MIME type value in the header.  Some examples:

  print $t->header( -content-type => "image/png" );
  print $t->header( -content-type => "text/plain" );

=item -redirect

Causes header() to return a HTTP C<Location> header that will redirect the user to a new page.  Example:

  print $t->header( -redirect => "/cgi-bin/new_location" );

=item -cookie

Sets a cookie.  Example:

  print $t->header( -cookie => $cookie );

=item [any other key]

Any other key passed will result in the addition of the key and value to the header.  Example:

  print $t->header( Expires => $date );

will result in:

  Content-type: text/html
  Expires: [date specifed]

=back 

=head2 $t->content()

Returns the final HTML output.  Accepts placehoders and their replacements as key/value pairs.  These replacements will be made throughout the current template.  Example:

If CGI::Template is called from a script called "welcome":

  #!/usr/bin/perl -w
  use strict;

  use CGI::Template;
  my $t = new CGI::Template;

  my $title = "Welcome";
  my $menu  = "Menu";
  my $text  = "Hello world.";

  print $t->header();
  print $t->content(
     TITLE => $title,
     MENU  => $menu,
     TEXT  => $text,
  );

And the contents of cgi-bin/templates/welcome.html are as follows:

  <html>
    <head>
       <title>#!TITLE!#</title>
    </head> 
    <body>
       <div id="menu">#!MENU!#</div>
       <div id="content">#!TEXT!#</div>
    </body>
  </html>

Then the resulting output of the "welcome" script will be:

  Content-type: text/html

  <!DOCTYPE html>
  <html>
    <head>
       <title>Welcome</title>
    </head> 
    <body>
       <div id="menu">Menu</div>
       <div id="content">Hello world.</div>
    </body>
  </html>


=head2 $t->get_template()

Requres a string argument. Returns a template retrieved from the file named $string within the CGI::Template directory.  This is useful to reduce the amount of time spent editing template content that is used on many pages throughout your web application.  Example:

  my $menu = $t->get_template( "menu" );
  ...
  print $t->content(
      ...
      MENU => $menu,
      ...
  );

=head2 $t->replace_template()

Requires a string argument. Replaces the current template with the provided string argument.  This is useful if under some conditions your script needs to output a different template than usual.  Often used with get_template().  Example:

  if( $other ){
     my $new_template = $t->get_template( "other" );
     $t->replace_template( $new_template );

     print $t->header();
     print $t->content(
        PLACEHOLDER => $value,
        ...
     );
     exit;

  }

=head2 $t->path()

Returns the remaining content after the script name in the URL. (i.e., the content of the environment variable C<PATH_INFO>).


=head2 $t->error()

Requres a string argument.  Prints an HTTP header, an error message, and calls C<exit()>.  Accepts a string argument which then replaces the placehoder MESSAGE in the error template: error.html  Example:

  $t->error( "Zip code must be numeric." ) if( $zipcode !~ /^\d+$/ );



=head1 SEE ALSO

There are many other HTML template systems available for Perl, and each one does things a little (or a lot) differently.  If you'd like to freely mix Perl within your HTML you should check out L<HTML::Embperl>.  If you'd like to be able to process loops and such within HTML code, check out L<HTML::Template>.  

=head1 AUTHOR

David J. Venable, E<lt>davidjvenable@gmail.comE<gt>, @davevenable

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by David J. Venable

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
