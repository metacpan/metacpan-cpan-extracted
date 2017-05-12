package Ace::Browser::SearchSubs;

=head1 NAME

Ace::Browser::SearchSubs - Subroutines for AceBrowser search scripts

=head1 SYNOPSIS

  use Ace;
  use Ace::Browser::AceSubs;
  use Ace::Browser::SearchSubs;
  use CGI qw(:standard);

  my $form = p(start_form,
	       textfield(-name=>'query'),
	       end_form);
  AceSearchTable('Search for stuff',$form);
  ...

  my $query  = param('query');
  my $offset = AceSearchOffset;
  my ($objects,$count) = do_search($query,$offset);
  AceResultsTable($objects,$count,$offset,'Here are results');

=head1 DESCRIPTION

Ace::Browser::SearchSubs exports a set of constants and subroutines
that are useful for creating AceBrowser search scripts.

=head2 CONSTANTS

This package exports the following constants:

  MAXOBJECTS     The maximum number of objects that can be displayed
                 per page.

  SEARCH_ICON    An icon to use for search links. This is deprecated.
                 Use Configuration->Search_icon instead.

=head2 FUNCTIONS

These functions are exported:

=over 4

=cut

# Common constants and subroutines used by the various search scripts

use strict;
use vars qw(@ISA @EXPORT $VERSION);
use Ace::Browser::AceSubs qw(Configuration Url ResolveUrl);
use CGI qw(:standard *table *Tr *td);

require Exporter;
@ISA = qw(Exporter);
$VERSION = '1.30';

######################### This is the list of exported subroutines #######################
@EXPORT = qw(
	     MAXOBJECTS
	     SEARCH_ICON
	     AceSearchTable AceResultsTable AceSearchOffset
	     DisplayInstructions
	    );

# ----- constants used by the pattern search script ------
use constant ROWS           => 10;    # how many rows to allocate for search results
use constant COLS           =>  5;    #  "   "   columns   "       "    "      "
use constant MAXOBJECTS     => ROWS * COLS;  # total objects per screen
use constant ICONS          => '/ico';
use constant SEARCH_ICON    => '/ico/search.gif';
use constant SPACER_ICON    => 'spacer.gif';
use constant LEFT_ICON      => 'cylarrw.gif';
use constant RIGHT_ICON     => 'cyrarrw.gif';

=item $offset = AceSearchOffset()

When the user is paging back and forth among a multi-page list of
results, this function returns the index of the first item to display.

=cut

sub AceSearchOffset {
  my $offset = param('offset') || 0;
  $offset += param('scroll') if param('scroll');
  $offset;
}

=item AceSearchTable([{hash}],$title,@contents)

Given a title and the HTML contents, this formats the search into a
table and gives it the background and foreground colors used elsewhere
for searches.  The formatted search is then printed.

The HTML contents are usually a fill-out form.  For convenience, you
can provide the contents in multiple parts (lines or elements) and
they will be concatenated together.

If the first argument is a hashref, then its contents will be passed
to start_form() to override the form arguments.

=cut

sub AceSearchTable {
  my %attributes = %{shift()} if ref($_[0]) eq 'HASH';
  my ($title,@body) = @_;
  print
    start_form(-action=>url(-absolute=>1,-path_info=>1).'#results',%attributes),
    a({-name=>'search'},''),
    table({-border=>0,-width=>'100%'},
	  TR({-valign=>'MIDDLE'},
	     td({-class=>'searchbody'},@body))),
    end_form;
}

=item AceResultsTable($objects,$count,$offset,$title)

This subroutine formats the results of a search into a pageable list
and prints out the resulting HTML.  The following arguments are required:

 $objects   An array reference containing the objects to place in the
            table.

 $count     The total number of objects.

 $offset    The offset into the array, as returned by AceSearchOffset()

 $title     A title for the table.

The array reference should contain no more than MAXOBJECTS objects.
The AceDB query should be arranged in such a way that this is the
case.  A typical idiom is the following:

  my $offset = AceSearchOffset();
  my $query  = param('query');
  my $count;
  my @objs = $db->fetch(-query=> $query,
			-count  => MAXOBJECTS,
			-offset => $offset,
			-total => \$count
		       );
  AceResultsTable(\@objs,$count,$offset,'Here are the results');

=cut

sub AceResultsTable {
  my ($objects,$count,$offset,$title) = @_;
  Delete('scroll');
  param(-name=>'offset',-value=>$offset);
  my @cheaders = map { $offset + ROWS * $_ } (0..(@$objects-1)/ROWS) if @$objects;
  my @rheaders = (1..min(ROWS,$count));

  $title ||= 'Search Results';

  print 
    a({-name=>'results'},''),
    start_table({-border=>0,-cellspacing=>2,-cellpadding=>2,-width=>'100%',-align=>'CENTER',-class=>'resultsbody'}),
    TR(th({-class=>'resultstitle'},$title));
  unless (@$objects) {
    print end_table,p();
    return;
  }

  print start_Tr,start_td;

  my $need_navbar = $offset > 0 || $count >= MAXOBJECTS;
  my @buttons = make_navigation_bar($offset,$count) if $need_navbar;

  print table({-width=>'50%',-align=>'CENTER'},Tr(@buttons)) if $need_navbar;
  print table({-width=>'100%'},tableize(ROWS,COLS,\@rheaders,\@cheaders,@$objects));

  print end_td,end_Tr,end_table,p();
}

# ------ ugly internal routines for scrolling along the search results list -----
sub make_navigation_bar {
  my($offset,$count) = @_;
  my (@buttons);
  my ($page,$pages) =  (1+int($offset/MAXOBJECTS),1+int($count/MAXOBJECTS));
  my $c = Configuration();
  my $icons  = $c->Icons || '/ico';
  my $spacer = "$icons/". SPACER_ICON;
  my $left   = "$icons/". LEFT_ICON;
  my $right  = "$icons/". RIGHT_ICON;
  my $url    = url(-absolute=>1,-query=>1);
  #  my $url    = self_url();
  push(@buttons,td({-align=>'RIGHT',-valign=>'MIDDLE'},
		   $offset > 0 
		               ? a({-href=>$url
                                  . '&scroll=-' . MAXOBJECTS},
				      img({-src=>$left,-alt=>'&lt; PREVIOUS',-border=>0}))
                               : img({-src=>$spacer,-alt=>''})
		   )
      );

  my $p = 1;
  while ($pages/$p > 25) { $p++; }
  my (@v,%v);
  for (my $i=1;$i<=$pages;$i++) {
    next unless ($i == $page) or (($i-1) % $p == 0);
    my $s = ($i - $page) * MAXOBJECTS;
    push(@v,$s);
    $v{$s}=$i;
  }
  my @hidden;
  Delete('scroll');
  Delete('Go');
  foreach (param()) {
    push(@hidden,hidden(-name=>$_,-value=>[param($_)]));
  }

  push(@buttons,
       td({-valign=>'MIDDLE',-align=>'CENTER'},
	  start_form({-name=>'form1'}),
	  submit(-name=>'Go',-label=>'Go to'),
	  'page',
	  popup_menu(-name=>'scroll',-Values=>\@v,-labels=>\%v,
		     -default=>($page-1)*MAXOBJECTS-$offset,
		     -override=>1,
		     -onChange=>'document.form1.submit()'),
	  "of $pages",
	  @hidden,
	  end_form()
	 )
      );

  push(@buttons,td({-align=>'LEFT',-valign=>'MIDDLE'},
		   $offset + MAXOBJECTS <= $count 
		   ? a({-href=>$url
			    . '&scroll=+' . MAXOBJECTS},
		       img({-src=>$right,-alt=>'NEXT &gt;',-border=>0}))
		   : img({-src=>$spacer,-alt=>''})
		  )
      );
  @buttons;
}

sub min { return $_[0] < $_[1] ? $_[0] : $_[1] }
#line 295

sub tableize {
    my($rows,$columns,$rheaders,$cheaders,@elements) = @_;
    my($result);
    my($row,$column);
    $result .= TR($rheaders ? th('&nbsp;') : (),th({-align=>'LEFT'},$cheaders)) 
      if $cheaders and @$cheaders > 1;
    for ($row=0;$row<$rows;$row++) {
	next unless defined($elements[$row]);
	$result .= "<TR>";
        $result .= qq(<TH  ALIGN=LEFT CLASS="search">$rheaders->[$row]</TH>) if $rheaders;
	for ($column=0;$column<$columns;$column++) {
	    $result .= qq(<TD VALIGN=TOP CLASS="search">) . $elements[$column*$rows + $row] . "</TD>"
		if defined($elements[$column*$rows + $row]);
	}
	$result .= "</TR>";
    }
    return $result;
}

1;

__END__

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Object>, L<Ace::Browser::SiteDefs>, L<Ace::Browsr::AceSubs>,
the README.ACEBROWSER file.

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
