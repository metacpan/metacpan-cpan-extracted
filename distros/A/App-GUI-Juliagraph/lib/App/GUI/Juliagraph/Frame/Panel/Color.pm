use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Panel::Color;
use base qw/Wx::Panel/;

use App::GUI::Juliagraph::Frame::Part::ColorBrowser;
use App::GUI::Juliagraph::Frame::Part::ColorPicker;
use App::GUI::Juliagraph::Frame::Part::ColorSetPicker;
use App::GUI::Juliagraph::Widget::ColorDisplay;
use App::GUI::Juliagraph::Widget::PositionMarker;

use Graphics::Toolkit::Color qw/color/;

our $default_color_def = $App::GUI::Juliagraph::Frame::Part::ColorSetPicker::default_color;

sub new {
    my ( $class, $parent, $config ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'set_back'}  = sub {};
    $self->{'config'}     = $config;
    $self->{'rule_square_size'} = 36;
    $self->{'last_state'} = 7;   # max pos
    $self->{'state_count'} = 7;  # nr of currently used
    $self->{'current_state'} = 1;

    $self->{'state_colors'}        = [ color('white')->gradient( to => 'black', steps => $self->{'state_count'}) ];
    $self->{'state_colors'}[$_]    = color( $default_color_def ) for $self->{'state_count'} .. $self->{'last_state'};
    $self->{'state_marker'}        = [ map { App::GUI::Juliagraph::Widget::PositionMarker->new($self, $self->{'rule_square_size'}, 20, $_, '', $default_color_def) } 0 .. $self->{'last_state'} ];
    $self->{'state_pic'}[$_]       = App::GUI::Juliagraph::Widget::ColorDisplay->new($self, $self->{'rule_square_size'}, $self->{'rule_square_size'}, $_, $self->{'state_colors'}[$_]->values(as => 'hash'))
        for 0 .. $self->{'last_state'};
    $self->{'color_set_store_lbl'} = Wx::StaticText->new($self, -1, 'Color Set Store' );
    $self->{'color_set_f_lbl'}     = Wx::StaticText->new($self, -1, 'Colors Set Function' );
    $self->{'state_color_lbl'}     = Wx::StaticText->new($self, -1, 'Currently Used State Colors' );
    $self->{'curr_color_lbl'}      = Wx::StaticText->new($self, -1, 'Selected State Color' );
    $self->{'color_store_lbl'}     = Wx::StaticText->new($self, -1, 'Color Store' );

    $self->{'dynamics'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[75, -1], [ -10 ..10 ]);
    $self->{'Sdelta'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);
    $self->{'Ldelta'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);


    $self->{'btn'}{'gray'}       = Wx::Button->new( $self, -1, 'Gray',       [-1,-1], [45, 35] );
    $self->{'btn'}{'gradient'}   = Wx::Button->new( $self, -1, 'Gradient',   [-1,-1], [70, 35] );
    $self->{'btn'}{'complement'} = Wx::Button->new( $self, -1, 'Complement', [-1,-1], [90, 35] );
    $self->{'btn'}{'gray'}->SetToolTip("reset to default grey scale color pallet. Adheres to count of needed colors and current dynamics settings.");
    $self->{'btn'}{'gradient'}->SetToolTip("create gradient between first and current color. Adheres to dynamics settings.");
    $self->{'btn'}{'complement'}->SetToolTip("Create color set from first up to current color as complementary colors. Adheres to both delta values.");
    $self->{'dynamics'}->SetToolTip("dynamics of gradient (1 = linear) and also of gray scale");
    $self->{'Sdelta'}->SetToolTip("max. satuaration deviation when computing complement colors ( -100 .. 100)");
    $self->{'Ldelta'}->SetToolTip("max. lightness deviation when computing complement colors ( -100 .. 100)");


    $self->{'picker'}  = App::GUI::Juliagraph::Frame::Part::ColorPicker->new( $self, $config->get_value('color') );
    $self->{'setpicker'}  = App::GUI::Juliagraph::Frame::Part::ColorSetPicker->new( $self, $config->get_value('color_set'));
    $self->{'browser'}  = App::GUI::Juliagraph::Frame::Part::ColorBrowser->new( $self, 'state', {red => 0, green => 0, blue => 0} );
    $self->{'browser'}->SetCallBack( sub { $self->set_current_color( $_[0] ) });

    Wx::Event::EVT_LEFT_DOWN( $self->{'state_pic'}[$_], sub { $self->select_state( $_[0]->get_nr ) }) for 0 .. $self->{'last_state'};
    Wx::Event::EVT_LEFT_DOWN( $self->{'state_marker'}[$_], sub { $self->select_state( $_[0]->get_nr ) }) for 0 .. $self->{'last_state'};
    $self->{'state_pic'}[$_-1]->SetToolTip("select state color $_ to change (marked by arrow - crosses mark currently passive colors)") for 1 .. $self->{'last_state'}+1;
    $self->{'state_marker'}[$_-1]->SetToolTip("select state color $_ to change (marked by arrow - crosses mark currently passive colors)") for 1 .. $self->{'last_state'}+1;


    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'gray'}, sub {
        $self->set_all_colors( color('white')->gradient( to => 'black', steps => $self->{'state_count'}+1, dynamic => $self->{'dynamics'}->GetValue) );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'gradient'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[0]->gradient( to => $c[ $self->{'current_state'} ], in => 'RGB', steps => $self->{'current_state'}+1, dynamics => $self->{'dynamics'}->GetValue);
        $self->set_all_colors( @new_colors );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'complement'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[ $self->{'current_state'} ]->complement( steps => $self->{'current_state'}+1,
                                                                     saturation_tilt => $self->{'Sdelta'}->GetValue,
                                                                     lightness_tilt => $self->{'Ldelta'}->GetValue );
        push @new_colors, shift @new_colors;
        $self->set_all_colors( @new_colors );
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW ;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;

    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->AddSpacer( 5 );
    $f_sizer->Add( $self->{'btn'}{'gray'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'btn'}{'gradient'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'dynamics'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->AddSpacer( 25 );
    $f_sizer->Add( $self->{'btn'}{'complement'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'Sdelta'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( $self->{'Ldelta'}, 0, $std_attr|&Wx::wxALL, 5 );
    $f_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_sizer = $self->{'state_sizer'} = Wx::BoxSizer->new(&Wx::wxHORIZONTAL); # $self->{'plate_sizer'}->Clear(1);
    $state_sizer->AddSpacer( 7 );
    my @option_sizer;
    for my $state (0 .. $self->{'last_state'}){
        $option_sizer[$state] = Wx::BoxSizer->new( &Wx::wxVERTICAL );
        $option_sizer[$state]->AddSpacer( 2 );
        $option_sizer[$state]->Add( $self->{'state_pic'}[$state], 0, $all_attr, 6);
        $option_sizer[$state]->Add( $self->{'state_marker'}[$state], 0, $all_attr, 6);
        $state_sizer->Add( $option_sizer[$state], 0, $all_attr, 4);
    }
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'color_set_store_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $self->{'setpicker'}, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'color_set_f_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $f_sizer, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'state_color_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $state_sizer, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'curr_color_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $self->{'browser'}, 0, $std_attr, 0);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );
    $main_sizer->Add( $self->{'color_store_lbl'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 5);
    $main_sizer->Add( $self->{'picker'}, 0, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    $self->{'call_back'} = sub {};
    $self->init;
    $self->set_state_count( $self->{'state_count'} );
    $self->select_state ( $self->{'current_state'} );
    $self;
}

sub set_state_count {
    my ($self, $count) = @_;
    $self->{'state_count'} = $count;
    $self->{'state_marker'}[$_]->set_state('passive') for 0 .. $self->{'state_count'};
    $self->{'state_marker'}[$_]->set_state('disabled') for $self->{'state_count'}+1 .. $self->{'last_state'};
    $self->{'state_marker'}[ $self->{'current_state'} ]->set_state('active');
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub select_state {
    my ($self, $state) = @_;
    $state //= $self->{'current_state'};
    my $old_marker_state = ($self->{'current_state'} <= $self->{'state_count'}) ? 'passive' : 'disabled';
    $self->{'state_marker'}[$self->{'current_state'}]->set_state( $old_marker_state );
    $self->{'state_marker'}[ $state ]->set_state('active');
    $self->{'current_state'} = $state;
    $self->{'browser'}->set_data( $self->{'state_colors'}[$self->{'current_state'}]->rgb_hash, 'silent' );
}

sub init { $_[0]->set_settings( { 0 => '#FFFFFF', 1 => '#F9E595', 2 => '#A1680C', 3 => '#B63A3E',
                                  4 => '#777777', 5 => '#555555', 6 => '#333333', 7 => '#111111', 8 => '#000000',
                                  dynamics => 0, delta_S => 0, delta_L => 0 } )
}

sub get_settings {
    my ($self) = @_;
    my $data = {
        dynamics => $self->{'dynamics'}->GetValue,
        delta_S => $self->{'Sdelta'}->GetValue,
        delta_L => $self->{'Ldelta'}->GetValue,
    };
    $data->{$_} = $self->{'state_colors'}[$_]->values(as => 'string') for 0 .. $self->{'last_state'}+1;
    $data;
}

sub set_settings {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'dynamics'};
    $self->{'dynamics'}->SetValue( $data->{'dynamics'} );
    $self->{'Sdelta'}->SetValue( $data->{'delta_S'} );
    $self->{'Ldelta'}->SetValue( $data->{'delta_L'} );
    for (0 .. $self->{'last_state'}){
        $data->{$_} = $default_color_def unless exists $data->{$_};
    }
    $self->{'state_colors'}[$_] = color( $data->{$_} ) for 0 .. $self->{'last_state'}+1;
    $self->set_all_colors( @{$self->{'state_colors'}} );
    $self->{'objects'} = $self->{'state_colors'};
}

sub get_current_color {
    my ($self) = @_;
    $self->{'state_colors'}[$self->{'current_state'}];
}

sub set_current_color {
    my ($self, $color) = @_;
    return unless ref $color eq 'HASH';
    $self->{'state_colors'}[$self->{'current_state'}] = color( $color );
    $self->{'state_pic'}[$self->{'current_state'}]->set_color( $color );
    $self->{'browser'}->set_data( $color );
    $self->{'call_back'}->( 'color' ); # update whole app
}

sub set_all_colors {
    my ($self, @color) = @_;
    return unless @color;
    map { return if ref $_ ne 'Graphics::Toolkit::Color' } @color;
    $self->{'state_colors'}[$_] = $color[$_] for 0 .. $#color;
    # $self->{'state_colors'}[$_] = color( $default_color_def ) for $self->{'state_count'} .. $self->{'last_state'};
    $self->{'state_pic'}[$_]->set_color( $self->{'state_colors'}[$_]->rgb_hash ) for 0 .. $self->{'last_state'};
    $self->{'state_pic'}[$_]->set_color( $self->{'state_colors'}[$_]->values ) for 0 .. $self->{'last_state'};
    $self->select_state;
    # $self->{'call_back'}->( 'color' ); # update whole app
}

sub get_all_colors { @{$_[0]->{'state_colors'}} }
sub get_active_colors { @{$_[0]->{'state_colors'}}[ 0 .. $_[0]->{'state_count'} - 1] }

sub update_config {
    my ($self) = @_;
    $self->{'config'}->set_value('color',     $self->{'picker'}->get_config);
    $self->{'config'}->set_value('color_set', $self->{'setpicker'}->get_config);
    #~ $self->{'config'}->set_value('color_current',
        #~ [ map {$self->{'state_colors'}[$_]->values(as => 'string')} 0 .. $self->{'last_state'} ]);
}



1;
