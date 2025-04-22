
# part of a polynomial tab

package App::GUI::Juliagraph::Frame::Panel::Monomial;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderStep;

sub new {
    my ( $class, $parent, $initial_exp, $std_margin ) = @_;

    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'init_exp'} = $initial_exp // 0;
    $self->{'callback'} = sub {};

    $self->{'active'} = Wx::CheckBox->new( $self, -1, ' On', [-1,-1], [ 60, -1]);
    $self->{'active'}->SetToolTip("switch usage of this polynome on or off");
    $self->{'use_minus'} = Wx::CheckBox->new( $self, -1, ' -', [-1,-1], [ 50, -1]);
    $self->{'use_minus'}->SetToolTip('if on, this monomial will be subtracted instead of added');
    $self->{'use_log'} = Wx::CheckBox->new( $self, -1, ' log', [-1,-1], [ 60, -1]);
    $self->{'use_log'}->SetToolTip(' if on, you put a logarithm in front of this monomial term as in: z_n+1 = log( factor * z_n**exponent )');
    $self->{'use_factor'} = Wx::CheckBox->new( $self, -1, ' Factor', [-1,-1], [ 70, -1]);
    $self->{'use_factor'}->SetToolTip('if on, you employ the complex factor from the text boxes below (Re and Im) in formula z_n+1 = factor * z_n**exponent');
    $self->{'use_coor'} = Wx::CheckBox->new( $self, -1, ' Coor.', [-1,-1], [ 70, -1]);
    $self->{'use_coor'}->SetToolTip('if on, the complex factor or 1 gets multiplied with current complex pixel coordinates');


    my $exp_txt = "exponent above iterator variable z_n+1 = z_n**exponent * factor\nzero turns factor into constant";
    $self->{'lbl_exponent'} = Wx::StaticText->new($self, -1, 'E x p o n e n t :' );
    $self->{'lbl_exponent'}->SetToolTip($exp_txt);
    $self->{'exponent'} = Wx::ComboBox->new( $self, -1, 2, [-1,-1],[75, 35], [1 .. 16]);
    $self->{'exponent'}->SetToolTip($exp_txt);

    $self->{'lbl_rf'} = Wx::StaticText->new($self, -1, 'Re : ' );
    $self->{'lbl_if'} = Wx::StaticText->new($self, -1, 'Im : ' );
    $self->{'lbl_rf'}->SetToolTip('real value part of factor');
    $self->{'lbl_if'}->SetToolTip('imaginary value part of factor');

    $self->{'factor_r'}  = Wx::TextCtrl->new( $self, -1, 0, [-1, -1],  [-1, 30] );
    $self->{'factor_i'}  = Wx::TextCtrl->new( $self, -1, 0, [-1, -1],  [-1, 30] );
    $self->{'factor_r'}->SetToolTip('real value part of factor');
    $self->{'factor_i'}->SetToolTip('imaginary value part of factor');
    $self->{'button_r'}  = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 160, 3, 0.3, 4, 2 );
    $self->{'button_i'}  = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 160, 3, 0.3, 4, 2, );

    $self->{'button_r'}->SetCallBack(sub { $self->{'factor_r'}->SetValue( $self->{'factor_r'}->GetValue + shift ) });
    $self->{'button_i'}->SetCallBack(sub { $self->{'factor_i'}->SetValue( $self->{'factor_i'}->GetValue + shift ) });


    Wx::Event::EVT_CHECKBOX( $self, $self->{'active'},     sub { $self->enable_monomial( $self->{'active'}->GetValue ); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'use_factor'}, sub { $self->enable_factor( $self->{'use_factor'}->GetValue ); $self->{'callback'}->(); });
    Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'callback'}->() }) for qw/use_minus use_log use_coor/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'callback'}->() }) for qw/exponent/;
    Wx::Event::EVT_TEXT( $self, $self->{$_},     sub { $self->{'callback'}->() }) for qw/factor_r factor_i/;

    $std_margin //= 10;
    my $std  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box  = $std | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $item = $std | &Wx::wxLEFT | &Wx::wxRIGHT;
    my $row  = $std | &Wx::wxTOP;
    my $first_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $first_sizer->AddSpacer( $std_margin );
    $first_sizer->Add( $self->{'active'},       0, $box,  5);
    $first_sizer->AddSpacer( $std_margin - 1 );
    $first_sizer->Add( $self->{'use_minus'},    0, $box,  5);
    $first_sizer->AddSpacer( $std_margin - 9);
    $first_sizer->Add( $self->{'use_factor'},   0, $box,  5);
    $first_sizer->AddSpacer( $std_margin + 7);
    $first_sizer->Add( $self->{'use_coor'},     0, $box,  5);
    $first_sizer->AddSpacer( $std_margin + 1);
    $first_sizer->Add( $self->{'use_log'},      0, $box,  5);
    $first_sizer->AddStretchSpacer( );
    $first_sizer->Add( $self->{'lbl_exponent'}, 0, $box, 13);
    $first_sizer->AddSpacer( 10 );
    $first_sizer->Add( $self->{'exponent'},     0, $box,  5);
    $first_sizer->AddSpacer( $std_margin+2 );

    my $r_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_sizer->AddSpacer( $std_margin );
    $r_sizer->Add( $self->{'lbl_rf'},     0, $box, 12);
    $r_sizer->AddSpacer( 5 );
    $r_sizer->Add( $self->{'factor_r'},   1, $box,  5);
    $r_sizer->Add( $self->{'button_r'},   0, $box,  5);
    $r_sizer->AddSpacer( $std_margin );

    my $i_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $i_sizer->AddSpacer( $std_margin );
    $i_sizer->Add( $self->{'lbl_if'},     0, $box, 12);
    $i_sizer->AddSpacer( 5 );
    $i_sizer->Add( $self->{'factor_i'},   1, $box,  5);
    $i_sizer->Add( $self->{'button_i'},   0, $box,  5);
    $i_sizer->AddSpacer( $std_margin );

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $first_sizer, 0, $row,  0 );
    $sizer->Add( $r_sizer,     0, $row, 10 );
    $sizer->Add( $i_sizer,     0, $row,  5 );
    $sizer->AddSpacer( 10 );
    $self->SetSizer($sizer);
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_settings ({ active => $self->{'init_exp'} == 2, # only second is on by default
                           use_log => 0, use_factor => 1, use_minus => 0, use_coor => 0,
                           factor_r => 1, factor_i => 1, exponent => $self->{'init_exp'}, } );
}
sub get_settings {
    my ( $self ) = @_;
    {
        active     => $self->{'active'}->GetValue   ? $self->{'active'}->GetValue : 0,
        use_log    => $self->{'use_log'}->GetValue ? $self->{'use_log'}->GetValue : 0,
        use_minus  => $self->{'use_minus'}->GetValue ? $self->{'use_minus'}->GetValue : 0,
        use_factor => $self->{'use_factor'}->GetValue ? $self->{'use_factor'}->GetValue : 0,
        use_coor   => $self->{'use_coor'}->GetValue ? $self->{'use_coor'}->GetValue : 0,
        factor_r   => $self->{'factor_r'}->GetValue ? $self->{'factor_r'}->GetValue : 0,
        factor_i   => $self->{'factor_i'}->GetValue ? $self->{'factor_i'}->GetValue : 0,
        exponent   => $self->{'exponent'}->GetStringSelection,
    }
}
sub set_settings {
    my ( $self, $settings ) = @_;
    return 0 unless ref $settings eq 'HASH';
    $self->PauseCallBack();
    for my $key (qw/active use_log use_minus use_factor use_coor factor_r factor_i/){
        next unless exists $settings->{$key};
        $self->{$key}->SetValue( $settings->{$key} );
    }
    for my $key (qw/exponent/){
        next unless exists $settings->{$key};
        $self->{$key}->SetSelection( $self->{$key}->FindString( $settings->{$key}) );
    }
    $self->enable_factor( $settings->{'use_factor'} );
    $self->enable_monomial( $settings->{'active'} );
    $self->RestoreCallBack();
    1;
}

sub enable_monomial {
    my ( $self, $on ) = @_;
    $self->{$_}->Enable( $on ) for qw/use_minus use_log use_factor
     lbl_rf lbl_if factor_r factor_i  button_r button_i lbl_exponent exponent/;
    $self->enable_factor if int $on;
    $self->{'use_coor'}->Enable(1) if $on and $self->{'enable_coor'};
}

sub enable_factor {
    my ( $self, $on ) = @_;
    $on //= $self->{'use_factor'}->GetValue;
    $self->{$_}->Enable( $on ) for qw/factor_r factor_i button_r button_i lbl_rf lbl_if/;
    $self->{'use_factor'}->SetValue( $on ) unless int $self->{'use_factor'}->GetValue == int $on;
}

sub enable_coor {
    my ( $self, $on ) = @_;
    $self->{'enable_coor'} = $on;
    if ($on){
        $self->{'use_coor'}->Enable( 1 ) if $self->{'active'}->GetValue;
    } else {
        $self->{'use_coor'}->SetValue( 0 );
        $self->{'use_coor'}->Enable( 0 );
    }
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
