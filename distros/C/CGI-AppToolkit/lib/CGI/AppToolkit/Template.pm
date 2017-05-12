package CGI::AppToolkit::Template;

# Copyright 2002 Robert Giseburt. All rights reserved.
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# Email: rob@heavyhosting.net

$CGI::AppToolkit::Template::VERSION = '0.05';

# NOTE: POD documentation is located at the bottom of this file.

require 5.004;
use strict;
use Carp;

use Exporter;
use CGI::AppToolkit::Template::TemplateC;
use vars qw(@ISA @EXPORT_OK %CACHE %KEYMAP %_OBJ @PATH);
@ISA = qw(Exporter);
@EXPORT_OK = qw(template);            # symbols to export by default

%CACHE = ();
%KEYMAP = ('load' => 'file', 'text' => 'set', 'string' => 'set');

@PATH = qw/. templates/;

### Subroutines ###

sub template {
	if ($_[0] eq __PACKAGE__) {
		shift;
	} 
	if (@_ == 1) {
		if (ref $_[0] || $_[0] =~ /(\x0D|\x0A)/) {
			unshift @_, '-set';
		} else {
			unshift @_, '-load';		
		}
	}
	return __PACKAGE__->new(@_, -cache => 1);
}

#-------------------------


sub new {
	my $self = bless {}, shift;
	$self->init(@_);
	$self
}

#-------------------------


sub init {
	my $self = shift;
	my %in = ref $_[0] ? %{ shift() } : @_;
	my %hash = ();
	foreach my $inkey (keys %in) {
		my $key = lc $inkey;
		$key =~ s/^-//;
		$key = $KEYMAP{$key} || $key;
		$hash{$key} ||= $in{$inkey};
	}
	undef %in;
	
	$self->{'cache'} = $hash{'cache'};
	$self->{'fatal'} = $hash{'fatal'};
		
	$self->load($hash{'file'}) if $hash{'file'};
	$self->set($hash{'set'}) if $hash{'set'};
}

#-------------------------


sub load {
	my $self = shift;
	my $template_file_orig = shift;
	
	if (!$self->{'cache'}
	       ||
	   (!$CACHE{$template_file_orig})
	       ||
	   ((stat(_))[9] != $CACHE{$template_file_orig}[0])) {
	   
		my $template_file = '';
		if ($template_file_orig !~ m{/}) {
			foreach my $dir (@PATH) {
				if (-d $dir && (-e "$dir/$template_file_orig" || -e "$dir/$template_file_orig.tmpl")) {
					$template_file = -e "$dir/$template_file_orig" ? "$dir/$template_file_orig" : "$dir/$template_file_orig.tmpl";
					last;
				}
			}
			
			carp "File '$template_file_orig' doesn't exist in template path ('",
				join("', '", @PATH), "')!" unless -e $template_file;

		} else {
			$template_file = $template_file_orig;
			carp "File '$template_file' doesn't exist!" unless -e $template_file;
		}		
		
		open FORM, $template_file or die "Unable to open $template_file! $!\n";	
			local $/ = undef;
			my $template = _cleanup(<FORM>);
		close FORM;
		
		$self->{'template'} = CGI::AppToolkit::Template::TemplateC->new($template);
		$self->_load_vars unless $self->{'vars-loaded'};
		
		# MAKE PATH FULL HERE
		
		$CACHE{$template_file} = [
			(stat(_))[9],
			$self->{'template'},
			$self->{'vars'}
		] if $self->{'cache'};
		
	} else {
	
		($self->{'template'}, $self->{'vars'}) = @{$CACHE{$template_file_orig}}[1, 2];

	}
}

#-------------------------


sub set {
	my $self = shift;
	my @lines = ref $_[0] ? @{$_[0]} : @_;
	my $template = _cleanup(join("", @lines));

	$self->{'template'} = CGI::AppToolkit::Template::TemplateC->new($template);
	$self->_load_vars unless $self->{'vars-loaded'};
	
	$self
}

#-------------------------


sub _cleanup {
	my $t = shift;
	
#	my $r = "\x0D"; # \r
#	my $n = "\x0A"; # \n
#	# Mac = \r
#	# Unix = \n
#	# DOS = \r\n
#	$t =~ s/($r|$n|$r$n)/\n/go; # Convert line-endings to current "\n" - Mac or UNIX

	# change {? ... ?} to <? ... ?>
	#$t =~ s/{\?((?:[^{}]+?|{\?.*?\?}|{[^?])+)\?}/<?$1?>/sg;
	
	# change {?@token?} to {?@token --?} line {?-- @token?}
	$t =~ s/^(.*?)[{<]\?\s*(\@[-_a-zA-Z0-9]+)\s*\?[}>](.*(?:\n|\z))/<?$2 --?>$1$3<?-- $2?>/mg;

	# change <repeattoken name="token"/> to <repeattoken name="token"> line </repeattoken>
	$t =~ s/^(.*?)<\s*repeattoken\s*(?:name\s*=\s*(['"])([-_a-zA-Z0-9]+)\2?|name\s*=\s*([-_a-zA-Z0-9]+)|([-_a-zA-Z0-9]+))\s*([^>]*)\/>(.*(?:\n|\z))/<repeattoken name="$3$4$5"$6>$1$7<\/repeattoken>/mg;
	
	$t
}

#-------------------------


sub check_cache {
	my($self) = shift;
	if (($self->{'file-name'}) && ((stat($self->{'file-name'}))[9] != $self->{'file-date'})) {
		$self->load($self->{'file-name'});
		return 1;
	}
	0
}

#-------------------------


sub make {
	my $self = shift;
	my $values = ref $_[0] ? shift : {@_};
	
	my $template = $self->{'template'};
	
	my $output = $template->value($self, [$values]);
	
	my $error = $template->get_error();
	if ($error) {
		die '$error' if $self->{'fatal'};
		return undef;
	}
	
	$output
}

*output = \&make;
*print = \&make;

#-------------------------


sub get_error {
	my $self = shift;
	my $template = $self->{'template'};

	$template->get_error()
}

#-------------------------


sub var {
	my $self = shift;
	return $self->vars(@_);
}

#-------------------------


sub vars {
	my $self = shift;
	my $val = shift;
	
	if ($val) {
		return $self->{'vars'}{$val};
	} else {
		return $self->{'vars'};
	}
}

#-------------------------


sub set_path {
	my $self = shift;

	if (@_) {
		@PATH = ref $_[0] ? @{$_[0]} : @_;
	}
}

#-------------------------


sub _load_vars {
	my $self = shift;
	$self->{'vars'} = $self->{'template'}->get_vars();
}

#-------------------------


sub filter {
	my $self = shift;
	my ($filter, $args, $text) = @_;
	
	my $obj = obj($filter);
	$obj->filter($args, $text)
}

#-------------------------------------#

# find a filter object kind
sub obj {
	my $orignal_kind = shift;
	my $kind = $orignal_kind;
	
#	my $kind = lc(shift);	
#	$kind =~ s/\s+/_/g;
#	$kind =~ s/(?:^|_)([a-z])/uc($1)/ge;
	
	my $prefix = __PACKAGE__ . "::Filter";
	my $prefix_path = $prefix;
	$prefix_path = s{::}{/}g;
	my $obj;
	
	if (exists $_OBJ{$kind}) {
		return $_OBJ{$kind};
	} else {
		#no strict 'refs';
    	eval "package $prefix\::_firesafe; require $prefix\::$kind;";
		if ($@) {
			my $err = $@;
			my $advice = "";

			if ($err =~ /Can't find loadable object/) {
				$advice = "Perhaps $prefix::$kind was statically linked into a new perl binary.\n"
					."In which case you need to use that new perl binary.\n"
					."Or perhaps only the .pm file was installed but not the shared object file."

			} elsif ($err =~ /Can't locate.*?$prefix_path$kind\.pm in \@INC/) {
				$advice = "Perhaps the $prefix::$kind perl module hasn't been fully installed.";

			} elsif ($err =~ /Can't locate .*? in \@INC/) {
				$advice = "Perhaps a module that $prefix::$kind requires hasn't been fully installed.";
			}
			Carp::croak("obj('$orignal_kind' => '$prefix\::$kind') failed: $err$advice\n");
		}
		
		$obj = "$prefix\::$kind"->new();
		return $_OBJ{$kind} = $obj;
	}
}

1;

__END__

=head1 NAME

CGI::AppToolkit::Template - Perl module to manipulate text templates

=head1 DESCRIPTION

This module takes a raw complex data structure and a formatted text file and combines the two. This is useful for the generation of HTML, XML, or any other formatted text. The templating syntax is formatted for quick parsing (by human or machine) and to be usable in most GUI HTML editors without having to do a lot of backflips. 

CGI::AppToolkit::Template was developed to fulfill several goals. It is similar to HTML::Template in concept and in style, but goes about it by very different means. It's goals are:

=over 4

=item *

Simple token replacement with minimal code on the CGI or script end.

=item * 

Simple and quick handling of complex data structures, including arrays.

=item *

To provide a complete seperation of HTML code and CGI code. With this module, the CGI script might not have any HTML code in it at all, and HTML will have no perl or script-like code in it at all. (The HTML designer doesn't have to know any scripting to create a very usable and powerful template.) To this end, this module also allows tokens to contain information for the CGI to read.

=item *

Speed. Because of this, error checking is minimal. 

=back

=head2 Methods

=over 4

=item B<template(>[FILENAME|STRING]B<)>

Shortcut to B<new(-set=E<gt>"template text")> or B<new(-file=E<gt>"filename")>. If the supplied string has line endings, it's assumed to be the template text, otherwise it's assumed to be a filename. This may be called as a method or as a subroutine. It will be imported into B<use>ing namespace when requested:

  use CGI::AppToolkit::Template qw/template/;

B<NOTE:> This module is loaded and this method is called by B<CGI::AppToolkit-E<gt>template()>, which should be used instead when using L<CGI::AppToolkit|CGI::AppToolkit>.

Example:

  $t = template('template.html');
  # OR
  $t = CGI::AppToolkit->template('template.html');
 
  # or to read the file in from another source manually
  open FILE, 'template.html';
  @lines = <FILE>;
  $t = template(\@lines); # must pass a ref
  # or
  $t = template(join('', @lines)); # or a single string  

=item B<new(>[OPTIONS]B<)>

Create a new CGI::AppToolkit::Template object. The B<template()> method cals this method for you, or you can call it directly.

B<NOTE:> If you are using L<CGI::AppToolkit|CGI::AppToolkit>, then it is highly recommended that you use it's B<CGI::AppToolkit-E<gt>template()> method instead.

OPTIONS include: B<load> (or B<file>), B<set> (or B<text> or B<string>), and B<cache>. B<load> and B<set> are shorthand for the corresponding methods. B<cache>, if non-zero, will tell the module to cache the templates loaded from file in a package-global variable. This is very useful when running under B<mod_perl>, for example.

Example:

  $t = CGI::AppToolkit::Template->new(-load => 'template.html');
 
  # or to read the file in from another source manually
  open FILE, 'template.html';
  @lines = <FILE>;
  $t = CGI::AppToolkit::Template->new(-text => \@lines); # must pass a ref
  # or
  $t = CGI::AppToolkit::Template->new(-text => join('', @lines)); # or a single string  

=item B<load(>FILENAMEB<)>

Load a file into the template object. Called automatically be B<template()> or B<CGI::AppToolkit-E<gt>template()>.

Example:

  $t = CGI::AppToolkit::Template->new();
  $t->load('template.html');

=item B<set(>TEXTB<)>

Sets the template to the supplied TEXT. Called automatically be B<template()> or B<CGI::AppToolkit-E<gt>template()>.

Example:

  $t = CGI::AppToolkit::Template->new();

  open FILE, 'template.html';
  @lines = <FILE>;
  $t->set(\@lines); # must pass a ref
  # or
  $t->set(join('', @lines)); # or a single string  

=item B<make(>I<HASHREF>B<)>

Makes the template. B<output> and B<print> are synonyms.

Example:

  $t->make({token => 'some text', names => [{name => 'Rob'}, {name => 'David'}]});

=item B<check_cache()>

Checks to see if the template file has been modified and reloads it if necessary. 

=item B<var(>NAMEB<)>

=item B<vars(>B<)>

B<var> loads a variable tagged with NAME from the template and returns it. B<vars> returns a list of variable names that can be passed to B<var>.

Example:

  $star = $t->var('star');
  @vars = $t->vars();

=back

=head2 Template Syntax

The template syntax is heirarchical and token based. Every tag has two forms: curly brace or HTML-like. All curly brace forms of tags begin with C<{?> and end with C<?}>. Angle brackets C<E<lt>E<gt>> may be used instead of curly braces C<{}>. For example, the following are all the same:

  {? $name ?}
  <? $name ?>
  <token name="name">
  <token name>

Use of HTML-like tags or curly brace tags with angle brackets might make the template difficult to use in some GUI HTML editors.

NOTE: Tokens may be escaped with a backslash '\' ... and becuase of this, I<backslashes will be lost>. You must escape any backslashes you want to keep in your template.

Tokens may be nested to virtually any level. The two styles, curly bace and html-like, may be mixed at will, but human readability may suffer.

Line endings may be of any OS style: Mac, UN!X, or DOS.

=over 4

=item B<{? $>I<key>B< ?}>

=item B<{? $>I<key> I<filter()>B< ?}>

=item B<E<lt>token name=">I<key>B<"E<gt>>

=item B<E<lt>token name=">I<key>B<" do=">I<filter()>B<"E<gt>>

=item B<E<lt>token >I<key>B<E<gt>>

=item B<E<lt>token >I<key> I<filter()>B<E<gt>>

A simple token. Replaced with the string value of a token provided with the specified name I<key>.

If a I<filter()> is specified, then the named L<C<CGI::AppToolkit::Template::Filter>|CGI::AppToolkit::Template::Filter> subclass will be loaded and it's C<filter()> function will be called, with the token's value and any parameters specified passed to it. Please see L<C<CGI::AppToolkit::Template::Filter>|CGI::AppToolkit::Template::Filter> for a list of provided filters.

NOTE: The template module's ability to parse the parameters are very rudimentary. It can only handle a comma delimited list of space-free words or single or double quoted strings. The string may have escaped quotes in them. The style of quote (single or double) makes no difference.

=item B<{?if $I<token> --?}>I<...>B<{?-- $I<token> --?}>I<...>B<{?-- $I<token> ?}>

=item B<{?if $I<token>=">I<template>B<" --?}>I<...>B<{?-- $I<token> --?}>I<...>B<{?-- $I<token> ?}>

=item B<{?if $I<token>='>I<text>B<' --?}>I<...>B<{?-- $I<token> --?}>I<...>B<{?-- $I<token> ?}>

=item B<{?if $I<token>=>I<number>B< --?}>I<...>B<{?-- $I<token> --?}>I<...>B<{?-- $I<token> ?}>

A decision if..else block. Checks I<token> to be true, or compares it to the string I<text>, the subtemplate I<template>, or the number I<number>, respectively, and if the test passes then the template code inside this token is appended to the output text. If there is an 'else' (C<{?-- $I<token> --?}> or C<E<lt>elseE<gt>>) and the test fails, the template code between the else and the end (C<{?-- $I<token> ?}>) will be appended to the output text.

The comparison operators C<E<lt>>, C<E<lt>=>, C<E<gt>>, C<E<gt>=>, or C<!=> may be used, and you may also place an exclamation point (C<!>) before the C<$token>.

  {?if $token<='a string' --?}...{?-- $token?}
  {?if !$token --?}...{?-- $token?}
  {?if !$token!='a string' --?}...{?-- $token?} <-- if token equals 'a string'

Comparison is done as a number if the value is not quoted, as a string if is single-quoted, and as a subtemplate if it is double-quoted. This is intended to be similar to the use of quotes in perl:

  <option {?if $selection = "{?$selected_item?}" --?}SELECTED{?-- $selection?}>{?$selection?}
  {?if $state != 'hidden' --?}<img src="...">{?-- $state?}
  {?if $count > 0 --?}{?$count?}{?-- $count --?}<font color="red">$count</font>{?-- $count?}

=item B<E<lt>iftoken name=">I<token>B<"E<gt>>I<...>B<E<lt>elseE<gt>>I<...>B<E<lt>/iftokenE<gt>>

=item B<E<lt>iftoken name=">I<token>B<" value=">I<value>B<" as=">I<(template|string|number)>B<" comparison=">I<(not|eq|ne|lt|le|gt|ge)>B<"E<gt>>I<...>B<E<lt>elseE<gt>>I<...>B<E<lt>/iftokenE<gt>>

An alternate syntax for the decision if..else block. Checks I<token> to be true, or compares it to the value I<value>, and if the test passes then the template code inside this token is appended to the output text. If there is an 'else' (B<{?-- $I<token> --?}> or B<E<lt>elseE<gt>>) and the test fails, the template code between the else and the end (C<E<lt>/iftokenE<gt>>) will be appended to the output text.

If there is no C<value="..."> given, then the token is tested for perl 'trueness.' If the C<comparison="..."> is given as C<not> or C<ne> then the 'trueness' of the token is reversed.

The value, if given, is treated as described in the C<as="...">, or as a number if not specified. Unlike the curly brace form, the style of quoting does B<not> matter. Possible C<as> values are C<string>, C<template>, or C<number>.

The token is compared to the value according to the value of C<comparison="...">. Possible values are C<not> (false), C<ne> (not equal), C<eq> (equal), C<lt> (less than), C<le> (less than or equal to), C<gt> (greater than), or C<ge> (greater than or equal to).

  <iftoken name="thanks">Thanks for visiting!<else>You're not welcome here! Go away.</iftoken>

You can mix token stylas as you wish, to the dismay of anyone (or any GUI HTML app) trying to read the template:

  <iftoken name="id" as="number" value="10" comparison="gt">Your id is greated than 10!{?-- $id --?}Your id <= 10.{?-- $id?}
  {?if $name --?}Hello '<token name='name'>'.<else>I don't know who you are!</iftoken>
  {?if $address --?}I know where you live!<else>I don't know your address{?-- $address?}
  <iftoken id><token id>{?-- $id?}

=item B<{? @>I<token>B< --?}>I<text>B<{?-- @>I<token>B< --?}>I<text>B<{?-- @>I<token>B< ?}>

=item B<E<lt>repeattoken name=">I<token>B<"E<gt>>I<...>B<E<lt>elseE<gt>>I<...>B<E<lt>/repeattokenE<gt>>

=item B<{? @>I<token>B< ?}>

=item B<E<lt>repeattoken name=">I<token>B<"/E<gt>>

A repeat token. Repeats the contents of this token for each hashref contained in the arrayref provided with the name I<token> and the results are appended to the output text. If the arrayref is empty and ther is an 'else' (B<{?-- $I<token> --?}> or B<E<lt>elseE<gt>>), then the template code between the else and the end (C<E<lt>/iftokenE<gt>>) will be appended to the output text.

=item B<{? @>I<token>B< ?}>

=item B<E<lt>repeattoken name=">I<token>B<"/E<gt>>

A repeat token, as above, except it repeats the line that it is on. The token can appear anywhere in the line.

  <select name="tool">
  	<option value="{?$id?}" {?if $id="{?$selected-tool?}" --?}SELECTED{?-- $id?}>{?$name?}{?@tools?}
  </select>

In the above example, the C<E<lt>option ...E<gt>> line will be repeated for every tool of the 'tools' array. If the C<id> is the same as C<{?$selected-tool?}>, then SELECTED. So, in the code we call:

  print CGI::AppToolkit->template('tools')->make(
  	'tools' => [
  		{'id' => 1, 'name' => 'Hammer'},
  		{'id' => 2, 'name' => 'Name'},
  		{'id' => 3, 'name' => 'Drill'},
  		{'id' => 4, 'name' => 'Saw'},
  	],
  	'selected-tool' => 3
  );

And, assuming the file is called 'C<tools.tmpl>,' then the result should look something like:

  <select name="tool">
        <option value="1" >Hammer
        <option value="2" >Name
        <option value="3" SELECTED>Drill
        <option value="4" >Saw
  </select>

=item B<{? my $I<var> --?}>I<text>B<{?-- $I<var> ?}>

=item B<{? my $I<var>='>I<text>B<' ?}>

=item B<E<lt>vartoken name=">I<token>B<"E<gt>>I<text>B<E<lt>/vartokenE<gt>>

=item B<E<lt>vartoken name=">I<token>B<" value=">I<text>B<"E<gt>>

A variable token. This will not appear in the output text, but the contents (value) can be retrieved with the C<var()> and C<vars()> methods.

=back

=head2 Data Format

The data passed to the C<make> method corresponds to the tags in the template. Each token is a named key-value pair of a hashref. For example, the following code:

  use CGI::AppToolkit;
  my $t = CGI::AppToolkit->template('example.tmpl');
  print $t->make({'token' => 'This is my text!'});

Given the file C<example.tmpl> contains:

  <html>
    <head><title>{?$token?}</title></head>
	<body>
	Some text: {?$token?}
	</body>
  </html>

Will print:

  <html>
    <head><title>This is my text!</title></head>
	<body>
	Some text: This is my text!
	</body>
  </html>

Complex data structures can be represented as well:

  use CGI::AppToolkit;
  my $t = CGI::AppToolkit->template('example2.tmpl');
  print $t->make({
        'title' =>'All about tokens',
        'tokens' => [
                {'token' => 'This is my text!'},
                {'token' => 'Text Too!'}
                ]
        });

Given the file C<example.tmpl> contains:

  <html>
    <head><title>{?$title?}</title></head>
    <body>
      {?@tokens?}Some text: {?$token?}
    </body>
  </html>

Will print:

  <html>
    <head><title>All about tokens</title></head>
	<body>
      Some text: This is my text!
      Some text: Text Too!
    </body>
  </html>

=head1 SYNOPSIS

=head2 Example template:

In this example I combine the use of B<E<lt>?$token?E<gt>> style syntax and B<{?$token?}> style syntax.

  <html>
    <head>
      <title><?$title><title>
    <head>
      <body>
        
        <?$body?><br>
        Made by: <token name="who">
        
        <table>
          <tr>
            <td>
              Name
            </td>
            <td>
              Options
            </td>
          </tr>
  {?@repeat --?}
          <tr>
            <td>
              <token name>
            </td>
            <td>
              <a href="index.cgi?edit-id={?$id?}">Edit<?a>
            </td>
          </tr>
  {?-- @repeat?}
        </table>
      </body>
    </head>
  </html> 

  <?my $author-->
    <B><A HREF="mailto:rob@heavyhosting.net">Rob Giseburt</A></B>
  <?--$author>

=head2 Example CGI code:

  #!/bin/perl
  
  use CGI; # see the perldoc for the CGI module
  use CGI::AppToolkit;
  
  #-- Standard CGI/CGI::AppToolkit stuff --#
  $cgi = CGI->new();
  $kit = CGI::AppToolkit->new();
  $kit->connect( ... ) || die $db->errstr;
  
  # load the data from a DB
  # returns an arrayref of hashrefs
  $repeat = $kit->data('item')->fetch(-all => 1);
  
  # Place the loaded data in a page-wide data structure
  $data = {
    title => 'This is an example of CGI::AppToolkit::Template at work.',
    body => 'Select edit from one of the options below:',
    repeat => $repeat
  };
  
  # print the CGI header
  print $cgi->header();
  
  #-- CGI::AppToolkit::Template stuff --#
  
  $template = $kit->template('example.tmpl');
  
  # load the 'author' HTML from the template
  $author = $template->var('author');
  # place it into the data
  $data->{'who'} = $author;

  # output the results of the data inserted into the template
  print $template->output($data);

=head1 AUTHOR

Copyright 2002 Robert Giseburt (rob@heavyhosting.net).  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please visit http://www.heavyhosting.net/AppToolkit/ for complete documentation.

=cut