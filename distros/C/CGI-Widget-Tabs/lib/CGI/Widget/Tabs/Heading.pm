=head1 NAME

CGI::Widget::Tabs::Heading - Create OO tab headings for CGI::Widget::Tabs objects


=head1 SYNOPSIS

None.


=head1 DESCRIPTION

This module is designed to work with CGI::Widget::Tabs. You can not use this module
in a standalone fashion. Look at the CGI::Widget::Tabs documentation for more info.

=head1 PUBLIC INTERFACE

=head2 Public Class Interface

=cut


package CGI::Widget::Tabs::Heading;


# pragmata
use strict;
use vars qw/$VERSION/;
# Standard Perl Library and CPAN modules
use HTML::Entities;

$VERSION = "1.00";

=head3 new

  new($proto)

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->raw(0);  # by default text is HTML escaped
    return $self;
}


=head2 Public Object Interface

These methods define the properties and behaviour of the object oriented
headings. Each OO heading can be tailored to specific requirements. Fresh new
OO headings are created by using the heading() method on a CGI::Widget::Tabs
object. Existing OO headings are returned by the headings() method. In the
tabs-demo.pl file OO headings are used as well. So look at that demo for a
real life example. Example:

    # create, append and return a new heading
    my $h = $tab->heading();

    # focus on the third heading
    my $h = ($tab->headings)[2];


The properties and behaviour of an OO heading can be set with the following
methods:

=head3 class

 class(STRING)

Overrides the widget's CSS class for this heading. This is useful if you have
a specific heading (e.g. "Maintenance") which always needs it's own private
mark up. If the optional argument STRING is given, the class for this heading
is set. Otherwise it is retrieved.

=cut

sub class {
    #
    # Specific heading class overriding the default widget class
    #
    my $self = shift;
    if ( @_ ) {
        $self->{class} = shift;
    }
    return $self->{class};
}

=head3 key

 key(STRING)

Sets/returns the value to use for this heading in the CGI query param list.
This is similar to the use of keys in key/value pairs in the headings()
method. The goal is to simplify programming logic and shorten the URL's. (See
the headings() method  elsewhere in this document for further explanation).
Example:

    # display the full heading...
    # ...but use a small key as query param value
    $h->text("Remote Configurations");
    $h->key("rc");

In contrast to the use of key/value pairs, CGI::Widget::Tabs knows that this
is a key and not a value. After all, you are using the key() method, right?
Consequently you don't need the prepend the key with a hyphen ("-"). You may
consider using a hyphen for your keys nevertheless. It will lead to more
transparent code. Observe how the snippet from above with a prepended "-"
will later on result in the following check:

    if ( $tab->active eq "-rc" ) {  # clearly we are using keys ....

Consider this a mild suggestion.

=cut

sub key {
    #
    # The key to identify this heading with
    #
    my $self = shift;
    if ( @_ ) {
        $self->{key} = shift;
    }
    return $self->{key};
}


=head3 raw

 raw(BOOLEAN)

The heading text will normally be HTML encoded. If you wish you can use
hard coded HTML. To avoid escaping this HTML, you need to set raw() to a
logical TRUE. This is usually a 1 (one). Setting it to FALSE (usually a 0)
will re-enable HTML encoding. The optional argument BOOLEAN can be any
argument evaluating to a logical value. Setting raw() will not take effect
until the widget is rendered. So it does not matter when you set it, as long
as you haven't rendered the widget. Examples:

    # HTML encoded
    $h1->text("Names A > L");
    $h2->text("Names M < Z");

    # Raw
    $h1->text("Names A &gt; L");
    $h1->raw(1);

    $h2->text("Names M &lt; Z");
    $h2->raw(1);

    # get the encoding setting of the fourth element
    my $h = ($tab->headings)[3];
    my $raw = $h->raw;


=cut

sub raw {
    #
    # Raw or HTML escaped?
    #
    my $self = shift;
    my $arg = shift;

    if ( defined $arg ) {
        $self->{raw} =  $arg ? 1 : 0;
    }
    return $self->{raw};
}


=head3 text

 text(STRING)

Sets/returns the heading text. If the optional argument STRING is given, the
text will be set otherwise it will be returned. The heading text will be HTML
encoded unless explicitely told otherwise (see: raw()). Examples:

    # set heading text for the first two headings
    ($tab->headings)[0]->text("Names A > L");
    ($tab->headings)[1]->text("Names M < Z");

    # get the text of the 4th heading
    my $text = ($tab->headings)[3]->text;


=cut

sub text {
    #
    # Text to be displayed
    #
    my $self = shift;
    my $text;

    if ( @_ ) {
        $self->{text} = shift;
    }
    if ( $self->raw ) {
        $text = $self->{text};
    } else {
        $text = HTML::Entities::encode_entities( $self->{text} );
    }
    return $text;
}


=head3 url

 url(STRING)

Overrides the self referencing URL for this heading. If the optional argument
STRING is given the URL is set. Otherwise it is returned. The URL is used
exactly as given. This means that any query params and values need to be
added explicitely. If a URL is not set, the heading will get a default self
referencing URL. For trivial applications, you will mostly be using this one.
Note that generating the self referencing URL will be delayed until the tab
widget it rendered. This means it will not be returned by the url() method.
Example:

      $h->url("www.someremotesite.com");  # go somewhere else

      my $url = $h->url;                  # return the URL

=cut

sub url {
    #
    # The redirect URL where this tab heading points to
    #
    my $self = shift;
    if ( @_ ) {
        $self->{url} = shift;
    }
    return $self->{url};
}





1;

__END__

