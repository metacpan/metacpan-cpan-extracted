=head1 MODULE FOR SALE

I am not planning to make any changes to this module as I have not had to use
it in any projects of my own for the last couple of years. I am aware that
others are using it.

If anyone would like to to take over maintenance/development of this module
pleas get in touch.

=head1 NAME

CGI::Widget::Tabs - Create tab widgets in HTML

=head1 SYNOPSIS

    use CGI::Widget::Tabs;
    my $tab = CGI::Widget::Tabs->new;

    use CGI;
    my $cgi = CGI->new;            # interface to the query params

    $tab->headings(@titles);       # e.g. qw/Drivers Cars Courses/
    $tab->default("Courses");      # the default active tab
    $tab->force_active("Courses"); # forceably make this the active tab
    $tab->active;                  # the currently active tab
    $tab->class("my_tab");         # the CSS class to use for markup
    $tab->cgi_object($cgi);        # the object holding the query params
    $tab->cgi_param("t");          # the CGI query parameter to use
    $tab->drop_params("ays");      # do NOT pass on "Are You Sure?" answers
    $tab->wrap(4);                 # wrap after 4 headings...
    $tab->indent(1);               # ...and add indentation
    $tab->render;                  # the resulting HTML code
    $tab->display;                 # same as `print $tab->render'


    $h = $tab->heading;               # new OO heading for this tab
    $h->text("TV Listings");          # heading text
    $h->key("tv");                    # key identifying this heading
    $h->raw(1);                       # switch off HTML encoding
    $h->url("whatsontonight.com");    # redirect URL for this heading
    $h->class("red");                 # this heading has it's own class

    # See the EXAMPLE section for a complete example

=head1 DESCRIPTION

=head2 Introduction

CGI::Widget::Tabs lets you simulate tab widgets in HTML. You could benefit
from a tab widget if you want to serve only one page. Depending on the tab
selected you fetch and display the underlying data. There are three main
reasons for taking this approach:

1. For the end user not to be directed to YAL or YAP (yet another link / yet
another page), but keep it all together: The single point of entry paradigm.

2. As a consequence the end user deals with a more consistent and integrated
GUI. This will give a better "situational awareness" within the application.

3. For the Perl hacker to handle multiple related data sources within the
same script environment.


As an example the following tabs could be used on a web page for someone's
spotting hobby:

      __________      __________      __________
     /  Planes  \    /  Trains  \    / Classics \
------------------------------------------------------
         _________
        /  Bikes  \
------------------------

As you can see, the headings wrap at three and a small indentation is added
to the start of the next row. The nice thing about CGI::Widget::Tabs is that
the tabs know their internal state. So you can ask a tab for instance which
heading has been clicked by the user. This way you get instant feedback.

=head2 "Hey Gorgeous!"

Of course tabs are useless if you can't "see" them. Without proper make up
they print as ordinary text. So you really need to fancy them up with some
eye candy. The designed way is that you provide a CSS style sheet and have
CGI::Widget::Tabs use that. See the class() method for how to do this.


=head1 EXAMPLE

Before digging into the API and all accessor methods, this example will
illustrate how to implement the spotting page from above. So you have
something to start with. It will give you enough clues to get on the road
quickly. The following code is a simple but complete example. Copy it and run
it through the webservers CGI engine. (For a even more complete and useful
demo with multiple tabs, see the file tabs-demo.pl in the CGI::Widget::Tabs
installation directory.) To fully appreciate it, it would be best to run it
in a performance environment, like mod_perl or SpeedyCGI.

    #! /usr/bin/perl -w

    use CGI::Widget::Tabs;
    use CGI;

    print <<EOT;
    Content-Type: text/html;

    <head>
    <style type="text/css">
    table.tab   { border-bottom: solid thin #C0D4E6; text-align: center }
    td.tab      { padding: 2 12 2 12; width: 80; background-color: #FAFAD2 }
    td.tab_actv { padding: 2 12 2 12; width: 80; background-color: #C0D4E6 }
    td.tab_spc  { width: 5 }
    td.tab_ind  { width: 15 }
    </style></head>
    <body>
    EOT

    my $cgi = CGI->new;
    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->headings( qw/Planes Traines Classics Bikes/ );
    $tab->wrap(3);
    # $tab->wrap(1);    # |uncomment to see the effect of
    # $tab->indent(0);  # |wrapping at 1 without indentation
    $tab->default("Traines");
    $tab->display;
    print "<br>We now should run some intelligent code ";
    print "to process <strong>", $tab->active, "</strong><br>";
    print "</body></html>";

=head1 PUBLIC INTERFACE


=cut

package CGI::Widget::Tabs;


# pragmata
use strict;
use vars qw/$VERSION/;

# Standard Perl Library and CPAN modules
use Carp;
use URI::Escape();
use HTML::Entities();

# CGI::Widget::Tabs modules
use CGI::Widget::Tabs::Heading;


$VERSION = "1.14";



=head2 Public Class Interface

=head3 new

  new()

Creates and  returns a new  CGI::Widget::Tabs  object. new()  does  not take any
arguments.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->indent(1);
    return $self;
}


=head2 Public Object Interface

=head3 active

 active()

Returns a string indicating the current active tab heading. This is (in order of
precedence) the heading set by force_active(), the heading being clicked on, the
default heading, or the first in  the list. The string  value will either be the
heading key or the heading text, depending on if you chose to use keys. Example:

    if ( $tab->active() eq "Trains" ) {  # heading text only

    if ( $tab->active() eq "-t" ) {      # key value ISO heading text

=cut

sub active {

    #
    # Returns the active heading. In order of precendence:
    # 1. A mandatory heading
    # 2. The heading clicked by the user
    # 3. The default heading
    # 4. The first heading in the list
    #
    my $self = shift;
    my $active;

    # 1. Heading clicked
    # 1. Mandatory heading
    $active = $self->force_active();
    return $active if defined $active;

    # 2. Heading clicked
    $active = $self->cgi_object->param($self->cgi_param);
    return $active if defined $active;

    # 3. Default
    $active = $self->default;
    return $active if defined $active;

    # 4. First
    my $h = ($self->headings)[0];  # headings are always OO objects
    return $h->key || $h->text;
}

=head3 cgi_object

 cgi_object(OBJECT)

Sets/returns the CGI or CGI::Minimal object. If the  optional argument OBJECT is
given, the CGI object is set,  otherwise it is returned.  CGI::Widget::Tabs uses
this object internally to process the CGI query parameters. If  you want you can
use some other CGI object handler. However such an object handler must provide a
param() method with corresponding behaviour as do CGI or CGI::Minimal. Note that
currently only CGI and CGI::Minimal have been tested. Example:

    # set
    my $cgi = CGI::Minimal->new;
    $tab->cgi_object($cgi);

    # get
    my $cgi = $tab->cgi_object;

=cut

sub cgi_object {

    #
    # The cgi object to retrieve the parameters from.
    # Could be a CGI object or a CGI::Minimal object.
    #
    my $self = shift;
    my $cgi = shift;
    if ( $cgi ) {
        if ( ref $cgi ne "CGI" and ref $cgi ne "CGI::Minimal") {
            carp "Warning: Expected CGI or CGI::Minimal object";
        }
        $self->{cgi_object} = $cgi;
    }
    return $self->{cgi_object};
}

=head3 cgi_param

  cgi_param(STRING)

Sets/returns the CGI query  parameter. This parameter  identifies the tab in the
CGI query string (the funny part  of the URL  with the ?  = & # characters).  If
the optional argument STRING is given, the query parameter is set.  Otherwise it
is returned. Usually  you  can leave this   untouched. In that case the  default
parameter "tab" is used. You  will need to  set this if  you have more CGI query
parameters on  the URL with "tab" already  being taken. Another  situation is if
you use multiple tab widgets on one  page. They both  would use "tab" by default
causing conflicts. Example:

   # Lets paint a fruit tab and a vegetable tab
   my $fruits_tab = CGI::Widget::Tabs->new;
   my $vegies_tab = CGI::Widget::Tabs->new;

   # this is our link with the outside world
   my $cgi = CGI::Minimal->new;
   $fruits_tab->cgi_object($cgi);
   $vegies_tab->cgi_object($cgi);

   # In the CGI params collection the first is
   # identified by 'ft' and the second by 'vt'
   $fruits_tab->cgi_param("ft");
   $vegies_tab->cgi_param("vt");

=cut

sub cgi_param {

    #
    # CGI parameter specifing the tab. Defaults to "tab".
    #
    my $self = shift;
    if ( @_ ) {
        $self->{cgi_param} = shift;
    }
    return $self->{cgi_param} || "tab";
}

=head3 drop_params

  drop_params(LIST)

Sets/retrieves  the list of  CGI parameters   to be  dropped from  the parameter
list.  If the optional argument  LIST is given the  list is set, otherwise it is
retrieved. Suppose you have clicked "Yes" to some "Are  you sure?" question. You
certainly want that question  to be asked  every time, right? Especially  if the
actions that go with it  are destructive.  If you did  NOT specify the parameter
to be dropped,  "Yes"  would have  been  silently  passed  on to  the  parameter
list. That would effectively preset "Are you sure" with "Yes" causing disastrous
results. Examples:

    $tab->drop_params("ays");  # drop the "Are you sure" param

=cut

sub drop_params {

    #
    # These parameters should not be passed on.
    #
    my $self = shift;
    if ( @_ ) {
        $self->{drop_params} = [@_];
    }
    return @{ $self->{drop_params} || [] };
}



=head3 class

  class(STRING)

Sets/returns the name of the CSS class used for the tabs markup. If the optional
argument STRING is given  the class is set,  otherwise  it is returned.   If not
set, the widget will   be based on the  class  "tab". In the  accompanying style
sheet, there are five class elements you need to provide:

=over 4

=item 1. A table element for containment of the entire tab widget

=item 2. A td element for a normal tab

=item 3. A td element for the active tab

=item 4. A td element for the spacers

=item 5. A td element for the indentation (if needed)

=back

The  class names of   these  elements are  directly  borrowed  from  the class()
method. The td elements for the active tab, the spacers and the indentations are
suffixed with  "_actv", "_spc" and  "_ind" respectively. For  instance, if you'd
run

    $tab->class("my_tab");

then the elements look like:

    <table class="my_tab">    # the entire table
    <td class="my_tab">       # normal tab
    <td class="my_tab_actv">  # active tab
    <td class="my_tab_spc">   # spacer
    <td class="my_tab_ind">   # indentation

If you    don't wrap headings,   then ofcourse  you won't   need  to specify the
indentation td's. By the way, the indentation will usually  look most natural if
it has the same width as the spacers or a multiple thereof.  Look at the example
in the EXAMPLE section to see how this all works out.

=cut

sub class {

    #
    # The CSS class for display of the tabs
    # Defaults to 'tab'.
    #
    my $self = shift;
    if ( @_ ) {
        $self->{class} = shift;
    }
    return $self->{class} || "tab";
}


=head3 default

 default(STRING)

Overrides which heading is the default. Normally CGI::Widget::Tabs will make the
first  heading  active. Use the  default() method  if you   want to deviate from
this. The optional argument STRING must either be the heading key or the heading
text, depending on how you chose to initialize the headings. Example:

    # Make the "Trains" heading the default active one.
    $tab->default("Trains");

    # ...or perhaps...
    $tab->default("-t");

=cut

sub default {

    #
    # The default active heading
    #
    my $self = shift;
    if ( @_ ) {
        $self->{default} = shift;
    }
    return $self->{default}
}

=head3 display

  display()

Renders the tab widget   and prints the resulting HTML   to the  default  output
handle (usually STDOUT). Example:


    $tab->display;       # this is the same as...

    print $tab->render;  # ...but saves a few keystrokes

See also the render() method.

=cut

sub display {

    #
    # save a few keystrokes
    #
    my $self = shift;
    print $self->render;
}



=head3 force_active

 force_active(STRING)

Forces the activation of a specific tab identified by it's heading text
or key. This is useful if you have an application which must show a
certain tab after doing someting. Or if you're paranoid and you've been
given a CGI query string which you don't trust. In both cases you can
make sure the tab of your preference is activated. Example:

    $tab->force_active("Trains");  # heading text only

    $tab->force_active("-t");      # key

    $tab->force_active(undef);     # forget all about it


=cut

sub force_active {

    #
    # Activates a heading. Takes heading text, key or undef.
    #
    my $self = shift;
    if ( @_ ) {
        $self->{force_active} = shift;
    }
    return $self->{force_active};
}



=head3 heading

  heading()

Creates, appends and returns a  new heading. The return  value will always be an
OO heading object. Example:

    my $h = $tab->heading();

In general you will  use OO headings if  the  headings() method is  not flexible
enough. For trivial applications the  headings() method mostly suffices. Look at
section PROPERTIES OF OO HEADINGS for more information on OO headings.

=cut

sub heading {

    #
    # Create, add, and return a new heading object
    #
    my $self = shift;
    my $h = CGI::Widget::Tabs::Heading->new();
    push @{ $self->{headings} }, $h;
    return $h;
}

=head3 headings

  headings(LIST)

Sets/returns the tab headings. Without arguments  the currently defined headings
are  returned. If no  headings  are  defined, the empty   list is  returned. Any
returned heading  will  always be an OO  heading,  regardless of if and  how the
initializing LIST argument  is used. Look at section  PROPERTIES OF OO  HEADINGS
for more info on how to deal with OO headings.

The optional LIST argument   is a short-cut  to  the OO headings interface.  The
elements  of LIST can take  various forms. Let's take  a moment  to take a close
look at  the headings of a  tab. Tab headings are the   things that --from human
perspective-- identify a tab page. Observe the spotting  example above. Here the
different tab pages are identified by the strings "Planes", "Trains", "Classics"
and "Bikes". They form the heading for each seperate tab.  The LIST elements can
be used to preset these tab headings.

An element of LIST can be any one of:

=over 4

=item * a string. E.g.:

    qw/Planes Trains Classics Bikes/

This is the simplest initializer. In the spotting example the four tabs headings
are  easily created   by  feeding  these words   as  a list  to  the  headings()
method. And  then you are almost  done: the headings  can be displayed  and each
heading gets it's own self referencing URL.

=item * a key/value pair. E.g.:

    ( -p => "Planes",
      -t => "Trains",
      -c => "Classics,
      -b => "Bikes" )

For trivial CGI::Widget::Tabs applications, the k/v pairs  are the ones you will
probably use the most.  They come in  handy because you don't  need to check the
value returned by active()  against very long  words. Even better, if you change
the tab headings (upper/lower case, typo's) but use the same keys you don't need
to change your code. So it is less  error prone. As a  pleasant side effect, the
URL's  get to  be significantly  shorter.  Do notice that  the keys  want  to be
unique. Keys in a k/v list are not at all magical. You can choose any string you
like with the provision that they start with the '-' (hyphen) sign. The starting
'-' of a list entry is what triggers  CGI::Widget::Tabs to decide  this is a k/v
entry. Single or dual character strings tend to be the most convenient keys.

=item * a hash

This use of the headings() method will clutter  up your code.  The hash tries to
mimic and encapsulate all OO accessor methods. If think  you need an initializer
hash, you probably want OO headings.  Use it only if you  must. If you can stick
with the  strings or  k/v  pairs.  That said,  the   hash  keys are  the   named
equivalents of the OO heading properties. E.g.:

    ( { text  => "Planes",
        key   => "p",
        url   => "www.aviation-mag.com",
        class => "heavens_blue",
        raw   => 0 },

=back

You can   mix  these types  in   any way you   like. The  various  types will be
translated on  the fly to  OO headings and  then processed.  Thus you can safely
say:

    $tab->headings( "Plaines",
                    -t => "Traines",
                    { text => "Classics",
                      key  => "c",
                      ... } )

Just as the hash initializer, this use does clutter up your  code. The reason is
that different concepts  of information are  piled up on  one big heep. You will
need to  scrutinize the code  to understand what it  is going on. Although it is
supported you should refrain yourself from making use of these combinations.

As  a summary,  here  are a  three  examples  of the headings()   method for the
spotting page.

    # Example 1: Set the headings with a list of strings
    my $tab = CGI::Widget::Tabs->new();
    $tab->headings( qw/Planes Trains Classics Bikes/ );

    # Example 2: Set the headings with a list of k/v pairs
    my $tab = CGI::Widget::Tabs->new();
    $tab->headings( -p => "Planes",
                    -t => "Trains",
                    -c => "Classics,
                    -b => "Bikes" );

    # Example 3: Isolate the "Classics" heading
    my $h = ($tab->headings)[2];

Note that these few statements provide almost enough  logic to generate the HTML
for the tab widget!

=cut

sub headings {

    #  Takes optional user defined simple headings as arguments,
    #  which  will be transformed into OO headings. E.g.:
    #  ( "Software", -hw => "Hardware", { text => "Wetware", key => "ww" } )
    #
    my $self = shift;
    if ( @_ ) {  # any arguments?

        my $h;   # OO heading
        my $ht;  # _heading _text

        HEADING: while ( my $arg = shift @_ ) {
            $h = $self->heading();  # add a new heading

            if ( ! ref $arg ) {  # Not a hash initializer
                # -- k/v pair
                ( $arg =~ /^-/ ) && do {
                    $h->key($arg);
                    $h->text(shift @_);
                    next HEADING;
                };

                # -- text only
                $h->text($arg);
                next HEADING;
            }

            # -- hash initializer
            ( ref($arg) eq "HASH" ) && do {
                if ( ! $arg->{text} ) {
                    croak "Hash initializer is missing mandatory text element";
                }

                $h->text($arg->{text});
                if ( exists( $arg->{key} )   && $arg->{key} )   { $h->key( $arg->{key} ) }
                if ( exists( $arg->{url} )   && $arg->{url} )   { $h->url(  $arg->{url} ) }
                if ( exists( $arg->{raw} )   && $arg->{raw} )   { $h->raw(  $arg->{raw} ) }
                if ( exists( $arg->{class} ) && $arg->{class} ) { $h->class(  $arg->{class} ) }
                next HEADING;
            };

            croak "Unsupported heading type";
            next;
        }
    }
    return @{ $self->{headings} || [] };
}

=head3 indent

  indent(BOOLEAN)

Sets/returns the  indentation setting. Without arguments  the current setting is
returned. indent() specifies if indentation should be added to the next row when
the headings  get wrapped. indent() is  a toggle. By default  indent() is set to
TRUE. You must explicitely  switch it off for  the desired effect.  The optional
argument BOOLEAN can be any argument evaluating to a logical value.

The purpose of swithing off indentation  is to simulate  a vertical menu. In the
spotting example, running

    $tab->wrap(1);
    $tab->indent(0);

would result in something like:

      __________
     |  Planes  |
    --------------
      __________
     |  Trains  |
    --------------
      __________
     | Classics |
    --------------
      __________
     |  Bikes   |
    --------------


You probably need to tweak your style sheet to have it look nicely.

=cut

sub indent {

    #
    # Indentation after wrapping to next line?
    #
    my $self = shift;
    my $arg = shift;

    if ( defined $arg ) {
        $self->{indent} =  $arg ? 1 : 0;
    }
    return $self->{indent};
}


=head3 render

  render()

Renders the tab widget  and returns the resulting HTML  code. This is  useful if
you need to print the tab to a different file handle. Another use is if you want
to manipulate  the HTML. For  instance to insert session id's  or the like.  See
the class() method  and the EXAMPLE section somewhere  else in this document  to
see how you can influence the markup of the tab widget. Example:

    my $html = $tab->render;
    print HTML $html;  # there's a session id filter behind HTML

=cut

sub render {

    #
    # Process the lot and display it.
    #
    my $self        = shift;
    my $cgi         = $self->cgi_object;
    my @headings    = $self->headings;
    my $class       = $self->class;
    my $cgi_param   = $self->cgi_param;
    my $active      = $self->active;
    my $wrap        = $self->wrap;
    my $indent      = $self->indent;
    my $spacer      = qq(<td class="$class).qq(_spc"></td>);
    my $indentation = qq(<td class="$class).qq(_ind"></td>);
    my @html;
    my $url;
    my $query_string_min_min;  # the query string minus the varying tab

    # -- reproduce the CGI query string EXCEPT the varying tab
    my @param_list = grep( $_ ne $cgi_param,$cgi->param() );

    # - From this list remove the wannabe-dropped
    my %drop_params = ();
    foreach ( $self->drop_params() ) { $drop_params{$_} = 1 };
    @param_list = grep (!exists $drop_params{$_}, @param_list);

    if ( @param_list ) {
        $query_string_min_min = join "&", map ( "$_=".URI::Escape::uri_escape($cgi->param($_)||"") , @param_list );
        $query_string_min_min .= "&";
    } else {
        $query_string_min_min = "";
    }


    if ( @headings ) {
        @html = ();
        push @html, "<!-- Generated by CGI::Widget::Tabs v$VERSION -->\n";

        my $heading_nr = 1;  # we're about to render the first heading...
        my $row_nr     = 1;  # ...of the first row
        my $param_value;
        my $h;
        my $url;

        foreach $h ( @headings ) {
            if ( $heading_nr == 1 ) {   # first one in the row?
                push @html, qq(<table class="$class">\n<tr>\n);
                if ( $indent && $row_nr > 1 ) {                     # = print indents if
                    push @html, ( $indentation x ($row_nr - 1));    # = necessary
                }                                                   # =
                push @html, "$spacer\n";  # each row starts with a spacer
            }

            # -- actual headings
            $param_value = $h->key || $h->text;
            if ( defined $h->class() ) {  # heading has local class?
                push @html, qq(<td class=").$h->class.'">';
            } else {
                push @html, qq(<td class="$class);
                push @html, qq(_actv) if $param_value eq $active;
                push @html, qq(">);
            }

            # -- user defined URL or default self ref. URL?
            my $url = $h->url || ( "?$query_string_min_min$cgi_param=".URI::Escape::uri_escape($param_value) );
            push @html, _link( $h->text , $url );
            push @html, "</td>$spacer\n";

            # -- end of row
            if ( $wrap && ( $heading_nr == $wrap ) ) {  # last one on this row?
                push @html, "</tr>\n";     # | yes, end this row
                push @html, "</table>\n";  # |
                $heading_nr = 0;
                $row_nr++;
            }
            $heading_nr++;
        }

        # --- all headings printed
        if ( $heading_nr > 1 )  {      # | We need to end this
            push @html, "</tr>\n";     # | row if it didn't just
            push @html, "</table>\n";  # | get wrapped.
        }
    }

    push @html, "<!-- End CGI::Widget::Tabs v$VERSION -->\n";
    return join("", @html);
}


=head3 wrap

  wrap(NUMBER)

Sets or returns the wrap setting. Without  arguments the current wrap setting is
returned. If the argument NUMBER is given the headings will wrap to the next row
after NUMBER headings. By default headings are not wrapped.

=cut

sub wrap {

    #
    # wrap to next row after this num of headings
    #
    my $self = shift;
    if ( @_ ) {
        $self->{wrap} = shift;
    }
    return $self->{wrap};
}


=head1 INTERNALS

=head2 Private Class Methods

=head3 _link

 link($text, $href)

Returns a HTML 'a' tag pair linking to $href with text $text

=cut

sub _link {

    #
    # Create a link for some text to a href
    # Expects = (<text>,<href>) pair.
    #
    return qq(<a href="$_[1]">$_[0]</a>);
}



1;

__END__


=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 DEPENDENCIES

This module requires these other modules and libraries:

 Carp
 CGI  or  CGI::Minimal or another CGI   "object broker" with   a similar param()
 method
 HTML::Entities
 Test::More
 URI::Escape

Test::More is only required for testing purposes.

This module has these optional dependencies:

 File::Find::Rule
 Pod::Coverage
 Test::Pod (0.95 or higher)
 Test::Signature

These are both just requried for testing purposes.

Also required, a CSS stylesheet for the tabs markup

=head1 TODO

Just because these items are in the todo list, does not  mean they will actually
be done. If you think  one of these would  be helpful say  so - and it will then
move up on my priority list.

=over

=item *

Re work the way Headings work. Do not assume that a  heading wants to be wrapped
into an a href tag. It might be javascript instead

=item *

Provide a hash  lookup as a  replacement mechanism for  $cgi->params() for those
who don't use CGI or CGI::Minimal

=item *

Add support for heading images instead of text

=item *

Consider replacing some/all of  the hand  crafted  get set  methods with use  of
Class::MethodMaker

=item *

Consider using Test::More in 003_main.t

=back

Patches always welcome.

=head1 BUGS

As a side effect, the CGI query parameter to identify the tab (see the
cgi_param() method) is always moved to the end of the query string.

To report a bug  or request an enhancement  use CPAN's  excellent Request
Tracker. 

=head1 CONTRIBUTIONS

I would appreciate receiving your CSS style sheets used for the tabs markup.
Especially if you happened to be professionally concerned with markup and
layout. For techies like us it is not always easy to see what goes and what
doesn't. If you send in a nice one, I will gladly bundle it with the next
release.

=head1 ACKNOWLEDGEMENTS

=over 4

=item Bodo Eing <eingb@uni-muenster.de>

=item Bernie Ledwick <bl@man.fwltech.com>

=item Bernhard Schmalhofer <Bernhard.Schmalhofer@biomax.de>

=back

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in svn.

http://sourceforge.net/projects/sagar-r-shah/

=head1 AUTHOR

Koos Pol E<lt>koos_pol@raketnet.nlE<gt>

=head1 MAINTAINER

Sagar R. Shah

=head1 SEE ALSO

L<CGI>,    L<CGI::Minimal>,    CSS  specs:     L<http://www.w3.org/TR/REC-CSS1>,
L<http://www.w3.org/TR/REC-CSS2>

=cut

=head1 COPYRIGHT

Copyright 2003, Koos Pol, All rights reserved

Copyright 2003-2007, Sagar R. Shah, All rights reserved

This program  is free software; you can  redistribute it  and/or modify it under
the same terms as Perl itself.

=cut
