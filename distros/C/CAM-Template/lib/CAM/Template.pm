package CAM::Template;

=head1 NAME

CAM::Template - Clotho-style search/replace HTML templates

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

  use CAM::Template;
  my $tmpl = new CAM::Template($tmpldir . "/main_tmpl.html");
  $tmpl->addParams(url => "http://foo.com/",
                   date => localtime(),
                   name => "Carol");
  $tmpl->addParams(\%more_params);
  $tmpl->setLoop("birthdaylist", name => "Eileen", date => "Sep 12");
  $tmpl->addLoop("birthdaylist", name => "Chris",  date => "Oct 13");
  $tmpl->addLoop("birthdaylist", [{name => "Dan",   date => "Feb 12"},
                                  {name => "Scott", date => "Sep 24"}]);
  print "Content-Type: text/html\n\n";
  $tmpl->print();

=head1 DESCRIPTION

This package is intended to replace Clotho's traditional ::PARAM::
syntax with an object-oriented API.  This syntax is overrideable by
subclasses.  See the last section of this documentation for an
explanation of the default syntax.

We recommend that you DO NOT use this module unless you have a good
reason.  The other CPAN templating modules, like HTML::Template and
Template::Toolkit) are better maintained than this one.  See 
L<http://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html>
for an excellent discussion of the various templating approaches.

So why does this module exist?  Legacy, mostly.  A ton of HTML was
written in this templating language.  So, we keep this module in good
condition.  Additionally, we believe it's unique in the Perl community
in that it has a reconfigurable template syntax.  That's worth a
little, we think.

=cut

#==============================

require 5.005_62;
use strict;
use warnings;
use Carp;

our @ISA = qw();
our $VERSION = '0.93';

## Global package settings

our $global_include_files = 1;

# Flags for the in-memory file cache
our $global_use_cache = 1;
our %global_filecache = ();

#==============================

=head1 FUNCTIONS 

=over 4

=cut

#==============================

=item patterns

This class method returns a series of regular expressions used for
template searching and replacing.  Modules which subclass
CAM::Template can override this method to implement a different
template syntax.

Example of the recommended way to write an override function for this
method in a subclass:

  sub patterns {
    my $pkg = shift;
    return {
      $pkg->SUPER::patterns(),
      # include syntax:  <? include("subfile.tmpl") ?>
      include => qr/<? *include\(\"([^\"]+)\"\) *?>/,
    };
  }

=cut

sub patterns
{
   my $pkg = shift;

   return {
      # $1 is the loop name
      loopstart => qr/<cam_loop\s+name\s*=\s*\"?([\w\-]+)\"?>/i,
      loopend => qr/<\/cam_loop>/i,

      # a string that looks like one of the "vars" below for
      # substituting the loop variable.  This will be used in:
      #    $template =~ s/loop-pattern/loop_out-pattern/;
      loop_out => '::$1::',

      # DEPRECATED
      # $1 is the variable name, $2 is the conditional body
      #if => qr/\?\?([\w\-]+?)\?\?(.*?)\?\?\1\?\?/s,
      #unless => qr/\?\?!([\w\-]+?)\?\?(.*?)\?\?!\1\?\?/s,

      # $1 is a boolean flag, $2 is the variable name,
      # $3 is the conditional body
      ifunless => qr/\?\?(!?)([\w\-]+?)\?\?(.*?)\?\?\1\2\?\?/s,
      ifunless_test => qr/^!$/s,


      # $1 is the variable name
      vars => [
               qr/<!--\s*::([\w\-]+?)::\s*-->/s,
               qr/::([\w\-]+?)::/s,
               qr/;;([\w\-]+?);;/s,
               ],
          
      # $1 is the variable name, $2 is the value to set it to
      staticvars => qr/::([\w\-]+)==(.{0,80}?)::/,

      # $1 is the subtemplate filename
      include => qr/<!\-\-\s*\#include\s+template=\"([^\"]+)\"\s*\-\->/,
   };
}
#==============================

=item new

=item new FILENAME

=item new FILENAME, PARAMS

Create a new template object.  You can specify the template filename and
the replacement dictionary right away, or do it later via methods.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless({
      content => undef,
      params => {},
      use_cache => $global_use_cache,
      include_files => $global_include_files,
      patterns => $pkg->patterns(),
      isloop => 0,
   }, $pkg);

   if (@_ > 0 && !$self->setFilename(shift))
   {
      return undef;
   }
   if (@_ > 0 && !$self->addParams(@_))
   {
      return undef;
   }

   return $self;
}
#==============================

=item setFileCache 0|1

Indicate whether the template file should be cached in memory.
Defaults to 1 (aka true).  This can be used either on an object or
globally:

    my $tmpl = new CAM::Template();
    $tmpl->setFileCache(0);
       or
    CAM::Template->setFileCache(0);

The global value only affects future template objects, not existing
ones.

=cut

sub setFileCache
{
   my $self = shift;
   my $bool = shift;

   if (ref($self))
   {
      $self->{use_cache} = $bool;
      return $self;
   }
   else
   {
      $global_use_cache = $bool;
      return 1;
   }
}
#==============================

=item setIncludeFiles 0|1

Indicate whether the template file should be able to include other template files automatically via the

   <!-- #include template="<filename>" -->

directive.  Defaults to 1 (aka true).  Note that this is recursive, so
don't have a file include itself!  This method can be used either on
an object or globally:

    my $tmpl = new CAM::Template();
    $tmpl->setIncludeFiles(0);
       or
    CAM::Template->setIncludeFiles(0);

The global value only affects future template objects, not existing
ones.

=cut

sub setIncludeFiles
{
   my $self = shift;
   my $bool = shift;

   if (ref($self))
   {
      $self->{include_files} = $bool;
      return $self;
   }
   else
   {
      $global_include_files = $bool;
      return 1;
   }
}
#==============================

=item setFilename FILENAME

Specify the template file to be used.  Returns false if the file does
not exist or the object if it does.  This loads and preparses the file.

=cut

sub setFilename
{
   my $self = shift;
   my $filename = shift;

   # Validate input
   if ((! $filename) || (! -r $filename))
   {
      &carp("File '$filename' cannot be read");
      return undef;
   }
   $self->{content} = $self->_fetchfile($filename);
   $self->{filename} = $filename;
   $self->_preparse();
   return $self;
}
#==============================

=item setString STRING

Specify template content to be used.  Use this instead of setFilename if
you already have the contents in memory.  This preparses the string.

=cut

sub setString
{
   my $self = shift;
   $self->{content} = {
      string => shift,
      studied => 0,
      skip => {},
   };
   delete $self->{filename};
   $self->_preparse();
   return $self;
}
#==============================

=item loopClass

Template loops (i.e. C<addLoop>) usually instantiate new template
objects to populate the loop body.  In general, we want the new
instance to be the same class as the main template object.  However,
in some subclasses of CAM::Template, this is a bad thing (for example
PDF templates with loops in their individual pages).

In the latter case, the subclass should override this method with
something like the following:

   sub loopClass { "CAM::Template" }

=cut

sub loopClass
{
   my $pkg_or_self = shift;

   return ref($pkg_or_self) || $pkg_or_self;
}
#==============================

=item addLoop LOOPNAME, HASHREF | KEY => VALUE, ...

=item addLoop LOOPNAME, ARRAYREF

Add to an iterating portion of the page.  This extracts the <cam_loop>
from the template, fills it with the specified parameters (and any
previously specified with setParams() or addParams()), and appends to
the LOOPNAME parameter in the params list.

If the ARRAYREF form of the method is used, it behaves as if you had done:

    foreach my $row (@$ARRAYREF) {
       $tmpl->addLoop($LOOPNAME, $row);
    }

so, the elements of the ARRAYREF are hashrefs representing a series of
rows to be added.

=cut

sub addLoop
{
   my $self = shift;
   my $loopname = shift;
   # additional params are collected below

   return undef if (!$self->{content});
   return undef if (!defined $self->{content}->{loops}->{$loopname});

   while (@_ > 0 && $_[0] && ref($_[0]) && ref($_[0]) eq "ARRAY")
   {
      my $looparray = shift;
      foreach my $loop (@$looparray)
      {
         if (!$self->addLoop($loopname, $loop))
         {
            return undef;
         }
      }
      # If we run out of arrayrefs, quit
      if (@_ == 0)
      {
         return $self;
      }
   }

   my $looptemplate = $self->{content}->{loop_cache}->{$loopname};
   if (!$looptemplate)
   {
      $self->{content}->{loop_cache}->{$loopname} =
          $looptemplate = $self->loopClass()->new();
      $looptemplate->{content} = {
         skip => {%{$self->{content}->{skip}}},
         string => $self->{content}->{loops}->{$loopname},
         staticparams => $self->{content}->{staticparams},
      };
      $looptemplate->study() if ($self->{content}->{studied});
   }
   $looptemplate->setParams(\%{$self->{params}}, $loopname => "", @_);
   $self->{params}->{$loopname} .= $looptemplate->toString();
   return $self;
}
#==============================

=item clearLoop LOOPNAME

Blank the contents of the loop accumlator.  This is really only useful
for nested loops.  For example:

    foreach my $state (@states) {
       $template->clearLoop("cities");
       foreach my $city (@{$state->{cities}}) {
          $template->addLoop("cities", 
                             city => $city->{name},
                             pop => $city->{population});
       }
       $template->addLoop("state", state => $state->{name});
    }

=cut

sub clearLoop
{
   my $self = shift;
   my $loopname = shift;

   $self->{params}->{$loopname} = "";
   return $self;
}
#==============================

=item setLoop LOOPNAME, HASHREF | KEY => VALUE, ...

Exactly like addLoop above, except it clears the loop first.  This is
useful for the first element of a nested loop.

=cut

sub setLoop
{
   my $self = shift;
   my $loopname = shift;

   $self->clearLoop($loopname);
   return $self->addLoop($loopname, @_);
}
#==============================

=item study

Takes a moment to analyze the template to see if any time can be
gained by skipping unused portions of the replacement syntax.  This is
obviously more useful for templates that are replaced often, like
loops.

Implementation note as of v0.77: In practice this rarely helps except
on large, simplistic templates.  Hopefully this will improve in the
future.

=cut

sub study
{
   my $self = shift;
 
   return undef if (!$self->{content});
   return undef if (!defined $self->{content}->{string});
   #study $self->{content}->{string};
   my $re_hash = $self->{patterns};
   my $content = $self->{content};
   foreach my $key ("if", "unless", "ifunless")
   {
      next if (!$re_hash->{$key});
      next if ($content->{skip}->{$key}); # for loops
      if ($content->{string} !~ /$$re_hash{$key}/)
      {
         $content->{skip}->{$key} = 1;
      }
   }

   my $i = 0;
   foreach my $re (@{$re_hash->{vars}})
   {
      my $key = "vars".++$i;
      next if ($content->{skip}->{$key}); # for loops
      if ($content->{string} !~ /$re/)
      {
         $content->{skip}->{$key} = 1;
      }
   }

   $content->{skip}->{cond} = 1 if (($content->{skip}->{if} &&
                                     $content->{skip}->{unless}) ||
                                    $content->{skip}->{ifunless});
   $content->{studied} = 1;
   return $self;
}
#==============================

=item addParams [HASHREF | KEY => VALUE], ...

Specify the search/replace dictionary for the template.  The arguments
can either be key value pairs, or hash references (it is permitted to
mix the two as of v0.71 of this library).  For example:

    my %hash = (name => "chris", age => 30);
    $tmpl1->addParams(%hash);
    
    my $hashref = \%hash;
    $tmpl2->addParams($hashref);

Returns false if the hash has an uneven number of arguments, or the
argument is not a hash reference.  Returns the object otherwise.

Note: this I<appends> to the parameter list.  To replace the list, use
the setParams method instead.

=cut

sub addParams
{
   my $self = shift;
   # additional arguments processed below


   # store everything up in a temp hash so we can detect errors and
   # quit before applying these params to the object.
   my %params = ();

   while (@_ > 0)
   {
      if (!defined $_[0])
      {
         &carp("Undefined key in the parameter list");
         return undef;
      }
      elsif (ref($_[0]))
      {
         my $ref = shift;
         if (ref($ref) =~ /^(?:SCALAR|ARRAY|CODE)$/)
         {
            &carp("Parameter list has a reference that is not a hash reference");
            return undef;
         }
         %params = (%params, %$ref);
      }
      elsif (@_ == 1)
      {
         &carp("Uneven number of arguments in key/value pair list");
         return undef;
      }
      else
      {
         # get a key value pair
         my $key = shift;
         $params{$key} = shift;
      }
   }

   foreach my $key (keys %params)
   {
      $self->{params}->{$key} = $params{$key};
   }
   return $self;
}
#==============================

=item setParams HASHREF | KEY => VALUE, ...

Exactly like addParams above, except it clears the parameter list first.

=cut

sub setParams
{
   my $self = shift;
   
   $self->{params} = {};
   return $self->addParams(@_);
}
#==============================

# PRIVATE FUNCTION
sub _preparse
{
   my $self = shift;

   my $content = $self->{content};
   return $self if ($content->{parsed});

   $content->{skip} = {};
   $content->{studied} = 0;
   $content->{loops} = {};
   $content->{loop_cache} = {};
   $content->{staticparams} = {};

   # Retrieve constant parameters set in the template files
   my $static_re = $self->{patterns}->{staticvars};
   $content->{string} =~ s/$static_re/$$content{staticparams}{$1}=$2; ""/ge;

   # Break up all loops
   my $re1 = $self->{patterns}->{loopstart};
   my $re2 = $self->{patterns}->{loopend};
   my ($start,$end) = split /\$1/, $self->{patterns}->{loop_out}, 2;
   my @parts = split /$re1/, $content->{string};
   while (@parts > 2) {
      my $tail = pop @parts;
      my $name = pop @parts;
      if ($tail =~ s/^(.*?)$re2/$start$name$end/s)
      {
         $content->{loops}->{$name} = $1;
      }
      else
      {
         warn "Found loop start for '$name' but no loop end";         
      }
      $parts[$#parts] .= $tail;
   }
   $content->{string} = $parts[0];
   $content->{parsed} = 1;

   return $self;
}
#==============================

# PRIVATE FUNCTION
sub _fetchfile
{
   my $self = shift;
   my $filename = shift;

   my $cache;
   if ($self->{use_cache})
   {
      my $pkg = ref($self);
      $global_filecache{$pkg} ||= {};
      $cache = $global_filecache{$pkg};
   }
   
   if ($self->{use_cache} && exists $cache->{$filename} &&
       $cache->{$filename}->{time} >= (stat($filename))[9])
   {
      return $cache->{$filename};
   }
   else
   {
      my $struct = {
         studied => 0,
         skip => {},
      };
      local *FILE;
      if (!open(FILE, $filename))
      {
         &carp("Failed to open file '$filename': $!");
         return undef;
      }
      local $/ = undef;
      $struct->{string} = <FILE>;
      close(FILE);

      if ($self->{include_files})
      {
         # Recursively add included files -- must be in the same directory
         my $dir = $filename;
         $dir =~ s,/[^/]+$,,;  # remove filename
         $dir .= "/" if ($dir =~ /[^\/]$/);
         my $re = $self->{patterns}->{include};
         $struct->{string} =~ s/$re/ $self->_fetchfile("$dir$1")->{string} /ge;
      }

      if ($self->{use_cache})
      {
         $struct->{time} = (stat($filename))[9];
         $cache->{$filename} = $struct;
      }
      return $struct;
   }
}

#==============================

=item toString

Executes the search/replace and returns the content.

=cut

sub toString
{
   my $self = shift;

   return "" unless ($self->{content});
   my $content = $self->{content}->{string};
   return "" unless (defined $content);

   my $re_hash = $self->{patterns};
   my $skip = $self->{content}->{skip};
   {
      # Turn off warnings, since it is likely that some parameters
      # will be undefined
      no warnings;

      # incoming params can override template params
      my %params = (
         "__filename__" => $self->{filename},
         %{$self->{content}->{staticparams}},
         %{$self->{params}},
      );

      unless ($skip->{cond})
      {
         # Do the following multiple times to handle nested conditionals

         if ($re_hash->{if} && $re_hash->{unless}) # legacy subclassing
         {

            &carp("DEPRECATED: please use 'ifunless' instead of 'if' and 'unless'\n" .
                  "in your patterns.  There was a subtle bug in the old way, and\n" .
                  "the new way is too slow with 'if' and 'unless'\n");

            my $pos = 1;
            my $neg = 1;
            do {
               if ($neg)
               {
                  $neg = ($content =~ s/$$re_hash{unless}/(!$params{$1}) ? $2 : ''/ge);
               }
               if ($pos)
               {
                  $pos = ($content =~ s/$$re_hash{if}/$params{$1} ? $2 : ''/ge);
               }
            } while ($neg || $pos);
         }
         else
         {
            do {} while ($content =~ s/$$re_hash{ifunless}/
                                       my($bool,$var,$body)=($1,$2,$3);
                                       ($bool =~ m,$$re_hash{ifunless_test}, ? !$params{$var} : $params{$var}) ? $body : ''
                                      /gse);
         }
      }

      my $i = 0;
      foreach my $re (@{$re_hash->{vars}})
      {
         next if ($skip->{"vars".++$i});
         $content =~ s/$re/$params{$1}/g;
      }
   }

   return $content;
}

#==============================

=item print

=item print FILEHANDLE

Sends the replaced content to the currently selected output (usually
STDOUT) or the supplied filehandle.

=cut

sub print
{
   my $self = shift;
   my $filehandle = shift;

   my $content = $self->toString();
   return undef if (!defined $content);

   if ($filehandle)
   {
      print $filehandle $content;
   }
   else
   {
      print $content;
   }
   return $self;
}
#==============================

1;
__END__

=back

=head1 TEMPLATE SYNTAX

The template syntax has four primary purposes: 1) to merge template
files (i.e. include standard headers, footers, etc., 2) to mark blanks
in the template that need to be filled with strings from the program,
3) to indicate optional sections of the template which are shown or
not shown, 4) to produce similar, repeated sections (like table rows),
and


=head2 Subtemplates

To include another file in your template, use this notation:

  <!-- include template="file.tmpl" -->

This causes "file.tmpl" to be slurped into the template before any
further processing occurs.  Subtemplates are allowed to slurp in their
own subtemplates too, but make sure that a file does not attempt to
include itself!  A subtemplate can even be included in multiple
places.  For example:

  <html>
  <body>
  <!-- Top nav -->
  <!-- include template="nav.tmpl" -->
  
  ...  blah blah ...
  
  <!-- Bottom nav -->
  <!-- include template="nav.tmpl" -->
  </body>
  </html>

=head2 String Replacement

To search and replace strings, use one of these three tag descriptions:

   ::var::
   <!-- ::var:: -->
   ;;var;;

The first is the normal syntax.  The second alternative is nice if you
want to view the raw template, so the "::" part doesn't show in your
browser.  The last was a workaround for Mac Dreamweaver which mangled
":" characters sometimes, but is now rarely used.

For example, if your template looks like this:

  Hello, <!--::fname::--> ::lname::!  Today is ;;day;;.

then your output will be:

  Hello, Chris Dolan!  Today is Friday.

if your code has this command:

  $template->setParams(fname => "Chris", lname => "Dolan", day => "Friday");

Another form of string replacement is one that is set in the template
itself.  The syntax for this is:

  ::var==some arbitrary string of text::

This is useful particularly for included subtemplates, or for phrases
that are repeated often.  In the following example, the table cell
color is hard-coded at the top of the template where it can be easily
changed:

  ::oddcolor==#AAAAAA:: ::evencolor==#FFFFFF::
  <html><body>
  <table>
  <tr><td bgcolor="::oddcolor::">one</td></tr>
  <tr><td bgcolor="::evencolor::">two</td></tr>
  <tr><td bgcolor="::oddcolor::">three</td></tr>
  <tr><td bgcolor="::evencolor::">four</td></tr>
  </table>
  </body></html>

The value portion of this tag can be any string on one line, as long
as it is less than 80 characters and does not contain "::".  These
hard-coded parameters can be overridden by parameters of the same name
set with addParams().  However setParams() does NOT clear the
hard-coded parameters, unlike the parameters set in the Perl code.

=head2 Conditional Blocks

Conditional sections of a template are either shown or not shown
depending on the state of a boolean parameter.  A parameter is true or
false just as Perl variables are true or false: undef, "" and 0 are
false; everything else is true.  Conditional blocks are marked by the
following codes:

   ??var?? Some text to display... ??var??
   ??!var?? Some text to display... ??!var??

The first type is shown if "var" is true and not shown if "var" is
false.  The second type is the opposite: show if false, not shown if
true.  Think of them as "if" and "unless" blocks, respectively.

These blocks are highly flexible.  They can span mutliple lines and
can be nested within each other.

For example, this template:

  Hello ??male??Mr.??male????!male??Ms.??!male?? ::lname::!

produces these:

  Hello Mr. Dolan!
  Hello Ms. Smith!

for these parameters, respectively:

  $template->setParams(male => 1, lname => "Dolan");
  $template->setParams(lname => "Smith");

=head2 Repetition

Often in templates you wish to print a list of data.  In this case,
you indicate one instance of this in a <CAM_loop> tag and use the
addLoop() method to replicate it.  The syntax is:

  <CAM_loop name="var"> ... </CAM_loop>

Note that "CAM_loop" is case insensitive, so you can write it as
<cam_loop> if you like.  For more detail see the documentation for the
addLoop() method above.

=head2 Example

Here is an example template using most of the above syntax:

  ::title==Example Template::
  <html>
  <head> <title>::title::</title> </head>
  <body>
    <h1>::title::</h1>
    <!-- include template="nav.tmpl" -->
    
    ??name?? <b> Welcome, ::name::! ??name??
    ??!name?? Nice to meet you. ??!name??
    
    ??data??
      <table>
      <tr><th>Height</th><th>Weight</th></tr>
      <CAM_loop name="data">
        <tr>
          ??height??  <td>::height::</td>  ??height??
          ??!height?? <td>(no height)</td> ??!height??
          ??weight??  <td>::weight::</td>  ??weight??
          ??!weight?? <td>(no weight)</td> ??!weight??
        </tr>
      </CAM_loop>
      </table>
    ??data??
    ??!data??
      Sorry, there is no data to show right now.
    ??!data??
  </body>
  </html>

and here is a filled in example of that template, exactly as it would
appear for the following code.

  $tmpl->setParams(name => "Chris");
  $tmpl->addLoop(height => "72", weight => 200);
  $tmpl->addLoop(height => "69", weight => undef);
  $tmpl->addLoop(height => "", weight => 150);
  $tmpl->print();

  <html>
  <head> <title>Example Template</title> </head>
  <body>
    <h1>Example Template</h1>
    <a href="../index.html">Back to home</a>
    
    <b> Welcome, Chris! 
    
    
    
      <table>
      <tr><th>Height</th><th>Weight</th></tr>
      
        <tr>
            <td>72</td>  
          
            <td>200</td>  
          
        </tr>
      
        <tr>
            <td>69</td>  
          
            <td>(no weight)</td>  
          
        </tr>
      
        <tr>
            <td>(no height)</td>  
          
            <td>150</td>  
          
        </tr>
      
      </table>
    
    
  </body>
  </html>

=head1 AUTHOR

Clotho Advanced Media, Inc. I<cpan@clotho.com>

Primary developer: Chris Dolan
