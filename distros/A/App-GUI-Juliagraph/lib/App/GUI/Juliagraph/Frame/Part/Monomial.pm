use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Part::Monomial;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderStep;

sub new {
    my ( $class, $parent, $initial_exp ) = @_;

    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'init_exp'} = $initial_exp // 0;
    $self->{'callback'} = sub {};

    $self->{'active'} = Wx::CheckBox->new( $self, -1, ' On', [-1,-1], [ 70, -1]);
    $self->{'active'}->SetToolTip("switch thit polynome on or off");

    $self->{'use_factor'} = Wx::CheckBox->new( $self, -1, ' Factor', [-1,-1], [ 80, -1]);
    $self->{'use_factor'}->SetToolTip('use or discard factor in formula z_n+1 = z_n**exp * factor');

    my $exp_txt = "exponent above iterator variable z_n+1 = z_n**exponent * factor\nzero turns factor into constant";
    my $exp_lbl   = Wx::StaticText->new($self, -1, 'E x p o n e n t :' );
    $exp_lbl->SetToolTip($exp_txt);
    $self->{'exponent'} = Wx::ComboBox->new( $self, -1, 2, [-1,-1],[75, 35], [0 .. 16]);
    $self->{'exponent'}->SetToolTip($exp_txt);

    my $r_lbl     = Wx::StaticText->new($self, -1, 'Re : ' );
    my $i_lbl     = Wx::StaticText->new($self, -1, 'Im : ' );
    $r_lbl->SetToolTip('real value part of factor');
    $i_lbl->SetToolTip('imaginary value part of factor');
    $self->{'factor_r'}  = Wx::TextCtrl->new( $self, -1, 0, [-1, -1],  [-1, 30] );
    $self->{'factor_i'}  = Wx::TextCtrl->new( $self, -1, 0, [-1, -1],  [-1, 30] );
    $self->{'factor_r'}->SetToolTip('real value part of factor');
    $self->{'factor_i'}->SetToolTip('imaginary value part of factor');
    $self->{'button_r'}  = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 100, 3, 0.3, 2, '<<', '>>' );
    $self->{'button_i'}  = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 100, 3, 0.3, 2, '<<', '>>' );

    $self->{'button_r'}->SetCallBack(sub { $self->{'factor_r'}->SetValue( $self->{'factor_r'}->GetValue + shift ) });
    $self->{'button_i'}->SetCallBack(sub { $self->{'factor_i'}->SetValue( $self->{'factor_i'}->GetValue + shift ) });


    Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'callback'}->() }) for qw/active use_factor/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'callback'}->() }) for qw/exponent/;
    Wx::Event::EVT_TEXT( $self, $self->{$_},     sub { $self->{'callback'}->() }) for qw/factor_r factor_i/;
    # Wx::Event::EVT_BUTTON(   $self, $self->{'reset'}, sub {  });

    my $base_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL;
    my $vert_attr = $base_attr | &Wx::wxTOP| &Wx::wxBOTTOM | &Wx::wxGROW;
    my $all_attr  = $base_attr | &Wx::wxALL;
    my $next      = $base_attr | &Wx::wxLEFT;
    my $std_margin = 10;

    my $first_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $first_sizer->AddSpacer( $std_margin );
    $first_sizer->Add( $self->{'active'},     0, $vert_attr,  5);
    $first_sizer->AddSpacer( $std_margin );
    $first_sizer->Add( $self->{'use_factor'}, 0, $vert_attr,  5);
    $first_sizer->AddStretchSpacer( );
    $first_sizer->Add( $exp_lbl,              0, $vert_attr, 12);
    $first_sizer->AddSpacer( 10 );
    $first_sizer->Add( $self->{'exponent'},   0, $vert_attr,  5);
    $first_sizer->AddSpacer( $std_margin );

    my $r_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_sizer->AddSpacer( $std_margin );
    $r_sizer->Add( $r_lbl,              0, $vert_attr, 12);
    $r_sizer->AddSpacer( 5 );
    $r_sizer->Add( $self->{'factor_r'}, 1, $all_attr, 0);
    $r_sizer->AddSpacer( 5 );
    $r_sizer->Add( $self->{'button_r'}, 0, $vert_attr, 0);

    my $i_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $i_sizer->AddSpacer( $std_margin );
    $i_sizer->Add( $i_lbl,              0, $vert_attr, 12);
    $i_sizer->AddSpacer( 5 );
    $i_sizer->Add( $self->{'factor_i'}, 1, $all_attr, 0);
    $i_sizer->AddSpacer( 5 );
    $i_sizer->Add( $self->{'button_i'}, 0, $vert_attr, 0);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5 );
    $sizer->Add( $first_sizer, 0, $vert_attr, 0 );
    $sizer->AddSpacer( 5 );
    $sizer->Add( $r_sizer,     0, $vert_attr, 0 );
    $sizer->Add( $i_sizer,     0, $vert_attr, 0 );
    $sizer->AddSpacer( 10 );
    $self->SetSizer($sizer);
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_settings ({ exponent => $self->{'init_exp'},
                           factor_r => 1, factor_i => 1, active => 0, use_factor => 1 } );
}
sub get_settings {
    my ( $self ) = @_;
    {
        active     => $self->{'active'}->GetValue   ? $self->{'active'}->GetValue : 0,
        use_factor => $self->{'use_factor'}->GetValue ? $self->{'use_factor'}->GetValue : 0,
        factor_r   => $self->{'factor_r'}->GetValue ? $self->{'factor_r'}->GetValue : 0,
        factor_i   => $self->{'factor_i'}->GetValue ? $self->{'factor_i'}->GetValue : 0,
        exponent   => $self->{'exponent'}->GetStringSelection,
    }
}
sub set_settings {
    my ( $self, $data ) = @_;
    return 0 unless ref $data eq 'HASH';
    $self->PauseCallBack();
    for my $key (qw/active use_factor factor_r factor_i/){
        next unless exists $data->{$key} and exists $self->{$key};
        $self->{$key}->SetValue( $data->{$key} );
    }
    for my $key (qw/exponent/){
        next unless exists $data->{$key} and exists $self->{$key};
        $self->{$key}->SetSelection( $self->{$key}->FindString($data->{$key}) );
    }
    $self->RestoreCallBack();
    1;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}
sub PauseCallBack {
    my ($self) = @_;
    $self->{'pause'} = $self->{'callback'};
    $self->{'callback'} = sub {};
}
sub RestoreCallBack {
    my ($self) = @_;
    return unless exists $self->{'pause'};
    $self->{'callback'} = $self->{'pause'};
    delete $self->{'pause'};
}

1;
