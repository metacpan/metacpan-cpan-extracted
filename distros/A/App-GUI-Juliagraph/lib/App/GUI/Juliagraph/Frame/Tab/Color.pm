
# color selection page

package App::GUI::Juliagraph::Frame::Tab::Color;
use base qw/Wx::Panel/;
use v5.12;
use warnings;
use Wx;
use App::GUI::Juliagraph::Frame::Panel::ColorBrowser;
use App::GUI::Juliagraph::Frame::Panel::ColorPicker;
use App::GUI::Juliagraph::Frame::Panel::ColorSetPicker;
use App::GUI::Juliagraph::Widget::ColorDisplay;
use App::GUI::Juliagraph::Widget::PositionMarker;
use Graphics::Toolkit::Color qw/color/;

our $default_color_def = $App::GUI::Juliagraph::Frame::Panel::ColorSetPicker::default_color;
my $default_settings = { 1=> 'black', 2=> 'red', 3=> 'orange', 4 => 'blue',
                         tilt => 0, delta_S => 0, delta_L => 0 };

sub new {
    my ( $class, $parent, $config, $size ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'call_back'}  = sub {};
    $self->{'config'}     = $config;
    $self->{'color_count'} = $size;     # number of displayed colors
    $self->{'active_color_count'} = 4;  # nr of currently used colors, overwritten on init
    $self->{'current_color_nr'} = 0;    # index starts from 0
    $self->{'display_size'} = 30;

    $self->{'used_colors'}     = [ color('blue')->gradient( to => 'red', steps => $self->{'active_color_count'}) ];
    $self->{'used_colors'}[$_] = color( $default_color_def ) for $self->{'active_color_count'} .. $self->{'color_count'}-1;
    $self->{'color_marker'}    = [ map { App::GUI::Juliagraph::Widget::PositionMarker->new
                                           ($self, $self->{'display_size'}, 20, $_, '', $default_color_def) } 0 .. $self->{'color_count'}-1 ];
    $self->{'color_display'}[$_] = App::GUI::Juliagraph::Widget::ColorDisplay->new
        ($self, $self->{'display_size'}-2, $self->{'display_size'},
         $_, $self->{'used_colors'}[$_]->values(as => 'hash')      ) for 0 .. $self->{'color_count'}-1;
    $self->{'color_marker'}[$_-1]->SetToolTip("color $_, to change (marked by arrow - crosses mark currently passive colors)") for 1 .. $self->{'color_count'}-1;
    $self->{'color_display'}[$_-1]->SetToolTip("color $_, to change (marked by arrow - crosses mark currently passive colors)") for 1 .. $self->{'color_count'}-1;
    $self->{'color_marker'}[$size-1]->SetToolTip("lost color, often background color, shown where values do not converge");
    $self->{'color_display'}[$size-1]->SetToolTip("last color, often background color, shown where values do not converge");

    $self->{'label'}{'color_set_store'} = Wx::StaticText->new($self, -1, 'Color Set Store' );
    $self->{'label'}{'color_set_funct'} = Wx::StaticText->new($self, -1, 'Colors Set Function' );
    $self->{'label'}{'used_colors'}     = Wx::StaticText->new($self, -1, 'Currently Used Colors' );
    $self->{'label'}{'selected_color'}  = Wx::StaticText->new($self, -1, 'Selected Color' );
    $self->{'label'}{'color_store'}     = Wx::StaticText->new($self, -1, 'Color Store' );

    $self->{'widget'}{'tilt'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1], [80, -1], [ -6, -5, -4, -3, -2.5, -2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6]);
    $self->{'widget'}{'delta_S'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);
    $self->{'widget'}{'delta_L'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [50,-1], &Wx::wxTE_RIGHT);

    $self->{'button'}{'gradient'}   = Wx::Button->new( $self, -1, 'Gradient',   [-1,-1], [ 75, 17] );
    $self->{'button'}{'complement'} = Wx::Button->new( $self, -1, 'Complement', [-1,-1], [100, 17] );
    $self->{'button'}{'left'}  = Wx::Button->new( $self, -1, '<', [-1,-1], [30, 17] );
    $self->{'button'}{'right'} = Wx::Button->new( $self, -1, '>', [-1,-1], [30, 17] );
    $self->{'button'}{'left'}->SetToolTip("Move currently selected color to the left.");
    $self->{'button'}{'right'}->SetToolTip("Move currently selected color to the left.");
    $self->{'button'}{'gradient'}->SetToolTip("Create gradient between first and current color. Adheres to tilt settings.");
    $self->{'button'}{'complement'}->SetToolTip("Create color set from first up to current color as complementary colors. Adheres to both delta values.");
    $self->{'widget'}{'tilt'}->SetToolTip("tilt of gradient (0 = linear) and also of gray scale");
    $self->{'widget'}{'delta_S'}->SetToolTip("max. satuaration deviation when computing complement colors ( -100 .. 100)");
    $self->{'widget'}{'delta_L'}->SetToolTip("max. lightness deviation when computing complement colors ( -100 .. 100)");


    $self->{'picker'}    = App::GUI::Juliagraph::Frame::Panel::ColorPicker->new( $self, $config->get_value('color') );
    $self->{'setpicker'} = App::GUI::Juliagraph::Frame::Panel::ColorSetPicker->new( $self, $config->get_value('color_set'), $self->{'color_count'});

    $self->{'browser'}   = App::GUI::Juliagraph::Frame::Panel::ColorBrowser->new( $self, 'selected', {red => 0, green => 0, blue => 0} );
    $self->{'browser'}->SetCallBack( sub { $self->set_current_color( $_[0] ) });

    Wx::Event::EVT_LEFT_DOWN( $self->{'color_display'}[$_], sub { $self->set_current_color_nr( $_[0]->get_nr ) }) for 0 .. $self->{'color_count'}-1;
    Wx::Event::EVT_LEFT_DOWN( $self->{'color_marker'}[$_], sub { $self->set_current_color_nr( $_[0]->get_nr ) }) for 0 .. $self->{'color_count'}-1;

    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'gradient'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[0]->gradient( to => $c[ $self->{'current_color_nr'} ], in => 'RGB',
                                       steps => $self->{'current_color_nr'}+1,
                                        tilt => $self->{'widget'}{'tilt'}->GetValue );
        $self->set_all_colors( @new_colors );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'complement'}, sub {
        my @c = $self->get_all_colors;
        my @new_colors = $c[ $self->{'current_color_nr'} ]->complement( steps => $self->{'current_color_nr'}+1,
                                                                       target => {
                                                                              s => $self->{'widget'}{'delta_S'}->GetValue,
                                                                              l => $self->{'widget'}{'delta_L'}->GetValue
                                                                           },);
        $self->set_all_colors( @new_colors );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'left'}, sub {
        my $pos = $self->get_current_color_nr;
        my @colors = $self->get_all_colors;
        my $selected = splice @colors, $pos, 1;
        $pos--;
        $pos = $self->{'color_count'} - 1 if $pos < 0;
        splice @colors, $pos, 0, $selected;
        $self->set_all_colors( @colors );
        $self->set_current_color_nr( $pos );
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'right'}, sub {
        my $pos = $self->get_current_color_nr;
        my @colors = $self->get_all_colors;
        my $selected = splice @colors, $pos, 1;
        $pos++;
        $pos = 0 if $pos >= $self->{'color_count'};
        splice @colors, $pos, 0, $selected;
        $self->set_all_colors( @colors );
        $self->set_current_color_nr( $pos );
    });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW ;
    my $all_attr = $std_attr | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $next_attr = &Wx::wxGROW | &Wx::wxTOP | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->AddSpacer( 10 );
    $f_sizer->Add( $self->{'button'}{'gradient'},  0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'tilt'},      0, $all_attr, 5 );
    $f_sizer->AddSpacer( 20 );
    $f_sizer->Add( $self->{'button'}{'complement'},0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'delta_S'},   0, $all_attr, 5 );
    $f_sizer->Add( $self->{'widget'}{'delta_L'},   0, $all_attr, 5 );
    $f_sizer->AddSpacer( 20 );
    $f_sizer->Add( $self->{'button'}{'left'},      0, $all_attr, 5 );
    $f_sizer->Add( $self->{'button'}{'right'},     0, $all_attr, 5 );
    $f_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_sizer = $self->{'state_sizer'} = Wx::BoxSizer->new(&Wx::wxHORIZONTAL); # $self->{'plate_sizer'}->Clear(1);
    $state_sizer->AddSpacer( 12 );
    my @option_sizer;
    for my $nr (0 .. $self->{'color_count'}-1){
        #$state_sizer->AddSpacer( 1 );
        $option_sizer[$nr] = Wx::BoxSizer->new( &Wx::wxVERTICAL );
        $option_sizer[$nr]->AddSpacer( 2 );
        $option_sizer[$nr]->Add( $self->{'color_display'}[$nr],0, $all_attr, 3);
        $option_sizer[$nr]->Add( $self->{'color_marker'}[$nr], 0, $all_attr, 3);
        $state_sizer->Add( $option_sizer[$nr],                 0, $all_attr, 6);
        #$state_sizer->AddSpacer( 1 );
    }
    $state_sizer->Insert( 11, Wx::StaticLine->new( $self, -1,[-1,-1],[-1,-1], &Wx::wxLI_VERTICAL), 0, &Wx::wxGROW);
    $state_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_set_store'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $self->{'setpicker'},                0, $all_attr,                       10);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_set_funct'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $f_sizer,                            0, $all_attr,                       10);
    $sizer->AddSpacer(  2 );
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'used_colors'},     0, &Wx::wxALIGN_CENTER_HORIZONTAL,   0);
    $sizer->Add( $state_sizer,                        0, $all_attr,                        5);
    $sizer->AddSpacer(  5 );
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $all_attr,                        0);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'selected_color'},  0, &Wx::wxALIGN_CENTER_HORIZONTAL,  10);
    $sizer->Add( $self->{'browser'},                  0, $next_attr, 10);
    $sizer->Add( Wx::StaticLine->new( $self, -1),     0, $next_attr,  8);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'color_store'},     0, &Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $sizer->Add( $self->{'picker'},                   0, $std_attr| &Wx::wxLEFT,         10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $sizer );
    $self->set_active_color_count( $self->{'active_color_count'} );
    $self->set_current_color_nr ( $self->{'current_color_nr'} );
    $self->init;
    $self;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub set_active_color_count {
    my ($self, $count) = @_;
    return unless defined $count and $count > 1 and $count < 11;
    $self->{'active_color_count'} = $count;
    $self->{'color_marker'}[$_]->set_state('passive') for 0 .. $self->{'active_color_count'}-1;
    $self->{'color_marker'}[$_]->set_state('disabled') for $self->{'active_color_count'} .. $self->{'color_count'}-1;
    $self->{'color_marker'}[ $self->{'current_color_nr'} ]->set_state('active');
}

sub get_current_color_nr { $_[0]->{'current_color_nr'} }
sub set_current_color_nr {
    my ($self, $nr) = @_;
    $nr //= $self->{'current_color_nr'};
    my $old_marker_state = ($self->{'current_color_nr'} < $self->{'active_color_count'}) ? 'passive' : 'disabled';
    $self->{'color_marker'}[$self->{'current_color_nr'}]->set_state( $old_marker_state );
    $self->{'color_marker'}[ $nr ]->set_state('active');
    $self->{'current_color_nr'} = $nr;
    $self->{'browser'}->set_data( $self->{'used_colors'}[$self->{'current_color_nr'}]->values(as => 'hash'), 'silent' );
}

sub init { $_[0]->set_settings( $default_settings ) }

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'tilt'};
    $self->{'widget'}{$_}->SetValue( $settings->{$_} // $default_settings->{$_} ) for qw/tilt delta_S delta_L/;
    $self->set_all_colors( grep {defined $_} map {$settings->{$_}} 1 .. $self->{'color_count'} );
}

sub get_state    { $_[0]->get_settings }
sub get_settings {
    my ($self) = @_;
    my $data = {
        tilt => $self->{'widget'}{'tilt'}->GetValue,
        delta_S => $self->{'widget'}{'delta_S'}->GetValue,
        delta_L => $self->{'widget'}{'delta_L'}->GetValue,
    };
    $data->{$_} = $self->{'used_colors'}[$_-1]->values(as => 'hex_string') for 1 .. $self->{'color_count'};
    $data;
}

sub get_current_color {
    my ($self) = @_;
    $self->{'used_colors'}[$self->{'current_color_nr'}];
}

sub set_current_color {
    my ($self, $color) = @_;
    return unless ref $color eq 'HASH';
    $self->{'used_colors'}[$self->{'current_color_nr'}] = color( $color );
    $self->{'color_display'}[$self->{'current_color_nr'}]->set_color( $color );
    $self->{'browser'}->set_data( $color );
    $self->{'call_back'}->( 'color' ); # update whole app
}

sub set_all_colors {
    my ($self, @colors) = @_;
    return unless @colors;
    for my $i (0 .. $#colors){
        my $temp = $colors[ $i ];
        $colors[ $i ] = color( $temp ) if ref $temp ne 'Graphics::Toolkit::Color';
        return "value number $i: $temp is no color" if ref $colors[ $i ] ne 'Graphics::Toolkit::Color';
    }
    $self->{'used_colors'} = [@colors];
    $self->{'used_colors'}[$_] = color( $default_color_def ) for @colors .. $self->{'color_count'}-1;
    $self->{'color_display'}[$_]->set_color( $self->{'used_colors'}[$_]->values(as => 'hash') ) for 0 .. $self->{'color_count'}-1;
    $self->set_current_color_nr;
    $self->{'call_back'}->( 'color' ); # update whole app
}

sub get_all_colors { @{$_[0]->{'used_colors'}} }
sub get_active_colors { @{$_[0]->{'used_colors'}}[ 0 .. $_[0]->{'active_color_count'} - 1] }

sub update_config {
    my ($self) = @_;
    $self->{'config'}->set_value('color',     $self->{'picker'}->get_config);
    $self->{'config'}->set_value('color_set', $self->{'setpicker'}->get_config);
}



1;
