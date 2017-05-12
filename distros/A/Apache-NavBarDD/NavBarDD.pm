package Apache::NavBarDD;
# file Apache/NavBarDD.pm

use 5.0006;
use strict;
use Apache::Constants qw(:common);
use Apache::File ();
use Apache::URI ();

our $VERSION = '0.75';

my %BARS = ();

# Define default values for the NavBarDD's objects attributes.

# $master_table_atts defines the attributes for the master table.
my $master_table_atts=<<EOF;
CELLSPACING="0" CELLPADDING="1" BORDER="0" WIDTH="600"
EOF

# $vassal_table_atts defines the attributes for the vassal table.
my $vassal_table_atts=<<EOF;
CELLSPACING="0" CELLPADDING="0" BORDER="0" WIDTH="100%" ALIGN="CENTER"
EOF

# $master_padding defines the HTML element to be used between the elements 
# of the master table.
my $master_padding=<<EOF;
<TD BGCOLOR="#FFFFFF" WIDTH="2"><FONT SIZE="2">&nbsp;</FONT></TD>
EOF

# $vassal_padding defines the HTML element to be used between the elements 
# of the vassal table.
my $vassal_padding=<<EOF;
<TD NOWRAP BGCOLOR="#FFFFCC" WIDTH="10">
<FONT SIZE="2" COLOR="#336699">&nbsp;|&nbsp;
</FONT></TD>\n
EOF

# $style defines the HTML style element to be used as a default CSS.
my $style=<<EOF;
<style>

td.master-active {
    height: 2ex;
    font-family: helvetica,arial;
    font-weight: bold;
    font-size: 10pt;
    color: #003366;
    background-color: #FFFFCC;
    text-align: center
}

td.master-normal {
    height: 2ex;
    font-family: helvetica,arial;
    font-size: 10pt;
    color: #FFFFFF;
    background-color: #006633; 
    text-align:center;
}

td.vassal-active {
    height: 4ex; 
    font-family: helvetica,arial; 
    font-size: 7pt; 
    color: #006633; 
    background-color: #FFFFFF;
}

td.vassal-normal {
    height: 4ex; 
    font-family: helvetica, arial; 
    font-size: 7pt; 
    color: #006633; 
    background-color: #FFFFCC; 
}

a.master {
    text-decoration: none;
    color: #FFFFFF;
}

a.vassal {
    text-decoration: none;
    color: #006633;
}

</style>
EOF

# if $bottom the bar is displayed both on the top and on the bottom
# of the page.
my $bottom = 0;

# $depth is the vassal bar's depth down the document hierarchy.
my $depth = 2;

sub handler($$) {
    my ($self, $r) = @_;

    my $bar = $self->read_configuration($r) || return DECLINED;    
    $r->content_type eq 'text/html' || return DECLINED;
    my $fh = Apache::File->new($r->filename) || return DECLINED;

    # the following handle caching; they stand in the way when
    # making changes to the code, so use them wisely

    # $r->update_mtime($bar->modified);
    # $r->set_last_modified;
    # my $rc = $r->meets_conditions;
    # return $rc unless $rc == OK;

    $r->send_http_header;
    return OK if $r->header_only;

    my $before = $self->before;
    my $style = $self->style;
    my $master_table_atts = $self->master_table_atts;
    my $vassal_table_atts = $self->vassal_table_atts;
    my $master_padding = $self->master_padding;
    my $vassal_padding = $self->vassal_padding; 
    my $after = $self->after;

    my $navbar = $self->make_bar($r, $bar);

    local $/ = "";
    while (<$fh>) {
      s:(</HEAD>):$style$1:oi;
      s:(<BODY.*?>):$1$before$navbar$after:osi;
      s:(</BODY.*?>):$navbar$1:osi if $self->bottom;
    } continue {
	$r->print($_);
    }

    return OK;
}

###############################################################################
# constructor                                                                 #
# it constructs the object; N.B.: the object contains the bar, which is       #
# constructed separately                                                      #
###############################################################################

sub new {
    my $class = shift;

    my $self = {
	style => $style,
	master_table_atts => $master_table_atts,
	vassal_table_atts => $vassal_table_atts,
	master_padding => $master_padding,
	vassal_padding => $vassal_padding,
	bottom => $bottom,
	depth => $depth,
	@_, # override previous attributes
    };
    return bless $self, $class;
}

###############################################################################
# accessor/modifier methods                                                   #
###############################################################################

sub style {
    my $self = shift;
    if (@_) { $self->{style} = shift; }
    return $self->{style};
}

sub master_table_atts {
    my $self = shift;
    if (@_) { $self->{master_table_atts} = shift; }
    return $self->{master_table_atts};
}

sub vassal_table_atts {
    my $self = shift;
    if (@_) { $self->{vassal_table_atts} = shift; }
    return $self->{vassal_table_atts};
}

sub master_padding {
    my $self = shift;
    if (@_) { $self->{master_padding} = shift; }
    return $self->{master_padding};
}

sub vassal_padding {
    my $self = shift;
    if (@_) { $self->{vassal_padding} = shift; }
    return $self->{vassal_padding};
}

sub before {
    my $self = shift;
    if (@_) { $self->{before} = shift; }
    return $self->{before};
}

sub after {
    my $self = shift;
    if (@_) { $self->{after} = shift; }
    return $self->{after};
}

sub made {
    my $self = shift;    
    return $self->{made};
}

sub bottom {
    my $self = shift;
    if (@_) { $self->{bottom} = shift; }
    return $self->{bottom};
}

sub depth {
    my $self = shift;
    if (@_) { $self->{depth} = shift; }
    return $self->{depth};
}

###############################################################################
# bar construction methods                                                    #
# they construct the bar, whereas the constructor constructs the object       #
###############################################################################

sub paint {
    my ($self, $r) = @_;
    my $bar = $self->read_configuration($r);
    return $self->{made} = $self->make_bar($r, $bar);
}

sub make_bar {
    my ($self, $r, $bar) = @_;
    # create the navigation bar
    my $current_url = $r->uri;
    my ($m, $class); # $m is the vassal's master, $class holds format
    # start with the master
    my $master_table_atts = $self->master_table_atts; # to interpolate 
    my @cells;
    for my $url (@{$bar->master_urls}) {
	my $label = $bar->master_label($url);
	# get the first $depth elements of the url
	my $base = $self->depth;
	my $trunc = ($url =~ /^((?:\/[^\/]*){$base}\/).*$/i, $1);
	my $is_current = $current_url =~ /^$trunc/;
	my $cell = $is_current ?
	    ($m = $trunc, 
	     $class = "master-active", $label)
	    : ($class = "master-normal",
	    qq(<A HREF="$url" class="master">$label</A>));
	push @cells,
	qq(<TD class="$class">$cell</TD>\n), $self->master_padding;
    }

    # return if not a two-level bar
    return qq(\n<TABLE $master_table_atts><TR>@cells</TR></TABLE>\n)
	unless %{$bar->vassal_urls}; 

    # return if a two-level bar without children urls, e.g.,
    # when the master selection holds no vassals.
    my $vassal_table_atts = $self->vassal_table_atts; # to interpolate
    return qq(\n<TABLE $master_table_atts><TR>@cells</TR></TABLE>
              <TABLE $vassal_table_atts>
	      <TR><TD CLASS="vassal-normal">&nbsp;</TD>
	      </TR></TABLE>\n) 
	unless $bar->vassal_urls($m); 

    # create the vassal table
    my @vassal_cells;
    for my $url (@{$bar->vassal_urls($m)}) { # get the master's vassals
	# $vassal_padding is used in all but the last cell, as specified
	# by $padding.
	my ($padding, $last) = ($self->vassal_padding);
	my $label = $bar->vassal_label($url);
	# get the first $depth + 1 elements of the url
	my $vassal_base = $self->depth + 1;
	my $trunc = ($url =~ /^((?:\/[^\/]*){$vassal_base}\/).*$/i, $1);
	my $is_current = $current_url =~ /^$trunc/;
	$padding = "" # stretch width, no padding
	    if ($url eq @{$bar->vassal_urls($m)}[-1]); # if last item
	my $cell = $is_current ?
	    ($class = "vassal-active", $label)
	    : ($class = "vassal-normal", 
	    qq(<A HREF="$url" class="vassal">$label</A>));
	push @vassal_cells,
	qq(<TD CLASS="$class" NOWRAP>$cell</TD>), $padding;
    }
    push @vassal_cells,
    qq(<TD CLASS="vassal-normal" NOWRAP WIDTH="100%">&nbsp;</TD>);
    return qq(<TABLE $master_table_atts><TR>@cells</TR></TABLE>
	      <TABLE $vassal_table_atts><TR>@vassal_cells</TR></TABLE>\n);
}

# read the navigation bar configuration file and return it as a hash
sub read_configuration {
    my ($self, $r) = @_;
    my $conf_file;
    return unless $conf_file = $r->dir_config('NavConf');
    return unless -e ($conf_file = $r->server_root_relative($conf_file));
    my $mod_time = (stat _)[9];
    return $BARS{$conf_file} if $BARS{$conf_file}
    && $BARS{$conf_file}->modified >= $mod_time;
    return $BARS{$conf_file} = NavBarDD->new($conf_file, $self->depth);
}

package NavBarDD;

#create a new NavBarDD object
sub new {
    my ($class, $conf_file, $depth) = @_;
    my (@master_urls, %master_labels, 
	@vassal_urls, %vassal_labels, %vassal_urls);
    my $p; # parent
    my $fh = Apache::File->new($conf_file) || return;
    while (<$fh>) {
	chomp;
	s/^\s+//; s/\s+$//;   # fold leading and trailing whitespace
	next if /^#/ || /^$/; # skip comments and empty lines
	next unless my($url, $label) = /^(\S+)\s+(.+)/;
	if ($url !~ /$p/i) { # url is not a child
	    # the parent is the first $depth url elements
	    $p = ($url =~ /^((?:\/[^\/]*){$depth}\/).*$/i, $1);	    
	    push @master_urls, $url; # keep the url in an ordered array
	    $master_labels{$url} = $label; # keep its label in a hash
	} else { 
	    push @{$vassal_urls{$p}}, $url;
	    $vassal_labels{$url}  = $label;
	}
    }
    return bless {'master_urls' => \@master_urls,
		  'master_labels' => \%master_labels,
		  'vassal_urls' => \@vassal_urls,
		  'vassal_labels' => \%vassal_labels,
		  'vassal_urls' => \%vassal_urls,
		  'modified' => (stat $conf_file)[9]}, $class;
}

# return reference to ordered list of the URIs in the master bar
sub master_urls { return shift->{'master_urls'}; }

# if called with an argument, return reference to the ordered list of the  
# argument's vassal urls; if called with no argument returns reference
# to the vassal urls hash that determines the existence of the vassal bar.
sub vassal_urls { return $_[0]->{'vassal_urls'} if $#_ == 0;
		  return $_[0]->{'vassal_urls'}->{$_[1]} if $#_ == 1;}

# return the label for a particular URI in the master bar
sub master_label { return $_[0]->{'master_labels'}->{$_[1]};}
#sub master_label { return $_[0]->{'master_labels'}->{$_[1]} || $_[1]; }

# return the label for a particular URI in the vassal bar
sub vassal_label { return $_[0]->{'vassal_labels'}->{$_[1]};}
#sub vassal_label { return $_[0]->{'vassal_labels'}->{$_[1]} || $_[1]; }

# return the modification date of the configuration file
sub modified { return $_[0]->{'modified'}; }

# return 

1;

__END__

=head1 NAME

Apache::NavBarDD - A dynamic double-decker (two level) Navigation Bar

=head1 SYNOPSIS

    use Apache::NavBarDD;
    $Apache::NavBarDD::myBar = Apache::NavBarDD->new;

=head1 DESCRIPTION

The NavBarDD package provides a dynamic navigation bar along the lines
of the NavBar module described in Lincoln Stein's and Doug
MacEachern's "Writing Apache Modules with Perl and C". It goes one
step further in allowing double-decker (two-level) navigation bars,
where the selection in the first level (the I<master> bar) determines
the contents of the second level (the I<vassal> bar).

The module provides an object oriented API to allow for easy
customisation. The navigation bar is an object that must be created
prior to use, for example in a server start-up file, according to the
contents of a special configuration file.

The main features of the module are:

=over 4

=item *

Allows both single and two level navigation bars.

=item *

It can be used to endow existing HTML pages with a navigation bar, or
it can be called from mod_perl modules.

=item *

Provides a full object oriented interface. 

=back

=head1 OVERVIEW

To create a new NavBarDD object with the default style:

    use Apache::NavBarDD;
    $Apache::NavBarDD::myBar = Apache::NavBarDD->new;

To create a new NavBarDD object preceded by a header image located in /images 
and using a specified stylesheet located in /styles:

    use Apache::NavBarDD;
    $Apache::NavBarDD::myBar = 
    Apache::NavBarDD->new(
	before => '<img src=/images/TOP.gif align="center">',
	style => '<link type="text/css" rel="stylesheet" href="/styles/navbar.css"/>'
	);

A navigation bar is usually constructed once and painted each time a
page is returned to the browser. I<Construction> refers to reading the
configuration file and creating the corresponding bar
structure. I<Painting> refers to actually rendering the bar taking
into account the currently displayed document etc. The bar is cached
after construction; it is reconstructed each time its configuration
file changes.

=head1 CONFIGURATION

One way to create the bar is to place the navigation bar's construction code
in a mod_perl-related initialisation file. Assuming that this file is
C</conf/startup.pl>, place the following in Apache's configuration file:

    PerlRequire      conf/startup.pl
    PerlFreshRestart On

You must of course configure the navigation bar in Apache's
configuration files:

    PerlModule Apache::NavBarDD
    <Location /site>
        SetHandler  perl-script
        PerlHandler $Apache::NavBarDD::myBar
        PerlSetVar  NavConf conf/navigation.conf
    </Location>

In this way, all HTML documents residing under /site are endowed with a
navigation bar. 

The bar can also be called from inside a mod_perl module:

    use Apache::NavBarDD;

    my $navbar = $Apache::NavBarDD::myBar;
    my $style = $navbar->style;
    $r->print("<HTML>\n<HEAD>\n<TITLE>mod_perl module</TITLE>\n$style</HEAD>\n<BODY>");
    $r->print($navbar->paint($r)); # $r is the request object

You have to make sure that the C<NavConf> variable is visible in the
module you are using the navigation bar. The variable points to the
navigation bar's configuration file, which is something like this:

    # Configuration file for the navigation bar
    /site/Home/				    Home
    /site/SectionA/		            First Section
    /site/SectionB/		            Second Section
    /site/SectionB/SubSectionA/	            Second Section A
    /site/SectionB/SubsectionB/		    Second Section B
    /site/SectionB/SubsectionC/foo.html	    Section B foo
    /site/SectionC/bar	                    bar
    /site/SectionC/foo/		            Section C foo
    /site/SectionC/bar/			    Section C bar

The configuration file comprises comments and lines of the form:

    URI    label

Each URI is the location of the content labelled by the corresponding
label. Lines starting with # are comments.

If the URI points to a directory it must end with a slash (/). I<Note
that this is different from the original NavBar configuration file,
where the trailing slash is not necessary>; it is due to the added
complexity of interpreting a two-levels structure.

The structure is interpreted by comparing each line to the previous
one. The comparison takes into account a specified level of
directories for the master bar, and that level plus one for the vassal
bar. The default level is 2, so that if the site's root is C</site>,
everything in C</site/Master/>, where C<Master> is a valid path
element, belongs to the master bar, except everything in
C</site/Master/Vassal/>, where C<Vassal> is a valid path element:
that belongs to the vassal bar.

This simple interpretation allows us to preselect an item in the vassal bar.
Consider the following segment of a configuration file:

    /site/FAQ/A/C.html				FAQ
    /site/FAQ/B/B.html				B
    /site/FAQ/A/C.html				C
    /site/FAQ/D/D.html				D

When selecting the FAQ tab, the user automatically gets C<C.html> as body,
with C<C> selected in the vassal bar.

If no vassals at all are found we get a one-level navigation bar.

=head1 CONSTRUCTOR

=over 4

=item new Apache::NavBarDD [ OPTIONS ]

This is the constructor for a new Apache::NavBarDD object. 

C<OPTIONS> are passed in a hash-like fashion, using key and value pairs.
Possible options are:

B<style> - An HTML C<style> element describing the navigation bar's style. The
navigation bar uses the following style classes:

=over 4

=item * 

C<td.master-active> - Master bar, selected item.

=item * 

C<td.master-normal> - Master bar, normal item.

=item *

C<td.vassal-active> - Vassal bar, selected item.

=item *

C<td.vassal-normal> - Vassal bar, normal item.

=item *

C<a.master> Anchors in master bar.

=item *

C<a.vassal> Anchors in vassal bar.

=back

The default value of C<style> is:

 <style>
 td.master-active {
     height: 2ex;
     font-family: helvetica,arial;
     font-weight: bold;
     font-size: 10pt;
     color: #003366;
     background-color: #FFFFCC;
     text-align: center
 }

 td.master-normal {
     height: 2ex;
     font-family: helvetica,arial;
     font-size: 10pt;
     color: #FFFFFF;
     background-color: #006633; 
     text-align:center;
 }

 td.vassal-active {
     height: 4ex; 
     font-family: helvetica,arial; 
     font-size: 7pt; 
     color: #006633; 
     background-color: #FFFFFF;
 }

 td.vassal-normal {
     height: 4ex; 
     font-family: helvetica, arial; 
     font-size: 7pt; 
     color: #006633; 
     background-color: #FFFFCC; 
 }

 a.master {
     text-decoration: none;
     color: #FFFFFF;
 }

 a.vassal {
     text-decoration: none;
     color: #006633;
 }

 </style>

B<master_table_atts> - The HTML C<table> attributes that apply to the master 
table. The default are:

C<CELLSPACING="0" CELLPADDING="1" BORDER="0" WIDTH="600">

B<vassal_table_atts> - The HTML C<table> attributes that apply to the vassal
table. The default are:

C<CELLSPACING="0" CELLPADDING="0" BORDER="0" WIDTH="100%" ALIGN="CENTER">

B<master_padding> - The HTML C<td> element that is used as padding between two 
cells in the master table. The default is:

C<< <TD BGCOLOR="#FFFFFF" WIDTH="2"><FONT SIZE="2">&nbsp;</FONT></TD> >>

B<vassal_padding> - The HTML C<td> element that is used as padding between two 
cells in the vassal table. The default is:

C<< <TD NOWRAP BGCOLOR="#FFFFCC" WIDTH="10">
<FONT SIZE="2" COLOR="#336699">&nbsp;|&nbsp;
</FONT></TD>\n >>

B<before> - An HTML element providing a header to be inserted before the
navigation bar. Default is empty. 

B<after> - An HTML element providing a header to be inserted after the 
navigation bar. Default is empty.

B<bottom> - A flag specifying, if set, to output the navigation bar on the
bottom as well as on the top of the page. Unset by default.

B<depth> - The depth of the directory hierarchy that is taken into account
when building the master bar; directories one level further down
are taken into account for the vassal bar. Default is 2.

=back

=head1 METHODS

=over 4

=item style ( [ STYLE ] )

If called without an argument, returns the bar's current style. C<STYLE> is 
an HTML C<style> element describing the navigation bar's style. 

=item master_table_atts ( [ TABLE_ATTS ] )

If called without an argument, returns the current master table's attributes.
C<TABLE_ATTS> is the HTML C<table> attributes that apply to the master 
table.

=item vassal_table_atts ( [ TABLE_ATTS ] )

If called without an argument, returns the current vassal table's attributes.
C<TABLE_ATTS> is the HTML C<table> attributes that apply to the vassal 
table.

=item master_padding ( [ PADDING_ATTS ] ) 

If called without an argument, returns the current master table's padding. 
C<PADDING_ATTS> is the HTML C<td> element that is used as padding between two 
adjacent cells in the master table.

=item vassal_padding  ( [ PADDING_ATTS ] )

If called without an argument, returns the current vassal table's padding. 
C<PADDING_ATTS> is the HTML C<td> element that is used as padding between two 
adjacent cells in the vassal table.

=item made ( ) 

Returns the constructed bar.

=item paint ( )

Paints and returns the constructed bar. Used in the mod_perl modules that 
want to display it.

=item before ( [ ELEMENT ] )

If called without an argument, returns the header that is currently inserted
before the navigation bar. C<ELEMENT> is an HTML element providing a 
header to be inserted before the navigation bar.

=item after ( [ ELEMENT ] )

If called without an argument, returns the header that is currently inserted
after the navigation bar. C<ELEMENT> is an HTML element providing a 
header to be inserted after the navigation bar.

=item bottom ( [ FLAG ] )

If called without an argument, returns the current value of the B<bottom>
option. If C<FLAG> is true the navigation bar is displayed in the bottom as 
well as on top of the page.

=back

=head1 AUTHOR

Panos Louridas <louridas@acm.org>.

=head1 SEE ALSO

Stein, L., MacEachern, D., (1999): "Writing Apache Modules with Perl
and C", O'Reilly & Associates, Sebastopol, CA, pp.  113--122. The
original Apache::NavBar.

Stein, L. D., (1998): "A Dynamic Navigation Bar", The Perl Journal,
Issue 12, Volume 3, Winter.

=head1 CREDITS

Lincoln Stein <lstein@cshl.org>, Doug MacEahern <dougm@pobox.com> -
for writing the original Apache::NavBar module. Lincoln gave permission
to distribute this on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Panagiotis Louridas <louridas@acm.org>. 
All rights reserved. This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut

