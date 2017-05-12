package AAC::Pvoice::Row;
use strict;
use warnings;

use Wx qw(:everything);
use Wx::Perl::Carp;
use AAC::Pvoice::Bitmap;
use base qw(Wx::Panel);

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.5 $=~/(\d+)\.(\d+)/);
#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    my ($parent,$maxitems,$items,
		$wxPos,$wxSize, $itemmaxX, $itemmaxY,
		$itemspacing, $background, $style,$name) = @_;
    my $self = $class->SUPER::new(  $parent,
				    Wx::NewId,
				    $wxPos  || wxDefaultPosition,
				    $wxSize || wxDefaultSize,
				    $style  || 0,
				    $name   || '');

    $self->{maxitems}    = $maxitems;

    my $sizer = Wx::GridSizer->new(1,0);
    $self->{items}   = [];
    $self->{actions} = [];
    
    my ($maxX, $maxY) = ($itemmaxX, $itemmaxY);

    # Add the defined keys for this row
    for (@$items)
    {
    	if (not defined $_)
    	{
            my $empty = Wx::BitmapButton->new(  $self, 
                                                Wx::NewId, 
                                                wxNullBitmap, 
                                                wxDefaultPosition, 
                                                [$maxX, $maxY],
                                                wxSUNKEN_BORDER);
            $empty->SetBackgroundColour($background);
    	    $sizer->Add($empty,0, wxALIGN_CENTRE|wxALL, $itemspacing);
            next;
    	}
        my ($id, $img, $sub) = @$_;
        my $button = Wx::BitmapButton->new ($self,             # parent
					    $id,               # id
					    $img,              # image
					    wxDefaultPosition, # position
					    [$maxX, $maxY],# size
					    wxSUNKEN_BORDER);  # style
        $button->SetBackgroundColour($background);
        $sizer->Add($button, 0, wxALIGN_CENTRE|wxALL, $itemspacing);
        push @{$self->{items}}, $button;
        push @{$self->{actions}}, $sub;
        push @{$self->{ids}}, $id;
    }
    my $totalitems = scalar(@$items);
    $self->{totalitems} = scalar(@{$self->{items}});
    for (0..($self->{maxitems} - $totalitems -1))
    {
	my $empty = Wx::BitmapButton->new(  $self, 
					    Wx::NewId, 
					    wxNullBitmap, 
					    wxDefaultPosition, 
					    [$maxX, $maxY],
					    wxSUNKEN_BORDER);
	$empty->SetBackgroundColour($background);
	$sizer->Add($empty,0, wxALIGN_CENTRE|wxALL, $itemspacing);
    }
    $self->SetBackgroundColour($background);
    $self->SetSizer($sizer);
    $self->SetAutoLayout(1);
    $sizer->Fit($self);
    return $self;
}

1;

__END__

=pod

=head1 NAME

AAC::Pvoice::Row - A row of selectable items

=head1 SYNOPSIS

  use AAC::Pvoice::Row;
  use Wx;
  
  my $panel = Wx::Panel->new($self, -1);
  my $items = [ [Wx::NewId, $SomeWxBitmap,      sub{ print "do something useful here"} ],
                [Wx::NewId, $SomeOtherWxBitmap, sub{ print "do something else here"} ]];
		
  my $row = AAC::Pvoice::Row->new($panel,           # parent
                                  scalar(@$items),  # max
                                  $items,           # items
                                  wxDefaultPosition,# pos
                                  wxDefaultSize,    # size
                                  50,		    # maxX
                                  75,               # maxY
                                  5,                # spacing
                                  wxWHITE)          # background colour

=head1 DESCRIPTION

AAC::Pvoice::Row is a subclass of Wx::Panel. It will typically be placed
on an AAC::Pvoice::Panel, and contains selectable Wx::Bitmap-s, which,
when selected, will invoke a callback.

=head1 USAGE

=head 2 new(parent, maxitems, items, position, size, maxX, maxY, spacing, backgroundcolour)

This constructor is the only overridden function in AAC::Pvoice::Row. It
takes quite a number of parameters

=over 4

=item parent

The parent on which this row will be placed. Typically you'll be using an
instance of AAC::Pvoice::Panel for this, but it can be any Wx::Window
subclass

=item maxitems

The maximum number of items (images) in this row. If the supplied number
of items (next parameter) is lower than maxitems, the row will be filled up
with (unselectable) WxNullBitmap-s.

=item items

This parameter is a reference to a list of lists. Each item in the listref
contains three items: a unique id, a Wx::Bitmap (or AAC::Pvoice::Bitmap for
that matter), and a callback that will be invoked when the item is selected.

=item position

This parameter is passed on to the SUPER's constructor directly. See the
documentation for Wx::Panel.

=item size

This parameter is passed on to the SUPER's constructor directly. See the
documentation for Wx::Panel.

=item maxX

This is the maximum X size in pixels for an item (a Bitmap) in this row

=item maxY

This is the maximum Y size in pixels for an item (a Bitmap) in this row

=item spacing

This is the spacing between the items in pixels in this row

=item backgroundcolour

This is the backgroundcolour of the panel, defined as a Wx::Colour, or one
of the constants defined by Wx (like wxWHITE)

=back

=head1 BUGS

probably a lot, patches welcome!


=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx

=cut