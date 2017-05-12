package AAC::Pvoice::Panel;
use strict;
use warnings;

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.15 $=~/(\d+)\.(\d+)/);

use Wx qw(:everything);
use Wx::Perl::Carp;
use Wx::Event qw(EVT_PAINT EVT_UPDATE_UI);
use base qw(Wx::Panel);

#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    $_[2] ||= wxDefaultPosition;
    $_[3] ||= wxDefaultSize;
    $_[4] ||= wxTAB_TRAVERSAL;
    my $self = $class->SUPER::new(@_[0..4]);

    $self->SetBackgroundColour(wxWHITE);

    $self->{parent}         = $_[0];
    $self->{position}       = $_[2];
    $self->{size}           = $_[3];
    $self->{disabletextrow} = $_[5] || 0;
    $self->{itemspacing}    = $_[6] || 0;
    $self->{selectionborder}= $_[7] || int($self->{itemspacing}/2)||1;
    $self->{disabletitle}   = $_[8] || 0;
    $self->{tls} = Wx::FlexGridSizer->new(0,1);
    $self->{totalrows}   = 0;
    $self->{lastrow}     = 0;
    $self->{currentpage} = 0;
    $self->{unfinished}  = 1;
    
    $self->RoundCornerRadius(10);

    my ($x, $y);

    # to get the right dimensions for the items, we maximize the
    # frame, show it, get the dimensions, and hide it again
    if (ref($self->{parent}) =~ /Frame/)
    {
	if ($self->{parent}->IsMaximized)
	{
	    ($x, $y) = @{$self->{size}};
	}
	else
	{
	    $self->{parent}->Maximize(1);
	    $self->{parent}->Show(1);
	    ($x, $y) = ( $self->GetSize()->GetWidth(),
			 $self->GetSize()->GetHeight() );
	    $self->{parent}->Show(0);
	}
    }
    else
    {
	# if our parent isn't a frame, we're not able to maximize
	# it, so we just get the dimensions of the parent
	($x, $y) = @{$self->{size}};
    }
    $self->{realx} = $x;
    $self->{realy} = $y;
    $self->xsize($x);
    $self->ysize($y);
    unless ($self->{disabletitle})
    {
	# to be able to calculate the useable y-size, we need to add the
	# title and get its height. Since we don't know what the title
	# will be, we'll simple draw an empty title.
	$self->TitleFont(Wx::Font->new( 18,                 # font size
					wxDECORATIVE,       # font family
					wxNORMAL,           # style
					wxNORMAL,           # weight
					0,                  
					'Comic Sans MS',    # face name
					wxFONTENCODING_SYSTEM)) unless $self->TitleFont;
	$self->AddTitle('');
	my $usableysize = $y - 2*$self->{title}->GetSize()->GetHeight();
	# If we want to use a textrow, we have to subtract another 60
	# pixels from the y size, since the textrow is always 60 pixels high.
	$usableysize-=60 unless $self->{disabletextrow};
	$self->ysize($usableysize);
    }
    # set the default colours...these can of course be changed...
    $self->SelectColour(Wx::Colour->new(255,131,131));
    $self->BackgroundColour(Wx::Colour->new(220,220,220));
    
    $self->SetSizer($self->{tls});
    $self->SetAutoLayout(1);

    $self->{displaytextsave} = [];
    $self->{speechtextsave}  = [];
    
    # Initialize the input stuff
    $self->{input} = AAC::Pvoice::Input->new($self);
    $self->{input}->Next(  sub{$self->Next});
    $self->{input}->Select(sub{$self->Select});
    
    $self->{rowcolumnscanning} = ($self->{input}->GetDevice ne 'mouse');
    EVT_PAINT($self, \&OnPaint);
    EVT_UPDATE_UI($self, $self, \&OnPaint);
    return $self;
}

sub SetEditmode
{
    my $self = shift;
    $self->{editmode} = shift;
}

sub OnPaint
{
    my ($self, $event) = @_;
    $self->{setselection} = 1;
    my $dc = Wx::PaintDC->new($self);
    $self->SetBackgroundColour($self->{parent}->GetBackgroundColour);
    $self->DrawBackground($dc);
    if ($self->{rowcolumnscanning} && not $self->{editmode})
    {
	$dc = Wx::WindowDC->new($self->{selectedwindow}->GetParent);
	$self->DrawBorder($dc);
    }
    $event->Skip;
}

sub DrawBorder
{
    my $self = shift;
    my $dc = shift;
    my $window = $self->{selectedwindow};
    my ($x, $y) = $window->GetPositionXY;
    my $size = $window->GetSize;
    my ($xsize, $ysize) = ($size->GetWidth, $size->GetHeight);
    $dc->BeginDrawing;
    $dc->SetBrush(wxTRANSPARENT_BRUSH);
    $dc->SetPen(Wx::Pen->new($self->{setselection} ? $self->SelectColour :
			                         $self->BackgroundColour, $self->{selectionborder}, wxSOLID));
    $dc->DrawRoundedRectangle($x-($self->{itemspacing}/2-1), $y-($self->{itemspacing}/2-1), $xsize+($self->{itemspacing}/2+1), $ysize+($self->{itemspacing}/2+1), $self->RoundCornerRadius);
    $dc->EndDrawing;
}

sub SetSelectionBorder
{
    my $self = shift;
    $self->{selectedwindow} = shift;
    $self->{setselection} = 1;
    my $dc = Wx::WindowDC->new($self->{selectedwindow}->GetParent);
    $self->DrawBorder($dc);
}

sub SetNormalBorder
{
    my $self = shift;
    $self->{selectedwindow} = shift;
    $self->{setselection} = 0;
    my $dc = Wx::WindowDC->new($self->{selectedwindow}->GetParent);
    $self->DrawBorder($dc);
}

sub RoundCornerRadius
{
    my $self = shift;
    $self->{radius} = shift || $self->{radius};
    return $self->{radius};
}

sub xsize
{
    my $self = shift;
    $self->{xsize} = shift || $self->{xsize};
    return $self->{xsize}-2*$self->RoundCornerRadius; 
}

sub ysize
{
    my $self = shift;
    $self->{ysize} = shift || $self->{ysize};
    return $self->{ysize}-2*$self->RoundCornerRadius;
}

sub lastrow
{
    my $self = shift;
    return $self->{lastrow};
}


sub SelectColour
{
    my $self = shift;
    $self->{selectcolour} = shift || $self->{selectcolour};
    return $self->{selectcolour};
}

sub BackgroundColour
{
    my $self = shift;
    $self->{backgroundcolour} = shift || $self->{backgroundcolour};
    return $self->{backgroundcolour};
}

sub DrawBackground
{
    my $self = shift;
    my $dc = shift;
    $dc->SetBrush(Wx::Brush->new($self->BackgroundColour, wxSOLID));
    $dc->SetPen(Wx::Pen->new($self->BackgroundColour, 1, wxSOLID));
    $dc->DrawRoundedRectangle(0,0,$self->{realx}, $self->{realy}, $self->RoundCornerRadius);
}

sub AddTitle
{
    my ($self, $title) = @_;
    return if $self->{disabletitle};
    my $titleupdate = exists $self->{title};
    if ($titleupdate)
    {
	$self->{tls}->Remove($self->{title});
    }
    # Create the TextControl
    $self->{title} = Wx::StaticText->new(   $self,         
                                            -1,             
                                            $title,
                                            wxDefaultPosition,
                                            wxDefaultSize,
                                            wxALIGN_CENTRE);
    $self->TitleFont();
    # Don't use 'Add' here...the title should be on top!!
    $self->{tls}->Prepend($self->{title},0, wxALIGN_CENTRE, 0);
}

sub TitleFont
{
    my $self = shift;
    $self->{titlefont} = shift || $self->{titlefont};
    return if not $self->{titlefont};
    $self->{title}->SetFont($self->{titlefont}) if $self->{title};
    return $self->{titlefont};
}

sub Append
{
    my $self = shift;
    my $row = shift;
    my $unselectable = shift;
    $self->{tls}->Add($row,                 # what to add
                      0,                    # unused
                      wxALIGN_CENTRE,       # style
                      0);                   # padding

    # setup the input event handling unless we're in editmode
    unless ($self->{editmode})
    {
	$row->{input} = AAC::Pvoice::Input->newchild($row);
	$row->{input}->Next(  sub{$self->Next});
	$row->{input}->Select(sub{$self->Select});
	my $index=0;
	foreach my $child ($row->GetChildren)
	{
	    $child->{input} = AAC::Pvoice::Input->newchild($child);
	    $child->{input}->Next(  sub{$self->Next});
	    $child->{input}->Select(sub{$self->Select});
	    if ((defined $row->{ids}->[$index]) && ($child->GetId == $row->{ids}->[$index]))
	    {
		my $action = $row->{actions}->[$index];
		$self->{input}->SetupMouse($child, sub{$self->SetSelectionBorder($child)}, $action, sub{$self->SetNormalBorder($child)});
		$index++;
	    }
	}
    }

    $self->{totalrows}++ if not $unselectable;
    $self->{lastrow}++;
    push @{$self->{rows}}, $row if not $unselectable;
    push @{$self->{unselectablerows}}, $row if $unselectable;
}

sub PauseInput
{
    my $self = shift;
    my $bool = shift;
    $self->{input}->PauseMonitor($bool);
    $self->{input}->PauseAutoscan($bool);
    $self->{input}->Pause($bool);
}

sub Clear
{
    my $self = shift;
    $self->{tls}->Remove($_) for (0..$self->{lastrow});
    foreach my $row (@{$self->{rows}})
    {
	$_->Destroy for $row->GetChildren();
	$row->Destroy
    }
    $_->Destroy for @{$self->{unselectablerows}};
    $self->{text}->Destroy if exists $self->{text};
    $self->{title}->Destroy if exists $self->{title};
    $self->{rows} = [];
    $self->{unselectablerows} = [];
    $self->SUPER::Clear();
    $self->{totalrows} = 0;
    $self->{lastrow} = 0;
    $self->Refresh;
}

sub Finalize
{
    my $self = shift;
    my $dc = Wx::WindowDC->new($self);
    $self->DrawBackground($dc);

    unless ($self->{disabletextrow})
    { 
	# Create the TextControl
	my $font = Wx::Font->new(  24,             # font size
				   wxSWISS,        # font family
				   wxNORMAL,       # style
				   wxNORMAL,       # weight
				   0,
				   'Comic Sans MS',# face name
				   wxFONTENCODING_SYSTEM);
	$font->SetUnderlined(1);
	$self->{ta} = Wx::TextAttr->new( Wx::Colour->new(0,0,0),      # textcol
					 Wx::Colour->new(255,255,255),# backgr.
					 $font);                      # font
	my $rowsizer = Wx::GridSizer->new(1,0);
	$self->{text} = Wx::TextCtrl->new( $self,            # parent
					   -1,               # id
					   '',               # text
					   wxDefaultPosition,# position
					   [4*($self->{realx}/5),60], # size
					   wxTE_RICH|
					   wxTE_MULTILINE);  # style
	# set the text-attributes
	$self->{text}->SetDefaultStyle($self->{ta});
	$rowsizer->Add($self->{text},          # what to add
		       0,                      # unused
		       wxALIGN_CENTRE|wxALL,   # style
		       $self->{itemspacing});  # padding
	$self->{tls}->Add($rowsizer, 0, wxALIGN_CENTRE, 0);
	$self->{textrowsizer} = $rowsizer;
    
	$self->{text}->SetValue(my $x = $self->RetrieveText);
	$self->{text}->SetStyle(0, length($self->{text}->GetValue), $self->{ta});
	$self->{text}->Refresh(); # Added to test it on the Mercury...added text
				  # isn't visible there...
    }    
    $self->{title}->SetBackgroundColour($self->BackgroundColour) unless $self->{disabletitle};

    $self->{tls}->AddGrowableCol(0);
    $self->Layout;

    # Select the first row
    $self->{selectedrow} = 0;
    $self->{selecteditem} = 0;
    $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning} && not $self->{editmode};
    $self->{rowselection} = 1;
    $self->Refresh;
    $self->Update();
    $self->{unfinished} = 0;
}

sub Next
{
    my $self = shift;
    return if ($self->{editmode} || $self->{unfinished});
    $self->{input}->QuitAutoscan;
    if ($self->{rowselection})
    {
        $self->SetNormalBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning};
        if ($self->{selectedrow} < ($self->{totalrows}-1))
        {
            $self->{selectedrow}++;
        }
        else
        {
            $self->{selectedrow} = 0;
        }
        $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning};
    }
    else
    {
        $self->SetNormalBorder($self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]) if $self->{rowcolumnscanning};
        if ($self->{selecteditem} < ($self->{rows}->[$self->{selectedrow}]->{totalitems}-1))
        {
            $self->{selecteditem}++;
        }
        else
        {
            $self->{selecteditem} = 0;
        }
        $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]) if $self->{rowcolumnscanning};
    }
    $self->{input}->StartAutoscan;
}

sub Select
{
    my $self = shift;
    return if $self->{editmode};
    $self->{input}->QuitAutoscan;
    if (($self->{rowselection}) &&  (@{$self->{rows}->[$self->{selectedrow}]->{items}} == 1))
    {
	$self->{rowselection} = 0;
	$self->{selecteditem} = 0;
    }
    if ($self->{rowselection})
    {
        $self->SetNormalBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning};
        $self->{rowselection} = 0;
        $self->{selecteditem} = 0;
        $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]) if $self->{rowcolumnscanning};
    }
    else
    {
        $self->SetNormalBorder($self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]) if $self->{rowcolumnscanning};
        $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning};

        &{$self->{rows}->[$self->{selectedrow}]->{actions}->[$self->{selecteditem}]};
        $self->{rowselection} = 1;
    }
    $self->{input}->StartAutoscan;
}

sub ToRowSelection
{
    my $self = shift;
	return if $self->{editmode};
    $self->SetNormalBorder($self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]) if $self->{rowcolumnscanning};
    $self->SetSelectionBorder($self->{rows}->[$self->{selectedrow}]) if $self->{rowcolumnscanning};
    $self->{rowselection} = 1;
}

sub DisplayAddText
{
    my $self = shift;
    push @{$self->{displaytextsave}}, $_[0];
    $self->{text}->AppendText($_[0]);
    $self->{text}->Refresh(); # Added to test it on the Mercury...added text
                              # isn't visible there...
}

sub SpeechAddText
{
    my $self = shift;
    push @{$self->{speechtextsave}}, $_[0];
}

sub RetrieveText
{
    my $self = shift;
    return wantarray ? @{$self->{displaytextsave}} : join('', @{$self->{displaytextsave}});
}

sub ClearText
{
    my $self = shift;
    $self->{displaytextsave}=[];
    $self->{speechtextsave}=[];
    $self->{text}->SetValue('');
    $self->{text}->Refresh(); # Added to test it on the Mercury...added text
                              # isn't visible there...
}

sub BackspaceText
{
    my $self = shift;
    pop @{$self->{displaytextsave}};
    pop @{$self->{speechtextsave}};
    $self->{text}->SetValue(my $x = $self->RetrieveText);
    $self->{text}->SetStyle(0, length($self->{text}->GetValue), $self->{ta});
    $self->{text}->Refresh(); # Added to test it on the Mercury...added text
                              # isn't visible there...
}

sub SpeechRetrieveText
{
    my $self = shift;
    return wantarray ? @{$self->{speechtextsave}} : join('', @{$self->{speechtextsave}});
}
    
1;

__END__

=pod

=head1 NAME

AAC::Pvoice::Panel - The base where a pVoice application consists of

=head1 SYNOPSIS

  use AAC::Pvoice::Panel;



=head1 DESCRIPTION



=head1 USAGE

=head2 new(parent, id, size, position, style, disabletextrow, itemspacing, selectionborderwidth, disabletitle)

This is the constructor for a new AAC::Pvoice::Panel. The first 5 parameters are
equal to the parameters for a normal Wx::Panel, see the wxPerl documentation
for those parameters.

=over 4

=item disabletextrow

This is s a boolean (1 or 0), which determines
if the text-input field at the bottom of the screen should be hidden or
not. Normally this inputfield will be shown (for an application like pVoice
this is normal, because that will contain the text the user is writing),
but for an application like pMusic this row is not nessecary, so it can be
disabled.

=item itemspacing

This is the spacing used between the rows that are appended.

=item selectionborderwidth

This is the width of the border around a selected row or a selected item.

=item disabletitle

This is also a boolean (1 or 0), which determines if the panel should
reserve space for a title. If disabletitle is set to 1, AddTitle won't have
any effect at all.

=back

=head2 SetEditmode($onoff)

This sets Editmode on or off (depending on $onoff to be a true or false value).
Editmode means that the typical pVoice input doesn't work anymore, and is
typically used in combination with AAC::Pvoice::EditableRow...

=head2 xsize

This returns the x-size of the panel in pixels.

=head2 ysize

This returns the y-size of the panel in pixels.

=head2 RoundCornerRadius

This sets the radius for the round corners that are used to draw the panel
background and to draw the selectionborder around rows and buttons.

=head2 lastrow

This retrieves the index of the last row that was added to the panel.

=head2 SelectColour(Wx::Colour)

This gets or sets the colour that indicates a selected row or selected item. It
takes a Wx::Colour (or a predefined colour constant) as a parameter.

=head2 BackgroundColour(Wx::Colour)

This gets or sets the normal backgroundcolour. It
takes a Wx::Colour (or a predefined colour constant) as a parameter.

=head2 AddTitle(title)

This method sets the title of the page and draws it on the AAC::Pvoice::Panel.
By default it uses the Comic Sans MS font at a size of 18pt. You can change
this using TitleFont.

=head2 TitleFont(Wx::Font)

This method gets or sets the Wx::Font used to write the Title.

=head2 Append(row, unselectable)

This method adds a row (AAC::Pvoice::Row or any subclass of Wx::Window) to
the panel. If this row shouldn't be selectable by the user, you should set
unselectable to 1. Omitting this parameter, or setting it to 0 makes the
row selectable.

=head2 Clear

This method clears the panel completely and destroys all objects on it.

=head2 Finalize

This method 'finalizes' the panel by creating the textinput row (if appliccable)
and setting up the selection of the first row. You always need to call
this method before being able to let the user interact with the pVoice panel.

=head2 Next

This method normally won't be called directly. It will highlight the 'next'
row (when we're in 'rowselection') or the next item inside a row (when
we're in 'columnselection')

=head2 Select

This method normally won't be called directly either. It will either 'select'
the row that is highlighted and thus go into columnselection, or, when we're
in columnselection, invoke the callback associated with that item and
go into rowselection again.

=head2 ToRowSelection

This method will remove the highlighting of an item (if nessecary) and highlight
the entire current row again and set rowselection back on.

=head2 DisplayAddText(text)

In pVoice-like applications there's a difference between 'displaytext' (which is
the text that the user actually is writing and which should be displayed on the
textrow) and the speech (phonetical) text (which is not displayed, but -if nessecary-
differs from the text as we would write it, so a speechsynthesizer sounds
better.

This method adds text to the displaytext. It is saved internally and displayed
on the textrow

=head2 SpeechAddText(text)

This method add text to the speechtext. It is saved internally and not displayed
on the textrow. See DisplayAddText for more information.

=head2 RetrieveText

This method returns the text that is added to the Displaytext since the
last 'ClearText'. In scalar context it returns it as one string, in listcontext
it returns the array of text as it was added.

=head2 SpeechRetrieveText

This method returns the text that is added to the Speechtext since the
last 'ClearText'. In scalar context it returns it as one string, in listcontext
it returns the array of text as it was added.

=head2 ClearText

This method clears both the displaytext and the speechtext. It also updates
the textrow to show nothing.

=head2 BackspaceText

This method removes the last text added to the speech *and* displaytext.
Make sure that both speechtext and displaytext have the same amount of
text added, because it just pops off the last item from both lists and
updates the textrow.

=head2 PauseInput($bool)

This method makes sure that the timers that are used for the input (using
AAC::Pvoice::Input) are paused if $bool is set to 1. If $bool is 0, they're
restarted.

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
