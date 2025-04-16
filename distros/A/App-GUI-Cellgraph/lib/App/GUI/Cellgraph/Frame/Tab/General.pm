
#  panel for general settings of image

package App::GUI::Cellgraph::Frame::Tab::General;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Compute::Subrule;

# action threshhold , value

sub new {
    my ( $class, $parent, $subrule_calc ) = @_;
    return unless ref $subrule_calc eq 'App::GUI::Cellgraph::Compute::Subrule';
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calc;
    $self->{'call_back'} = sub {};

    $self->create_label( 'logicals', 'State Rules', 'Section for rule logic settings' );
    $self->create_label( 'actions', 'Action Rules', 'Section for action rule logic settings' );
    $self->create_label( 'visuals',  'Visual Settings', 'Section for settings regarding appearances' );
    $self->create_label( 'input_size',  'Input Size :',  'Size of neighbourhood - from how many cells compute new cell state ?' );
    $self->create_label( 'state_count', 'Cell States :','How many states a cell can have ?' );
    $self->create_label( 'subrule_selection',   'Select :',   'Which selection of subrules are distinct? Rest gets bundled.' );
    $self->create_label( 'result_application', 'Result :', 'Result of a subrule should replace previous value (insert) or be added to it ?' );
    $self->create_label( 'rule_count',  'Sub - Rules :','Amount of subrules and possible rules resulting from current settings.' );
    $self->create_label( 'action_threshold','Threshold :',  'How to paint gaps between cell squares ?' );
    $self->create_label( 'action_spread',  'Spread :',  'How many neighbours get influenced by cells action rules ?' );
    $self->create_label( 'action_change',  'Change :',  'How much the action value always changes from round to round (never goes negative or above 1) ?' );
    $self->create_label( 'grid',       'Grid Style :',  'How to paint gaps between cell squares ?' );
    $self->create_label( 'cell_size',   'Cell Size :',  'Visual size of the cells in pixel.' );
    $self->create_label( 'direction',   'Direction :',  'painting direction and pattern mirroring style' );

    $self->{'widget'}{'grid_circular'}     = Wx::CheckBox->new( $self, -1, '  Circular');
    $self->{'widget'}{'action_rules_apply'}= Wx::CheckBox->new( $self, -1, '  Apply');
    $self->{'widget'}{'fill_cells'}        = Wx::CheckBox->new( $self, -1, '  Fill');

    $self->{'widget'}{'subrule_count'}     = Wx::TextCtrl->new( $self, -1, 8, [-1,-1], [ 55, -1], &Wx::wxTE_READONLY );

    $self->{'widget'}{'input_size'}        = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'state_count'}       = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[65, -1], [qw/2 3 4 5 6 7 8 9/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'subrule_selection'} = Wx::ComboBox->new( $self, -1, '2', [-1,-1],[118, -1], [qw/all symmetric sorted summing/], &Wx::wxTE_READONLY); # median
    $self->{'widget'}{'result_application'}= Wx::ComboBox->new( $self, -1, '2', [-1,-1],[110, -1], [qw/insert rotate add add_rot subtract multiply/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'action_threshold'}  = Wx::ComboBox->new( $self, -1, '0.6', [-1,-1],[90, -1], [0, 0.1,0.2,0.3,0.4,0.5,0.6,0.65,0.7,0.75,0.8,0.85, 0.9, 0.95,1.0]);
    $self->{'widget'}{'action_spread'}     = Wx::ComboBox->new( $self, -1, '0.6', [-1,-1],[65, -1], [0,1,2,3]);
    $self->{'widget'}{'action_change'}     = Wx::ComboBox->new( $self, -1, '0.6', [-1,-1],[85, -1], ['-1','-0.9','-0.8','-0.7','-0.6','-0.5','-0.4','-0.3','-0.2','-.1',0,'+0.1','+0.2','+0.3','+0.4','+0.5','+0.6','+0.7','+0.8','+0.9','+1']);
    $self->{'widget'}{'grid_type'}         = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[90, -1], ['lines', 'gaps', 'no']);
    $self->{'widget'}{'cell_size'}         = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[75, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'widget'}{'paint_direction'}   = Wx::ComboBox->new( $self, -1, 'top_down', [-1,-1],[120, -1], [qw/top_down outside_in inside_out/], &Wx::wxTE_READONLY);

    $self->{'widget'}{'input_size'}->SetToolTip('Size of neighbourhood (how many cells) to compute new cell state from ?');
    $self->{'widget'}{'state_count'}->SetToolTip('How many states a cell can have?');
    $self->{'widget'}{'subrule_count'}->SetToolTip('Count of Subrules resulting from current settings');
    $self->{'widget'}{'subrule_selection'}->SetToolTip("symmetric = an asymetric rule and its mirror have same result\nsumming = all rules with same sum of input states have same result");
    $self->{'widget'}{'result_application'}->SetToolTip("Result of a subrule should replace previous value (insert) or be added to it ?");
    $self->{'widget'}{'action_rules_apply'}->SetToolTip( "should action rules determine if a (state) rule gets applied this round.");
    $self->{'widget'}{'action_threshold'}->SetToolTip( "Action potential of a cell has to be at least this big so state can change.");
    $self->{'widget'}{'action_spread'}->SetToolTip( "How many neighbours get influenced by cells action rules ?");
    $self->{'widget'}{'action_change'}->SetToolTip( "How much the action value always changes from round to round (never goes negative or above 1) ?");
    $self->{'widget'}{'grid_type'}->SetToolTip('How to paint gaps between cell squares');
    $self->{'widget'}{'cell_size'}->SetToolTip('visual size of the cells in pixel');
    $self->{'widget'}{'paint_direction'}->SetToolTip('painting direction');
    $self->{'widget'}{'grid_circular'}->SetToolTip('cells on the edges become neighbours to each other');
    $self->{'widget'}{'fill_cells'}->SetToolTip('fill cell squares with color, or just pain rectangles');

    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() })
        for qw/grid_circular action_rules_apply fill_cells/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{$_}, sub { $self->{'call_back'}->() })
        for qw/grid_type cell_size action_threshold action_spread action_change paint_direction result_application/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{$_}, sub { $self->compute_subrule_count; $self->{'call_back'}->() })
        for qw/state_count input_size subrule_selection/;

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL;
    my $sep_attr = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT | &Wx::wxGROW;
    my $all_attr = $std_attr | &Wx::wxALL | &Wx::wxGROW;
    my $indent   = 15;

    my $rule1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule1_sizer->AddSpacer( $indent );
    $rule1_sizer->Add( $self->{'label'}{'input_size'}, 0, $std_attr, 0);
    $rule1_sizer->AddSpacer( 10 );
    $rule1_sizer->Add( $self->{'widget'}{'input_size'}, 0, $std_attr, 0);
    $rule1_sizer->AddSpacer( 40 );
    $rule1_sizer->Add( $self->{'label'}{'state_count'}, 0, $std_attr, 0);
    $rule1_sizer->AddSpacer( 10 );
    $rule1_sizer->Add( $self->{'widget'}{'state_count'}, 0, $std_attr, 0);
    $rule1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rule2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule2_sizer->AddSpacer( $indent );
    $rule2_sizer->Add( $self->{'label'}{'subrule_selection'}, 0, $std_attr, 0);
    $rule2_sizer->AddSpacer( 10 );
    $rule2_sizer->Add( $self->{'widget'}{'subrule_selection'}, 0, $std_attr, 0);
    $rule2_sizer->AddSpacer( 20 );
    $rule2_sizer->Add( $self->{'label'}{'rule_count'}, 0,   $std_attr, 0);
    $rule2_sizer->AddSpacer( 10 );
    $rule2_sizer->Add( $self->{'widget'}{'subrule_count'}, 0, $std_attr, 0);
    $rule2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rule3_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule3_sizer->AddSpacer( $indent );
    $rule3_sizer->Add( $self->{'label'}{'result_application'}, 0, $std_attr, 0);
    $rule3_sizer->AddSpacer( 10 );
    $rule3_sizer->Add( $self->{'widget'}{'result_application'}, 0, $std_attr, 0);
    $rule3_sizer->AddSpacer( 97 );
    $rule3_sizer->Add( $self->{'widget'}{'grid_circular'}, 0, $std_attr, 0);
    $rule3_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action1_sizer->AddSpacer( $indent );
    $action1_sizer->Add( $self->{'widget'}{'action_rules_apply'}, 0, $std_attr, 0);
    $action1_sizer->AddSpacer( 115 );
    $action1_sizer->Add( $self->{'label'}{'action_threshold'}, 0, $std_attr, 0);
    $action1_sizer->AddSpacer( 10 );
    $action1_sizer->Add( $self->{'widget'}{'action_threshold'}, 0, $std_attr, 0);
    $action1_sizer->AddSpacer( 15 );
    $action1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action2_sizer->AddSpacer( $indent );
    $action2_sizer->Add( $self->{'label'}{'action_spread'}, 0, $std_attr, 0);
    $action2_sizer->AddSpacer( 10 );
    $action2_sizer->Add( $self->{'widget'}{'action_spread'}, 0, $std_attr, 0);
    $action2_sizer->AddSpacer( 73 );
    $action2_sizer->Add( $self->{'label'}{'action_change'}, 0, $std_attr, 0);
    $action2_sizer->AddSpacer( 10 );
    $action2_sizer->Add( $self->{'widget'}{'action_change'}, 0, $std_attr, 0);
    $action2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $visual1_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $visual1_sizer->AddSpacer( $indent );
    $visual1_sizer->Add( $self->{'label'}{'direction'}, 0, $std_attr, 0);
    $visual1_sizer->AddSpacer( 10 );
    $visual1_sizer->Add( $self->{'widget'}{'paint_direction'}, 0, $std_attr, 0);
    $visual1_sizer->AddSpacer( 85 );
    $visual1_sizer->Add( $self->{'widget'}{'fill_cells'}, 0, $std_attr, 0);
    $visual1_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $visual2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $visual2_sizer->AddSpacer( $indent );
    $visual2_sizer->Add( $self->{'label'}{'grid'}, 0, $std_attr, 0);
    $visual2_sizer->AddSpacer( 10 );
    $visual2_sizer->Add( $self->{'widget'}{'grid_type'}, 0, $std_attr, 0);
    $visual2_sizer->AddSpacer( 30 );
    $visual2_sizer->Add( $self->{'label'}{'cell_size'}, 0, $std_attr, 0);
    $visual2_sizer->AddSpacer( 10 );
    $visual2_sizer->Add( $self->{'widget'}{'cell_size'}, 0, $std_attr, 0);
    $visual2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $row_space = 15;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( $row_space-5 );
    $main_sizer->Add( $self->{'label'}{'logicals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space);
    $main_sizer->Add( $rule2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $rule3_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $sep_attr, $row_space );
    $main_sizer->AddSpacer( $row_space-5 );
    $main_sizer->Add( $self->{'label'}{'actions'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $action1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $action2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $sep_attr, $row_space );
    $main_sizer->AddSpacer( $row_space-5 );
    $main_sizer->Add( $self->{'label'}{'visuals'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $visual1_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $visual2_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}
sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

my $default_settings = {
    input_size => 3, state_count => 2, grid_circular => 1,
    subrule_selection => 'all', subrule_count => 8,
    result_application => 'insert',
    action_rules_apply => 0, action_spread => 0,
    action_change => -0.6, action_threshold => 0.7,
    paint_direction => 'top_down', grid_type => 'lines', cell_size => 3,
    fill_cells => 1,
};

sub init        { $_[0]->set_settings( $default_settings ) }
sub get_settings {
    my ($self) = @_;
    my $settings = { map { $_ => $self->{'widget'}{$_}->GetValue } keys %{$self->{'widget'}} };
}
sub get_state   { $_[0]->get_settings() }
sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH';
    my $change = 0;
    for my $key (keys %{$self->{'widget'}}) {
        my $value = (exists $settings->{$key}) ? $settings->{$key} : $default_settings->{$key};
        next if $value eq $self->{'widget'}{$key}->GetValue;
        $self->{'widget'}{$key}->SetValue( $value );
        $change++;
    }
    $self->compute_subrule_count if $change;
}

sub compute_subrule_count {
    my ($self) = @_;
    $self->{'subrules'}->renew(
        $self->{'widget'}{'input_size'}->GetValue,
        $self->{'widget'}{'state_count'}->GetValue,
        $self->{'widget'}{'subrule_selection'}->GetValue
    );
    $self->{'widget'}{'subrule_count'}->SetValue( $self->{'subrules'}->independent_count );
}

sub create_label {
    my ($self, $id, $text, $help) = @_;
    return unless defined $text and $text and not exists $self->{'label'}{ $id };
    $self->{'label'}{ $id } = Wx::StaticText->new( $self, -1, $text );
    $self->{'label'}{ $id }->SetToolTip( $help ) if defined $help and $help;
    $self->{'label'}{ $id }
}

1;
