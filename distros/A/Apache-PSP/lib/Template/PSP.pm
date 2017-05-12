package Template::PSP;

require 5.005;

use strict;

use Carp;

use HTML::Parser;
use IO::Scalar;
use DBI; 
use vars qw($VERSION);

$VERSION = 1.00;

# %tags        - list of special HTML tags defined in Template.pm
# %global_tags - list of HTML tags, accessible by all pages
#
# $page       - scalar reference to script being created from template
# $frags      - html fragments
# $outputflag - process '$' variables
# $perlflag   - perl code
# $package    - template is being placed in $package
# %tagdata    - data associated with tag being created
# %Cache      - file time stamps for loaded psp pages
# %Handler    - pointers to subroutines for psp pages
# %type       - subroutines for handling output types

use vars qw (%tags %global_tags $page $parsefile $frags $outputflag $perlflag
	     $handlerflag $package %tagdata %Cache %Handler %type $lineno
	     $top_package $escapeflag $space
	    );

use vars qw(%QUERY %CGI %FILENAMES %AUTH %COOKIE);

%tags = map {$_ => 1} 
	( "tag", "loop", "if", "else", "elseif", "perl", "fetch", "output", 
	"handler", "return", "include", "pspescape" );

sub cleanup
{
  no strict 'refs';
  push(@{$top_package . "::cleanup_handler"}, shift);
}

sub cleanup_handler
{
  my $handlers = shift(@_);
  
  for (my $i=0;$handlers->[$i];$i++)
  {
    &{$handlers->[$i]}();
  }
}

sub setpvar
{
  my $item = shift;
  my $value = shift;
  if ($item)
  {
    no strict 'refs';
    ${$top_package . "::" . $item} = $value;
  }
}

sub getpvar
{
  my $item = shift;
  no strict 'refs';
  return ${$top_package . "::" . $item};
}

# derive the absolute path based on a
# relative filename and the current file
# 
# thanks to Scott Kiehn
#
sub abs_path
{
  my $file = shift(@_);
  
  my $prefix = substr($file, 0, 1);
  
  # if this is not an absolute path, 
  # create an absolute path from it
  if ($prefix ne '/')          
  {
    # check for document root abbreviation
    if ($prefix eq '~')     
    {
      $file = substr($file, 1);
      $file = $ENV{DOCUMENT_ROOT} . $file;
    }
    # otherwise use relative path based on the current file
    else                        
    {
      $file = substr( $parsefile, 0, rindex($parsefile, '/') ) . "/" . $file;
    }
  }

  return $file;
}


################################################################
# pspload
# pspload reloads psp pages that have changed on disk and 
# puts the code for those pages into their own package based
# on the name of the file being loaded.  We run the file
# name passed to pspload through abs_path to be certain that
# the file name is uniquely defined.

sub pspload
{
  my ($data, $pkg, $topflag) = @_;
  my $parseflag = 0;
  my $handler;
  my $file;
  my ($oldpage, $oldpkg, $oldfrags, $pg, $oldfile, $oldlineno);

  if (!ref($data))
  {
    # data is a file name, not the code 
    # This file name may have . ../.. or a relative path
    # that makes it not uniquely defined
    $file = abs_path($data);
  
    if (newfile($file))
    {
      # we've not loaded the file before, or it
      # has changed on disk.  Load it.
      if (!defined($pkg))
      {
        $pkg = valid_package_name($file);
      }
      $parseflag = 1;
    }
    else
    {
      $handler = $Handler{$file};
    }
  }
  else
  {
    $parseflag = 1;
    $file = $ENV{SCRIPT_FILENAME};
  }
  
  if ($parseflag)
  {
    my $parser;
    my $token;
    
    # we need to create a temporary place
    # to store the page as it is building it
    $oldlineno = $lineno;
    $oldfile = $parsefile;
    $oldfrags = $frags;
    $oldpage = $page;
    $oldpkg = $package;
    $frags = 0;
    $lineno = 1;
    $package = $pkg;
    $page = \$pg;
    $parsefile = $file;
    
    my $eval =  "package $pkg;\n" .
		'*getpvar = \&Template::PSP::getpvar;' . "\n" .
	        '*setpvar = \&Template::PSP::setpvar;' . "\n" .
		'*cleanup = \&Template::PSP::cleanup;' . "\n" .
		'use CGI::Minimal;' . "\n" .
		'use vars qw(%QUERY %CGI %FILENAMES %AUTH %COOKIE);' . "\n";
    
    eval $eval;
    
    append_page("package $pkg;\n");
    append_page("no strict;\n");
    append_page("sub {\n");
    if ($topflag)
    {
      append_page('$Template::PSP::top_package = ' . $pkg . ";\n");
	    append_page('Template::PSP::set_hashes(*CGI, *COOKIE, *QUERY, *FILENAMES, *AUTH);' . "\n");    }
    else
    {
      append_page(
	  '*QUERY = *{$Template::PSP::top_package . "::QUERY"};' . "\n" .
	  '*CGI = *{$Template::PSP::top_package . "::CGI"};' . "\n" .
	  '*FILENAMES = *{$Template::PSP::top_package . "::FILENAMES"};' . "\n" .
	  '*AUTH = *{$Template::PSP::top_package . "::AUTH"};' . "\n" .
	  '*COOKIE = *{$Template::PSP::top_package . "::COOKIE"};' . "\n");
    }
    
    $parser = HTML::Parser->new( api_version => 3,
				 start_h => [\&start, "tagname,attr,text"],
				 end_h => [\&end, "tagname,text"],
				 text_h => [\&text, "text,is_cdata"],
				 comment_h => [\&comment, "text"],
				 default_h => [\&default, "text"]
			       );
    
    # send unbroken text instead of chunks to improve performance
    # by reducing the number of function calls 
    $parser->unbroken_text(1);
    $parser->xml_mode(1);
    
    if (ref($data))
    {
      $parser->parse($$data) || croak "$! in pspload()";
    }
    else
    {
      $parser->parse_file($data) || croak "$! while loading file '$data'";
    }
    
    if ($topflag)
    {
      append_page('&Template::PSP::cleanup_handler(\@cleanup_handler);' . "\n");
      append_page('select(STDOUT);' . "\n");
    }
    append_page("return 1;\n");
    append_page("}\n");
    
    $handler = eval $$page;
        
    if ($@)
    {
      psperror($file);
    }
    
    if ($file)
    {
      $Handler{$file} = $handler;
    }
    
    no strict 'refs';
    
    # restore globals
    $lineno = $oldlineno;
    $parsefile = $oldfile;
    $frags = $oldfrags;
    $page = $oldpage;
    $package = $oldpkg;
  }

  # import export_tags from loaded page
  if (defined($package))
  {
    if (!defined($pkg))
    {
      $pkg = valid_package_name($file);
    }
    
    no strict 'refs';
    
    foreach my $tag (keys %{$pkg . "::export_tags"})
    {
      ${$package . "::custom_tags"}{$tag} = ${$pkg . "::export_tags"}{$tag};
    }
  }

  return $handler;
}


# displays psp page with line numbers
sub pspdebug
{
  no strict 'refs';
  my @lines = split("\n", $$page);
  for (my $i = 1; $i <= $#lines + 1;$i++)
  {
    print STDERR "<$i> " . $lines[$i-1] . "\n";
  }
}

# output error
sub psperror
{
  my $tag = shift;

  #    pspdebug();
  #    croak "failed when processing " . $tagdata{name} . ": $@\n";
  croak $@;
}

# appends code to page
sub append_page
{
  no strict 'refs';
  ${$page} .= join(" ", @_);
}

sub set_hashes (%%%%%)
{
  local(*CGI, *COOKIE, *QUERY, *FILENAMES, *AUTH) =  @_;
  
  # duplicate environment variables in %CGI
  %CGI = %ENV;
  
  # fill %QUERY with query values
  my $cgi = CGI::Minimal->new();
#  %QUERY = map { my $x = [$cgi->param($_)]; $_ => scalar(@{$x}) > 1 ? \@{$x} : $$x[0] } ($cgi->param);
  # canonically-correct (and possibly temporary) expansion
  %QUERY = ();
  my @params = $cgi->param();
  foreach my $p (@params)
  {
    my @items = $cgi->param($p);
    if (scalar(@items) > 1)
    {
      $QUERY{$p} = \@items;
    }
    else
    {
      $QUERY{$p} = $items[0];
    }
  }

  
  # process cookies for this request
  my $cgi = CGI::Minimal->new();
  %COOKIE = ();
  my @cookies = split(/; ?/,$ENV{HTTP_COOKIE});
  foreach my $item (@cookies) 
  {
    my ($name, $value) = split('=', $item);
    $COOKIE{$name} = $cgi->url_decode($value);
  }
  
  # leave authorization for another time
#  if ($ENV->{HTTP_AUTHORIZATION}) 
#  {
#    my @list = split(/ /, $ENV{HTTP_AUTHORIZATION});
#    if (lc($list[0]) eq "basic") 
#    {
#      my $encoded = pop(@list);
#      my $decoded = decode_base64($encoded);
#  
#      ($AUTH->{username}, $AUTH->{password}) = split(/:/, $decoded);
#    }
#  }
  
  return 1;
}

#########################################
# Template::PSP::Parser
# used to process psp pages using HTML::Parser

sub start
{
  my $tagname = lc(shift);
  my $attr = shift;
  my $text = shift;

  no strict 'refs';

  default($text);

  if ($escapeflag || $tagname eq $tagdata{name} || $perlflag)
  {
    text($space . $text);
    $space = "";
    return;
  }

  # start tag
  if ($tags{$tagname})
  {
    no strict 'refs';
    &{$tagname}($attr);
    return;
  }

  my $fn = ${$package . "::custom_tags"}{$tagname} || $global_tags{$tagname};

  if ($fn)
  {
    append_page('&' . $fn . '({');
    
    foreach my $item (keys %{$attr})
    {
      my $s;
      my $s2;
      my $arg = ${$attr}{$item};
      $s2 = substr($arg,0,1);
      $s = substr($arg,1,1);
      
      if (($s2 eq '$') ||
          (($s2 eq "\\") &&
           ($s eq '@') ||
           ($s eq '%') ||
           ($s eq '&')
          )
         )
      {
        # don't quote because arg is a reference
        append_page("'$item'", '=>', $arg . ',');
      }
      else
      {
        if ($arg !~ /^@/)
        {
          $arg =~ s/@/\\@/gs;
        }
        $arg =~ s/{/\\{/g;
        $arg =~ s/}/\\}/g;
        append_page("'$item'", '=>', 'qq{' . $arg . '},');
      }
    }
    
    append_page('});'  . "\n");
    return;
  }
  
  text($space . $text);
  $space = "";
  return;
}

sub end
{
  my $tagname = lc(shift);
  my $text = shift;

  default($text);

  if (($escapeflag && $tagname ne "pspescape") ||
      ($tagname eq $tagdata{name}) ||
      ($handlerflag && $tagname ne "handler") ||
      (!$handlerflag && $perlflag && $tagname ne "perl"))
  {
    text($space . $text);
    $space = "";
    return;
  }

  if ($tags{$tagname})
  {
    no strict 'refs';
    &{$tagname . "_"}();
    return;
  }

  no strict 'refs';

  my $fn = $global_tags{$tagname . "_"} ||
           ${$package . "::custom_tags"}{$tagname . "_"};

  if ($fn)
  {
    no strict 'refs';
    append_page('&' . $fn .'();' . "\n");
    return;
  }
  
  text($space . $text);
  $space = "";
  return;
}

# for comments,
# display the comment as provided
sub comment
{
  my ($text) = @_;
  default($text);

  text($space . $text);
  $space = "";
  return;
  
  return;
}

sub default
{
  my ($text) = @_;
  $lineno += count_lines($text);
}

# handles all text that is read by the parser
sub text
{
  my ($text) = @_;

  if (!$escapeflag && $text =~ /^\s*$/s)
  {
    $space = $text;
    return;
  }
  if ($perlflag)
  {
    append_page($text);
  }
  elsif ($outputflag)
  {
    $text =~ s/\@/\\\@/g;
    append_page('print qq{' . $text . '};' . "\n");
  }
  else
  {
    no strict 'refs';
    $frags++;
    ${$package . '::__html_' . $frags} = $text;
    append_page("print \$" . $package . '::__html_' . $frags . ";\n");;
  }
}


#########################################
# BEGIN TAG DEFINITIONS
#
# The tag TAG allows building of non-looping tags.
# three parameters can be passed:
# name - name of tag to create
# body - if set to nonzero, the tag being defined contains
#     a body
# output - if set to nonzero, the tag being defined will
#     evaluate variables that begin with '$' 


sub tag
{
  my ($attr) = @_;
  my (@attrs) = split(/,/, $attr->{accepts});

  # Try to hide global variables for building tag in
  # %Template::PSP::tagdata

  $tagdata{body} = $attr->{body};
  if ($tagdata{body})
  {
    push(@attrs, "body");
  }
  $tagdata{global} = $attr->{global};
  $tagdata{name} = lc($attr->{name});
  $tagdata{oldpage} = $page;
  $page = \$tagdata{page};

  # For each new tag, create a Perl function 
  # which will be called when the start tag is 
  # encountered

  append_page('package', $package . ";\n");
  append_page("no strict 'refs';\n");
  append_page('sub', $tagdata{name}, "{\n");
  append_page('my ($attr) = @_;' . "\n");
  
  foreach my $item (@attrs)
  {
    append_page('my', "\$" . $item, "=", '$attr->{' . $item . "};\n");
  }

  append_page("#line $lineno $parsefile\n"); 

  # If the tag we are defining will have a body,
  # redirect the output from processing the body
  # to a Perl scalar ($body).  Create a Perl function
  # which will be called when the end tag is encountered

  if ($tagdata{body})
  {
    # save all variables
    append_page('push(@Template::PSP::attrs, $attr);' . "\n");
    
    # Here's a nasty Perl trick for redirecting STDOUT to a scalar 
    # called $body
    
    append_page('push(@Template::PSP::oldfh, select(IO::Scalar->new_tie(\$attr->{body})));' . "\n");
    
    append_page('if ($attr->{"/"} eq "/") {' . "\n");
    append_page('&' . $tagdata{name} . '_();' . "\n");
    append_page('}' . "\n");
    append_page('}' . "\n");
    
    # Below is the creation of the Perl sub to be called after
    # we encounter the end tag.  Tags that have a body cannot
    # be processed until after the output from the body has
    # been obtained and stored in the scalar $body.  Tag
    # processing is thus placed after the end tag has been
    # encountered.
    
    append_page('sub', $tagdata{name} . '_',  '{' . "\n");
    
    # restore variables
    append_page('my $attr = pop(@Template::PSP::attrs);' . "\n");
    foreach my $item (@attrs)
    {
      append_page('my', "\$" . $item, "=", '$attr->{' . $item . '};' . "\n");
    }
    
    # stop sending STDOUT to scalar
    append_page('close(select(pop(@Template::PSP::oldfh)));' . "\n");
  }
}

# tag_ is called when the HTML tokenizer encounters the
# /tag.  The function finishes creating the Perl subroutine
# needed for processing the tag.

sub tag_
{
  append_page('}' . "\n");
  
  # add this tag to %global_tags or %export_tags for the page
  my $tagtype;
  if ($tagdata{global})
  {
    $tagtype = "Template::PSP::global";
  }
  else
  {
    $tagtype = $package . "::export";
    append_page("\$" . $package . "::" . 'custom_tags{' . $tagdata{name} . '}', '=',  '"' . $package . '::' . $tagdata{name} . '";' . "\n");
    if ($tagdata{body})
    {
      append_page("\$" . $package . "::" . 'custom_tags{' . $tagdata{name} . '_}', '=',  '"' . $package . '::' . $tagdata{name} . '_";' . "\n");
    }
  }
  append_page("\$" . $tagtype . '_tags{' . $tagdata{name} . '}', '=',  '"' . $package . '::' . $tagdata{name} . '";' . "\n");
  if ($tagdata{body})
  {
    append_page("\$" . $tagtype . '_tags{' . $tagdata{name} . '_}', '=',  '"' . $package . '::' . $tagdata{name} . '_";' . "\n");
  }
  
  eval $tagdata{page};
  if ($@)
  {
    psperror($tagdata{name});
  }
  
  # restore the current page that is being built
  $page = $tagdata{oldpage};
  undef %tagdata;
}

sub handler
{
  my ($attr) = @_;
  
  $handlerflag++;
  
  $tagdata{type} = $attr->{type};
  $tagdata{oldpage} = $page;
  $page = \$tagdata{page};
  
  append_page("no strict 'refs';\n");
  append_page('sub {' . "\n");
  append_page('my $data = shift;' . "\n");
  append_page('my $row = shift;' . "\n");
  append_page('my $fetch = shift;' . "\n");
  
  perl();
}

sub handler_
{
  perl_();
  append_page('}' . "\n");
  $type{$tagdata{type}} = eval $tagdata{page};
  if ($@)
  {
    psperror($tagdata{type});
  }
  $page = $tagdata{oldpage};
  undef %tagdata;
  $handlerflag--;
}

sub return
{
  append_page("return;\n");
}

sub return_ {};


# add HTML conditionals: loop, if, else, etc.
# these special tags must be written in Perl and
# cannot use the TAG tag.

sub loop
{
  my ($attr) = @_;

  my $name = $attr->{name} || "count";
  my $from = $attr->{from} || "1" ;
  my $to   = $attr->{to};
  my $step = $attr->{step} || "1";
  my $cond = $attr->{cond};
  my $list = $attr->{list};

  append_page("#line $lineno $parsefile\n"); 
  if ($cond)
  {
    append_page("while ($cond) {\n");
  }
  elsif ($list)
  {
    append_page("foreach my \$$name ($list) {\n");
  }
  else
  {
    append_page("for (my \$$name = $from; \$$name <= $to; \$$name+=$step) {\n");
  }
}

sub loop_
{
  append_page("}\n");
}


sub if
{
  my ($attr) = @_;
  append_page("#line $lineno $parsefile\n"); 
  append_page('if (' . $attr->{cond}. ') {' . "\n");
}

sub if_
{
  append_page("}" . "\n");
}

sub else
{
  append_page('} else {' . "\n");
}

sub else_ {}

sub elseif
{
  my ($attr) = @_;
  append_page("#line $lineno $parsefile\n"); 
  append_page('} elsif (' . $attr->{cond}. ') {' . "\n");
}

sub elseif_ {}

# autoloop works with the autoform tags

sub autoloop
{
  my ($attr) = @_;

  my $name = $attr->{name} || "count";

  append_page("#line $lineno $parsefile\n"); 
  
  # save the current autofill pvar
  append_page("my \$af = getpvar('autofilldata');\n");
  append_page("setpvar('autofilldata_save', \$af);\n");
  append_page("\n");
  append_page("foreach my \$item (\@{\$af->{$name}})\n");
  append_page("{\n");
  append_page("  setpvar('autofilldata', \$item);\n");
}

sub autoloop_
{
  append_page("}\n");
  
  # revive the previous autofill pvar
  append_page("setpvar('autofilldata', getpvar('autofilldata_save');\n");
}



# The <perl>, </perl> tags are special as well.  They
# modify the way that the script page is built, and
# therefore cannot be defined with the TAG tag.

sub perl
{
  $perlflag++;
  append_page("#line $lineno $parsefile\n");
  append_page('$|++;');
}

sub perl_
{
  append_page(";\n");
  $perlflag--;
}

# The <fetch> tag searches the %type hash for a handler.
# If no handler is found, we assume that the user
# is outputting global scalars.  New output types can
# be easily added by adding handlers to the %type hash.

sub fetch {
    my ($attr) = @_;
    my ($handler) = $type{$attr->{type}};
    my @fetch = split(/,/, $attr->{fetch});

    if (defined($handler)) {
	my $attrs;
	$attrs .= "[";
	foreach my $item (@fetch) {
	    $attrs .= "\"$item\",";
	}
	$attrs .= "]";
	    
	my $startrow = $attr->{startrow} || 0;
	my $endrow = $attr->{endrow};

	append_page("#line $lineno $parsefile\n"); 
	append_page('for (my $i=' . $startrow . '; (my $results = &{$Template::PSP::type{'
		    . lc($attr->{type})
		    . '}}($' . $attr->{query} . ' || getpvar("'
		    . $attr->{query}
		    . '"), $i, '
		    . $attrs
		    . '))' );
	if ($endrow) {
	    append_page('&& $i <' . $endrow);
	}
	append_page('; $i++) {' . "\n");
    } else {
	append_page("{\n");
	append_page('my $results = $'.$attr->{query}.' || getpvar("'.$attr->{query}."\");\n");
    }
    foreach my $item (@fetch) {
        append_page("my \$$item =", '$results->{' . $item. '};' . "\n");
    }
}

sub fetch_ {
    append_page("}\n");
}

sub output 
{
    $outputflag++;
}

sub output_ 
{
  $outputflag--;
  $outputflag = 0 if $outputflag < 0;  
}

sub pspescape 
{
  $escapeflag++;
}

sub pspescape_ 
{
  $escapeflag--;
  $escapeflag = 0 if $escapeflag < 0;  
}

sub include 
{
  my ($attr) = @_;
 
  my $file     = eval qq{"$attr->{file}"};
  $file = abs_path($file);

  if (! -f $file) 
  {
    croak "Cannot include file '", $attr->{file}, 
          "' while processing $parsefile\n";
  }
  
  pspload($file);
  
  append_page('&{&Template::PSP::pspload(' . "'$file'" . ')}();' . "\n");
}

sub include_ {}

# load the rest of the tags
foreach my $filename qw(Tags.psp autoform.psp)
{
  my $tags_file;
  
  foreach my $path (@INC)
  {
    my $test = $path . "/Template/PSP/$filename";
    
    if (-e $test)
    {
      $tags_file = $test;
      last;
    }
  }
  
  if ($tags_file)
  {
    eval { pspload($tags_file, "Template::PSP"); };
    if ($@)
    {
      warn "WARNING: Can't load optional tags from $tags_file. " .
           "Some global tags may not be available.\n";
    }
  }
}

#########################################
# MISC FUNCTIONS

# checks if file has changed on disk
sub newfile {
    my $file = shift;
    my $mtime = -M "$file";

    if (!defined($Cache{$file}) || $Cache{$file} != $mtime) {
	$Cache{$file} = $mtime;
	return 1;
    }
    return 0;
}

# converts file name into valid package
sub valid_package_name {
    my($string) = @_;
    $string =~ s/([^A-Za-z0-9\/])/sprintf("_%2x",unpack("C",$1))/eg;
    # second pass only for words starting with a digit
    $string =~ s|/(\d)|sprintf("/_%2x",unpack("C",$1))|eg;
    
    # Dress it up as a real package name
    $string =~ s|/|::|g;
    return "ve" . $string;
}


sub count_lines {
    my $text = shift;
    my $pos = 0;
    my $lines;

    while (($pos = index($text, "\n", $pos)) >= 0) {
	$lines++;
	$pos++;
    }
    return $lines;
}


1;

__END__

=head1 NAME

Template::PSP - Process HTML-like files with custom tags and Perl code

=head1 SYNOPSIS

  use Template::PSP;

  my $page_code = Template::PSP::pspload($filename);
  &$page_code();

=head1 DESCRIPTION

Template::PSP allows arbitrary Perl code to be embedded in HTML-like pages. It also provides a framework for creating custom tags using a combination of text and evaluated Perl. 

=head1 AUTHOR

Chris Radcliff, chris@globalspin.com

=head1 SEE ALSO

Apache::PSP

=cut
