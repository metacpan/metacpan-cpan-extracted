package AAC::Pvoice::Dialog;
use strict;
use warnings;

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.1 $=~/(\d+)\.(\d+)/);

use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE);

use base 'Wx::Dialog';

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my ($x, $y) = ($self->GetClientSize->GetWidth,
                   $self->GetClientSize->GetHeight);

    $self->{margin}           = 10;
    $self->{ITEMSPACING}      = 4;
    $self->{selectionborder}  = 3;
    $self->{backgroundcolour} = Wx::Colour->new(220,220,220);
    $self->SetBackgroundColour(wxWHITE);

    $self->{panel} = AAC::Pvoice::Panel->new(   $self,                 # parent
                                                -1,                    # id
                                                [$self->{margin},
                                                 $self->{margin}],     # position
                                                [$x-2*$self->{margin},
                                                 $y-2*$self->{margin}],# size
                                                wxNO_3D|wxWANTS_CHARS,               # style
                                                1,                     # disabletextrow 
                                                $self->{ITEMSPACING},  # rowspacing
                                                $self->{selectionborder}, # selectionborderwidth
                                                1);                     # disabletitle
    
    $self->{panel}->BackgroundColour($self->{backgroundcolour});
    $self->WarpPointer($self->{margin}+1,$self->{margin}+1);
    $self->SetFocus();
    EVT_CLOSE($self, \&OnClose);
    return $self;
}

sub Append
{
    my $self = shift;
    $self->{panel}->Append(@_);
}

sub OnClose
{
    my $self = shift;
    $self->Destroy();
}

sub Show
{
    my $self = shift;
    my $bool = shift;
    $self->{panel}->Finalize();
    $self->SUPER::Show($bool);    
}

sub ShowModal
{
    my $self = shift;
    $self->{panel}->Finalize();
    $self->SUPER::ShowModal();
}

1;

__END__


=pod

=head1 NAME

AAC::Pvoice::Dialog - A class similar to Wx::Dialog, with added accessibility

=head1 SYNOPSIS

  use AAC::Pvoice::Dialog;

=head1 DESCRIPTION

This subclass of Wx::Dialog knows all of Wx::Dialog's methods. Therefore
only two methods are described below. The constructor (which is also similar
to the Wx::Dialog constructor) and the (added) Append method.

=head1 USAGE

=head2 new(parent, id, caption, [x,y], [w,h])

This is the constructor for a new AAC::Pvoice::Dialog. It is similar to calling
the constructor of a Wx::Dialog.

=head2 Append

This method is similar to AAC::Pvoice::Panel's Append method and allows you
to append a 'row' (or any Wx::Window subclass) to the Dialog.

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
