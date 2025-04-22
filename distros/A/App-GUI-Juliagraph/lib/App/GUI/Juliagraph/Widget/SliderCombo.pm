
# slider widget with display of value and nudge buttons

package App::GUI::Juliagraph::Widget::SliderCombo;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $slider_size, $label, $help, $min, $max, $init_value, $delta, $value_name ) = @_;
    return unless defined $max;

    my $self = $class->SUPER::new( $parent, -1);
    my $lbl  = Wx::StaticText->new($self, -1, $label);
    $self->{'min_value'} = $min;
    $self->{'max_value'} = $max;
    $self->{'init_value'} = $init_value;
    $self->{'name'} = $label;
    $self->{'help'} = $help;
    $self->{'value'} = $init_value // $min;
    $self->{'value_delta'} = $delta // 1;
    $self->{'callback'} = sub {};
    return unless $self->{'value_delta'} != 0;

    my @l = map {length $_} $min, $min+$self->{'value_delta'}, $max-$self->{'value_delta'}, $max;
    my $max_txt_size = 0;
    map {$max_txt_size = $_ if $max_txt_size < $_} @l;
    $self->{'widget'}{'txt'} = Wx::TextCtrl->new( $self, -1, $init_value, [-1,-1], [(6 * $max_txt_size) + 26,-1], &Wx::wxTE_RIGHT);
    $self->{'widget'}{'button'}{'-'} = Wx::Button->new( $self, -1, '-', [-1,-1],[27, 27] );
    $self->{'widget'}{'button'}{'+'} = Wx::Button->new( $self, -1, '+', [-1,-1],[27, 27] );

    $self->{'widget'}{'slider'} = Wx::Slider->new(
        $self, -1, $init_value / $self->{'value_delta'}, $min / $self->{'value_delta'}, $max / $self->{'value_delta'},
        [-1, -1], [$slider_size, -1], &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM ) if defined $slider_size and $slider_size;

    $lbl->SetToolTip( $help );
    $self->{'widget'}{'txt'}->SetToolTip( $help );
    $self->{'widget'}{'slider'}->SetToolTip( $help ) if exists $self->{'widget'}{'slider'};
    $self->{'widget'}{'button'}{'-'}->SetToolTip( 'decrease '.((defined $value_name) ? $value_name.' ':'').'by '.$self->{'value_delta'} );
    $self->{'widget'}{'button'}{'+'}->SetToolTip( 'increase '.((defined $value_name) ? $value_name.' ':'').'by '.$self->{'value_delta'} );

    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    my $attr = &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_LEFT;
    $sizer->Add( $lbl,                             0, $attr,  5);
    $sizer->Add( $self->{'widget'}{'txt'},         0, $attr, 10);
    $sizer->Add( $self->{'widget'}{'button'}{'-'}, 0, $attr,  0);
    $sizer->Add( $self->{'widget'}{'button'}{'+'}, 0, $attr,  0);
    $sizer->Add( $self->{'widget'}{'slider'},      0, $attr, 10);
    $sizer->Add( 0,     1, &Wx::wxEXPAND|&Wx::wxGROW);
    $self->SetSizer($sizer);

    Wx::Event::EVT_TEXT( $self, $self->{'widget'}{'txt'}, sub {
        my ($self, $cmd) = @_;
        my $value = $cmd->GetString;
        $value = $self->{'init_value'} if not defined $value;
        $self->SetValue( $value );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'-'}, sub {
        $self->SetValue( $self->{'value'} - $self->{'value_delta'} )
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'+'}, sub {
        $self->SetValue( $self->{'value'} + $self->{'value_delta'} )
    });
    Wx::Event::EVT_SLIDER( $self, $self->{'widget'}{'slider'},   sub {
        my ($self, $cmd) = @_;
        $self->SetValue( $cmd->GetInt * $self->{'value_delta'} );
    }) if defined $self->{'widget'}{'slider'};

    return $self;
}

sub GetValue { $_[0]->{'value'} }

sub SetValue {
    my ( $self, $value, $passive) = @_;
    return if not defined $value or $self->{'value'} == $value or exists $self->{'no_recursive_events'};
    $value = $self->{'value_delta'} * int( $value / $self->{'value_delta'}) if $self->{'value_delta'};
    $value = $self->{'min_value'} if int($value) < $self->{'min_value'};
    $value = $self->{'max_value'} if int($value) > $self->{'max_value'};
    return if $self->{'value'} == $value;
    $self->{'no_recursive_events'}++;

    $self->{'value'} = $value;
    my $slider_val = $value / $self->{'value_delta'};
    $self->{'widget'}{'button'}{'-'}->Enable( $value != $self->{'min_value'} );
    $self->{'widget'}{'button'}{'+'}->Enable( $value != $self->{'max_value'} );
    $self->{'widget'}{'txt'}->SetValue( $value ) unless $value == $self->{'widget'}{'txt'}->GetValue;
    $self->{'widget'}{'slider'}->SetValue( $slider_val ) if
        defined $self->{'widget'}{'slider'} and $slider_val != $self->{'widget'}{'slider'}->GetValue;
    $self->{'callback'}->( $value ) unless defined $passive;
    delete $self->{'no_recursive_events'}
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

sub fractional_modulo {
    my ($value, $mod) = @_;
    my $div = int $value / $mod;
    return ($value - ($div * $mod));
}

1;
