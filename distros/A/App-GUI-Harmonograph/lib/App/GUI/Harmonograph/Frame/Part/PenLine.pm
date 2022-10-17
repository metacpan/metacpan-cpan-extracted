use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::PenLine;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    #return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->{'length'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Length','length of drawing in full circles', 1,  150,  10);
    $self->{'density'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Density','pixel per circle',  1,  50,  10);
    $self->{'thickness'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 80, 'Thickness','dot size or thickness of drawn line in pixel',  0,  12,  0);
    #$self->{'thickness'}  = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [1 .. 25], 1);
    $self->{'connect'} = Wx::CheckBox->new( $self, -1, '  Line');
    #$self->{'thickness'}->SetToolTip('dot size or thickness of drawn line in pixel');
    $self->{'connect'}->SetToolTip('connect the points / dots');

    my $row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row1->Add( $self->{'length'},  0, &Wx::wxALIGN_LEFT| &Wx::wxGROW | &Wx::wxLEFT, 10);
#    $row1->AddSpacer(20);
    $row1->Add( $self->{'density'}, 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW| &Wx::wxLEFT, 10);
    $row1->Add( 0, 0, &Wx::wxEXPAND);
    
    my $row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row2->AddSpacer(  15 );
    $row2->Add( $self->{'connect'},    0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 5);
    $row2->AddSpacer( 191 );
   # $row2->Add( Wx::StaticText->new($self, -1, 'Thickness'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 10);
    $row2->Add( $self->{'thickness'},  0, &Wx::wxALIGN_LEFT| &Wx::wxGROW | &Wx::wxALL, 5);
   # $row2->Add( Wx::StaticText->new($self, -1, 'Px'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 10);
    $row2->Add( 0, 0, &Wx::wxEXPAND);
    
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row1, 0, &Wx::wxEXPAND );
    $sizer->AddSpacer(15);
    $sizer->Add( $row2, 0, &Wx::wxEXPAND );
    $sizer->AddSpacer(5);
    
    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ( { length => 30, density => 10, thickness => 0, connect => 1 } );
}

sub get_data {
    my ( $self ) = @_;
    {
        length    => $self->{'length'}->GetValue,
        density   => $self->{'density'}->GetValue,
        thickness => $self->{'thickness'}->GetValue,
        connect      => $self->{'connect'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/length density thickness connect/, 
}

1;
