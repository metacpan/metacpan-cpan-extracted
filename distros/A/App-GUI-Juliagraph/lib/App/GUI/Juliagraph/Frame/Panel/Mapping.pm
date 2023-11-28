use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Panel::Mapping;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderStep;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    my $color_lbl = Wx::StaticText->new($self, -1, 'C o l o r : ' );
    my $sel_lbl  = Wx::StaticText->new($self, -1, 'S e l e c t : ' );
    my $repeat_lbl = Wx::StaticText->new($self, -1, 'R e p e a t : ' );
    my $group_lbl  = Wx::StaticText->new($self, -1, 'G r o u p i n g : ' );
    my $grad_lbl  = Wx::StaticText->new($self, -1, 'G r a d i e n t : ' );
    my $dyn_lbl  = Wx::StaticText->new($self, -1, 'D y n a m i c s : ' );
    # my $smooth_lbl = Wx::StaticText->new($self, -1, 'S m o o t h : ' );
    # my $sub_lbl = Wx::StaticText->new($self, -1, 'S u b s t e p s : ' );
    $color_lbl->SetToolTip('use chosen color selection or just simple gray scale');
    $sel_lbl->SetToolTip('tonly use the first n selected colors');
    $repeat_lbl->SetToolTip('how many times repeat the configured color rainbow');
    $group_lbl->SetToolTip('how many neighbouring stop values are being translated into one color');
    $grad_lbl->SetToolTip('how many shades has a gradient between two selected colors');
    $dyn_lbl->SetToolTip('how many big is the slant of a color gradient in one or another direction');
    #$smooth_lbl->SetToolTip('how many big is the slant of a color gradient in one or another direction');
    #$sub_lbl->SetToolTip('how many big is the slant of a color gradient in one or another direction');

    $self->{'color'}     = Wx::CheckBox->new( $self, -1, '', [-1,-1],[45, -1]);
    $self->{'select'}    = Wx::ComboBox->new( $self, -1, 8, [-1,-1],[65, -1], [1..8]);
    $self->{'repeat'}    = Wx::ComboBox->new( $self, -1, 256, [-1,-1],[65, -1], [1..20]);
    #$self->{'smooth'}   = Wx::CheckBox->new( $self, -1, '', [-1,-1],[45, -1]);
    $self->{'group'}     = Wx::ComboBox->new( $self, -1,  1,  [-1,-1],[75, -1], [1,  2,  3,  5, 8, 10, 13, 17, 20, 25, 30, 35, 40, 45, 50, 60, 70, 85]);
    $self->{'gradient'}  = Wx::ComboBox->new( $self, -1, 25,  [-1,-1],[75, -1], [0, 1,  2,  3,  4, 5, 6, 7, 8, 10, 12, 15, 20, 25, 30, 35, 40, 50]);
    $self->{'dynamics'}  = Wx::ComboBox->new( $self, -1, 0,  [-1,-1],[75, -1], [-10 .. 10]);
    #$self->{'substeps'} = Wx::ComboBox->new( $self, -1, 25,  [-1,-1],[75, -1], [1,  2,  3,  4, 5, 6, 7, 8, 10, 12, 15, 20, 25, 30, 35, 40]);
    $self->{'color'}->SetToolTip('use chosen color selection or just simple gray scale');
    $self->{'repeat'}->SetToolTip('take first color again when ran out of colors');
    $self->{'select'}->SetToolTip('the first n stop values are translated into colors');
    $self->{'group'}->SetToolTip('how many neighbouring stop values are being translated into one color');
    $self->{'gradient'}->SetToolTip('how many shades has a gradient between two selected colors');
    $self->{'dynamics'}->SetToolTip('how many big is the slant of a color gradient in one or another direction');
    #$self->{'smooth'}->SetToolTip('');
    #$self->{'substeps'}->SetToolTip('');

    Wx::Event::EVT_CHECKBOX( $self, $self->{$_},  sub { $self->{'callback'}->() }) for qw/color/; # smooth
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_},  sub { $self->{'callback'}->() }) for qw/repeat group gradient dynamics/; # substeps
    Wx::Event::EVT_COMBOBOX( $self, $self->{'select'},  sub { $self->{'callback'}->(); $self->GetParent->GetParent->{'tab'}{'color'}->set_state_count( $self->{'select'}->GetStringSelection - 1 ) });

    my $item_prop = &Wx::wxALIGN_LEFT|&Wx::wxTOP|&Wx::wxBOTTOM|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxALIGN_CENTER_HORIZONTAL|&Wx::wxGROW;
    my $std_margin = 10;

    my $color_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $color_sizer->Add( $color_lbl,          0, $item_prop, 12);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'color'},    0, $item_prop,  0);
    $color_sizer->AddStretchSpacer();
    $color_sizer->Add( $sel_lbl,            0, $item_prop, 12);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'select'},   0, $item_prop,  0);
    $color_sizer->AddSpacer( $std_margin );

    my $shades_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $shades_sizer->Add( $group_lbl,         0, $item_prop, 12);
    $shades_sizer->AddSpacer( 10 );
    $shades_sizer->Add( $self->{'group'},   0, $item_prop,  0);
    $shades_sizer->AddStretchSpacer();
    $shades_sizer->Add( $repeat_lbl,        0, $item_prop, 12);
    $shades_sizer->AddSpacer( 10 );
    $shades_sizer->Add( $self->{'repeat'},  0, $item_prop,  4);
    $shades_sizer->AddSpacer( $std_margin );

    my $grad_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $grad_sizer->Add( $grad_lbl,            0, $item_prop, 12);
    $grad_sizer->AddSpacer( 10 );
    $grad_sizer->Add( $self->{'gradient'},  0, $item_prop,  0);
    $grad_sizer->AddStretchSpacer();
    $grad_sizer->Add( $dyn_lbl,             0, $item_prop, 12);
    $grad_sizer->AddSpacer( 10 );
    $grad_sizer->Add( $self->{'dynamics'},  0, $item_prop,  0);
    $grad_sizer->AddSpacer( $std_margin );

    my $smooth_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    #~ $smooth_sizer->Add( $smooth_lbl,         0, $item_prop, 12);
    #~ $smooth_sizer->AddSpacer( 10 );
    #~ $smooth_sizer->Add( $self->{'smooth'},   0, $item_prop,  4);
    #~ $smooth_sizer->AddStretchSpacer( );
    #~ $smooth_sizer->Add( $sub_lbl,            0, $item_prop, 12);
    #~ $smooth_sizer->AddSpacer( 10 );
    #~ $smooth_sizer->Add( $self->{'substeps'}, 0, $item_prop,  0);
    #~ $smooth_sizer->AddSpacer( $std_margin );

    my $sizer_prop = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT|&Wx::wxRIGHT;
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( $std_margin );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $color_sizer,  0, $sizer_prop, $std_margin);
    $sizer->AddSpacer( 30 );
    $sizer->Add( $grad_sizer,   0, $sizer_prop, $std_margin);
    $sizer->AddSpacer( 35 );
    $sizer->Add( $shades_sizer, 0, $sizer_prop, $std_margin);
    $sizer->AddSpacer( 30 );
    $sizer->Add( $smooth_sizer, 0, $sizer_prop, $std_margin);
    $self->SetSizer($sizer);

    $self->{'callback'} = sub {};
    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_settings ({ color => 1,      select => 8,  repeat => 1, group => 1,
                       gradient => 10, dynamics => 0,  smooth => 0, substeps => 0 } );
}

sub get_settings {
    my ( $self ) = @_;
    {
        color   => int $self->{'color'}->GetValue,
        repeat  => $self->{'repeat'}->GetStringSelection,
        select  => $self->{'select'}->GetStringSelection,
        group    => $self->{'group'}->GetStringSelection,
        gradient => $self->{'gradient'}->GetStringSelection,
        dynamics => $self->{'dynamics'}->GetStringSelection,
        # smooth  => int $self->{'smooth'}->GetValue,
        # substeps => $self->{'substeps'}->GetStringSelection,
    }
}

sub set_settings {
    my ( $self, $data ) = @_;
    return 0 unless ref $data eq 'HASH' and exists $data->{'select'};
    $self->PauseCallBack();
    for my $key (qw/color/){ # smooth
        next unless exists $data->{$key} and exists $self->{$key};
        $self->{$key}->SetValue( $data->{$key} );
    }
    for my $key (qw/select repeat group gradient dynamics/){ # substeps
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
