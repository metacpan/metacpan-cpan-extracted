use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Widget::SliderCombo;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $slider_size, $label, $help, $min, $max, $init_value, $delta ) = @_;
    return unless defined $max;

    my $self = $class->SUPER::new( $parent, -1);
    my $lbl  = Wx::StaticText->new($self, -1, $label);
    $self->{'min'} = $min;
    $self->{'max'} = $max;
    $self->{'name'} = $label;
    $self->{'value'} = $init_value // $min;
    $self->{'delta'} = $delta // 1;
    $self->{'callback'} = sub {};

    $self->{'txt'}      = Wx::TextCtrl->new( $self, -1, $init_value, [-1,-1], [26 + 4 * int(log $max),-1], &Wx::wxTE_RIGHT);
    $self->{'btn'}{'-'} = Wx::Button->new( $self, -1, '-', [-1,-1],[30, 30] );
    $self->{'btn'}{'+'} = Wx::Button->new( $self, -1, '+', [-1,-1],[30, 30] );

    $self->{'slider'} = Wx::Slider->new( $self, -1, $init_value, $min, $max, [-1, -1], [$slider_size, -1],
                                                &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM );

    $lbl->SetToolTip( $help );
    $self->{'txt'}->SetToolTip( $help );
    $self->{'slider'}->SetToolTip( $help );
    $self->{'btn'}{'-'}->SetToolTip( "decrease by ".$self->{'delta'} );
    $self->{'btn'}{'+'}->SetToolTip( "increase by ".$self->{'delta'} );

    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->Add( $lbl,  0, &Wx::wxALL| &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxALIGN_LEFT, 12);
    $sizer->Add( $self->{'txt'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $sizer->Add( $self->{'btn'}{'-'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $sizer->Add( $self->{'btn'}{'+'}, 0, &Wx::wxGROW | &Wx::wxTOP | &Wx::wxBOTTOM | &Wx::wxALIGN_CENTER_VERTICAL, 5);
    $sizer->Add( $self->{'slider'}, 0, &Wx::wxGROW | &Wx::wxALL| &Wx::wxALIGN_CENTER_VERTICAL, 8);
    $sizer->Add( 0,     1, &Wx::wxEXPAND|&Wx::wxGROW);
    $self->SetSizer($sizer);

    Wx::Event::EVT_TEXT( $self, $self->{'txt'}, sub {
        my ($self, $cmd) = @_;
        my $value = $cmd->GetString;
        $value = $self->{'min'} if not defined $value or not $value or $value < $self->{'min'};
        if ($value > $self->{'max'}) {
            my $pos = index $value, $self->GetValue();
            $value = substr ($value, 0, $pos) . substr ($value, $pos + length( $self->GetValue() )) if $pos > -1;
            $value = $self->{'max'} if $value > $self->{'max'};
        }
        $self->SetValue( $value);
    });


    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'-'}, sub {
        my $value = $self->{'value'};
         $value -= ($value % $self->{'delta'} ? $value % $self->{'delta'} : $self->{'delta'});
        $value = $self->{'min'} if $value < $self->{'min'};
        $self->SetValue( $value );
    });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'+'}, sub {
        my $value = $self->{'value'};
        $value += $self->{'delta'} - ($value % $self->{'delta'});
        $value = $self->{'max'} if $value > $self->{'max'};
        $self->SetValue( $value );
    });

    Wx::Event::EVT_SLIDER( $self, $self->{'slider'}, sub {
        my ($self, $cmd) = @_;
        $self->SetValue( $cmd->GetInt );
    });

    return $self;
}

sub GetValue { $_[0]->{'value'} }

sub SetValue {
    my ( $self, $value, $passive) = @_;
    $value = $self->{'min'} if $value < $self->{'min'};
    $value = $self->{'max'} if $value > $self->{'max'};
    return if $self->{'value'} == $value;
    $self->{'value'} = $value;

    $self->{'btn'}{'-'}->Enable( $value != $self->{'min'} );
    $self->{'btn'}{'+'}->Enable( $value != $self->{'max'} );
    $self->{'txt'}->SetValue( $value ) unless $value == $self->{'txt'}->GetValue;
    $self->{'slider'}->SetValue( $value ) unless $value == $self->{'slider'}->GetValue;
    $self->{'callback'}->( $value ) unless defined $passive;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}


1;
