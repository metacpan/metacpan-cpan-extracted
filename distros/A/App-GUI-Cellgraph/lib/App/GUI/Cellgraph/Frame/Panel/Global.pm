use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Global;
use base qw/Wx::Panel/;
# use App::GUI::Cellgraph::Widget::SliderCombo;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);
    $self->{'call_back'} = sub {};
    
    
    $self->{'data_keys'} = [qw/grid_type cell_size paint_direction circular_grid state_count input_size/];#action_values action_threshold
    $self->{'grid_lbl'} = Wx::StaticText->new( $self, -1, 'Grid Style:');
    $self->{'cell_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    $self->{'direction_lbl'} = Wx::StaticText->new( $self, -1, 'Direction :');
    $self->{'input_size_lbl'} = Wx::StaticText->new( $self, -1, 'Input :');
    $self->{'state_ab_lbl'} = Wx::StaticText->new( $self, -1, 'Cell States :');
    $self->{'circular_grid'} = Wx::CheckBox->new( $self, -1, '  Circular');
    # $self->{'action_ab_lbl'} = Wx::StaticText->new( $self, -1, 'Action Values :');
    # $self->{'threshhold_lbl'} = Wx::StaticText->new( $self, -1, 'Threshold :');
    $self->{'grid_type'} = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[95, -1], ['lines', 'gaps', 'no']);
    $self->{'cell_size'} = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[75, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'paint_direction'} = Wx::ComboBox->new( $self, -1, 'top_down', [-1,-1],[120, -1], [qw/top_down outside_in inside_out/], &Wx::wxTE_READONLY);
    $self->{'state_count'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    $self->{'input_size'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7/], &Wx::wxTE_READONLY);
    # $self->{'action_values'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[75, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    # $self->{'action_threshold'} = Wx::ComboBox->new( $self, -1, '1', [-1,-1],[75, -1], [qw/0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2/], &Wx::wxTE_READONLY);
    
    $self->{'grid_lbl'}->SetToolTip('how to display the cell map');
    $self->{'grid_type'}->SetToolTip('how to display the cell map');
    $self->{'cell_size_lbl'}->SetToolTip('visual size of the cells in pixel');
    $self->{'cell_size'}->SetToolTip('visual size of the cells in pixel');
    $self->{'direction_lbl'}->SetToolTip('painting direction');
    $self->{'paint_direction'}->SetToolTip('painting direction');
    $self->{'input_size_lbl'}->SetToolTip('Size of neighbourhood (how many cells) to compute new cell state from?');
    $self->{'input_size'}->SetToolTip('Size of neighbourhood (how many cells) to compute new cell state from?');
    $self->{'state_ab_lbl'}->SetToolTip('How many states a cell can have?');
    $self->{'state_count'}->SetToolTip('How many states a cell can have?');
    $self->{'circular_grid'}->SetToolTip('using cells on the endges as neighbours to each other');
    # $self->{'action_values'}->SetToolTip('how many action values between 0 and 1 a cell can emit to itself and neighbours?');
    # $self->{'action_threshold'}->SetToolTip('when action value of a cell is equal or higher the cell will be active?');
    
    Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/circular_grid/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for @{$self->{'data_keys'}};
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $grid_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $grid_sizer->AddSpacer( 15 );
    $grid_sizer->Add( $self->{'grid_lbl'}, 0, $all_attr, 7);
    $grid_sizer->Add( $self->{'grid_type'}, 0, $row_attr, 8);
    $grid_sizer->AddSpacer( 22 );
    $grid_sizer->Add( $self->{'cell_size_lbl'}, 0, $all_attr, 7);
    #$grid_sizer->AddSpacer( 3 );
    $grid_sizer->Add( $self->{'cell_size'}, 0, $row_attr, 8);
    $grid_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $paint_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $paint_sizer->AddSpacer( 15 );
    $paint_sizer->Add( $self->{'direction_lbl'}, 0, $all_attr, 7);
    $paint_sizer->Add( $self->{'paint_direction'}, 0, $row_attr, 8);
    $paint_sizer->AddSpacer( 40 );
    $paint_sizer->Add( $self->{'circular_grid'}, 0, $row_attr, 8);
    $paint_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 15 );
    $rule_sizer->Add( $self->{'input_size_lbl'}, 0, $all_attr, 8);
    $rule_sizer->Add( $self->{'input_size'}, 0, $row_attr, 8);
    $rule_sizer->AddSpacer( 21 );
    $rule_sizer->Add( $self->{'state_ab_lbl'}, 0, $all_attr, 7);
    $rule_sizer->Add( $self->{'state_count'}, 0, $row_attr, 8);
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_sizer->AddSpacer( 23 );
    $action_sizer->Add( $self->{'action_ab_lbl'}, 0, $all_attr, 7);
    $action_sizer->Add( $self->{'action_values'}, 0, $row_attr, 8);
    $action_sizer->AddSpacer( 18 );
    $action_sizer->Add( $self->{'threshhold_lbl'}, 0, $all_attr, 7);
    $action_sizer->Add( $self->{'action_threshold'}, 0, $row_attr, 8);
    $action_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
   
    my $row_space = 20;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $grid_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $paint_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, $row_space );
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $action_sizer, 0, $std_attr, 0);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init        { $_[0]->set_data({ grid_type => 'lines', cell_size => 3, paint_direction => 'top_down',
                                    state_count => 2, input_size => 3, circular_grid => 0}) } #action_values => 2, action_threshold => 1 

sub get_data {
    my ($self) = @_;
    my $data = { map { $_ => $self->{$_}->GetValue } @{$self->{'data_keys'}} };
    $data;
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for @{$self->{'data_keys'}};
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}


1;
