package AAC::Pvoice::EditableRow;
use strict;
use warnings;

use Wx qw(:everything);
use Wx::Perl::Carp;
use Wx::Event qw(   EVT_BUTTON );
use AAC::Pvoice::Bitmap;
use base qw(Wx::Panel);

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.4 $=~/(\d+)\.(\d+)/);

#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    my ($parent,$maxitems,$items,$wxPos,$wxSize, $itemmaxX, $itemmaxY, $itemspacing, $background, $style,$name) = @_;
    $wxPos ||= wxDefaultPosition;
    $wxSize ||= wxDefaultSize;
    $style ||= 0;
    $name ||= '';
    my $self = $class->SUPER::new($parent, -1, $wxPos, $wxSize, $style, $name);

    $self->{maxitems} = $maxitems;
    $self->{itemspacing}=$itemspacing;

    # Create a new panel
    my $sizer = Wx::GridSizer->new(1,0);
    $self->{items} = [];
    $self->{actions} = [];

    my ($maxX, $maxY) = ($itemmaxX, $itemmaxY);

    # Add the defined keys for this row
    for (@$items)
    {
        my ($id, $img, $sub) = @$_;
        my $button = Wx::BitmapButton->new
                                    ($self,             # parent
                                     $id,               # id
                                     $img,              # image
                                     wxDefaultPosition, # position
                                     [$maxX+3, $maxY+3],     	# size
                                     wxBU_AUTODRAW);  # style
        $button->SetBackgroundColour($background);
        $sizer->Add($button, 0, wxALIGN_CENTRE|wxALL, $self->{itemspacing});
        push @{$self->{items}}, $button;
	EVT_BUTTON($self, $id, $sub);
    }
    my $totalitems = scalar(@$items);
    $self->{totalitems} = scalar(@{$self->{items}});
    $self->SetBackgroundColour($background);
    $self->SetSizer($sizer);
#    $self->SetAutoLayout(1);
    $sizer->Fit($self);
    return $self;
}

1;

__END__

=head1 NAME

AAC::Pvoice::EditableRow - Draw a pVoice row where items can be edited directly

=head1 SYNOPSIS

  use AAC::Pvoice::EditableRow


=head1 DESCRIPTION

This module is currently only useful for the pVoice application. It needs
to be refactored, maybe it'll disappear completely

=head1 USAGE

(todo)

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

