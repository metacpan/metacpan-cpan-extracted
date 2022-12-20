use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Rules;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::RuleGenerator;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::Action;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'call_back'}  = sub {};
    $self->{'rule_square_size'} = 20;
    $self->{'input_size'} = 3;
    $self->{'state_count'} = 2;


    $self->{'rule_nr'}   = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 50, -1], &Wx::wxTE_PROCESS_ENTER );
    $self->{'rule_nr'}->SetToolTip('number of currently displayed rule');
    $self->{'btn'}{'prev'}   = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}   = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'sh_l'}   = Wx::Button->new( $self, -1, '<<', [-1,-1], [35,25] );
    $self->{'btn'}{'sh_r'}   = Wx::Button->new( $self, -1, '>>', [-1,-1], [35,25] );
    $self->{'btn'}{'sym'}    = Wx::Button->new( $self, -1, '<>', [-1,-1], [35,25] );
    $self->{'btn'}{'inv'}    = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'opp'}    = Wx::Button->new( $self, -1, '%',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}    = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );

    $self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every partial rule swaps result with symmetric partner)');
    $self->{'btn'}{'inv'}->SetToolTip('choose inverted rule (every partial rule that produces white, goes black and vice versa)');
    $self->{'btn'}{'opp'}->SetToolTip('choose opposite rule ()');
    $self->{'btn'}{'rnd'}->SetToolTip('choose random rule');
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 20 );
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );        
    $rule_sizer->AddSpacer( 15 );
    $rule_sizer->Add( $self->{'btn'}{'sh_l'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'prev'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'next'}, 0, $all_attr, 5 );
    $rule_sizer->Add( $self->{'btn'}{'sh_r'}, 0, $all_attr, 5 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rf_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rf_sizer->AddSpacer( 125 );
    $rf_sizer->Add( $self->{'btn'}{'inv'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'sym'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'opp'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer(20);
    $rf_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $rf_sizer, 0, $std_attr, 20);
    #$main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxALL, 10 );

    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );
    
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'rule_nr'}, sub { $self->set_data( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_l'}, sub { $self->shift_rule_left; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sh_r'}, sub { $self->shift_rule_right; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'sym'},  sub { $self->symmetric_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'inv'},  sub { $self->invert_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'opp'},  sub { $self->opposite_rule; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_rule; $self->{'call_back'}->() } );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_value = $cmd->GetString;
        my $old_value = $self->{'rules'}->nr_from_output_list( $self->get_output_list );
        return if $new_value == $old_value;
        $self->set_rule( $new_value );
        $self->{'call_back'}->();
        
    });
    $self->regenerate_rules;
    $self->init;
    $self;
}

sub regenerate_rules {
    my ($self, $data) = @_;
    return if ref $data eq 'HASH' and $self->{'state_count'} == $data->{'global'}{'state_count'}
                                  and $self->{'input_size'} == $data->{'global'}{'input_size'};
    $self->{'state_count'} = $data->{'global'}{'state_count'} if ref $data eq 'HASH';
    $self->{'input_size'} = $data->{'global'}{'input_size'} if ref $data eq 'HASH';
    $self->{'rules'} = App::GUI::Cellgraph::RuleGenerator->new( $self->{'input_size'}, $self->{'state_count'} );
    $self->{'state_colors'} = [map {[$_->rgb]} color('white')->gradient_to('black', $self->{'state_count'})];
    my @input_colors = map {[map { $self->{'state_colors'}[$_] } @$_ ]} @{$self->{'rules'}{'input_list'}};

    my $refresh = 0;
    if (exists $self->{'rule_img'}){
        $self->{'plate_sizer'}->Clear(1);
        $self->{'rule_img'} = [];
        $self->{'arrow'} = [];
        $self->{'rule_result'} = [];
        # map { $_->Destroy} @{$self->{'rule_img'}}, @{$self->{'rule_result'}}, @{$self->{'arrow'}};
        $refresh = 1;
    } else {
        $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
        $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
    }
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    for my $rule_index ($self->{'rules'}->part_rule_iterator){
        $self->{'rule_img'}[$rule_index] = App::GUI::Cellgraph::Widget::RuleInput->new( 
                                           $self->{'rule_plate'}, $self->{'rule_square_size'}, $input_colors[$rule_index] );
        $self->{'rule_img'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
        
        $self->{'rule_result'}[$rule_index] = App::GUI::Cellgraph::Widget::ColorToggle->new( 
                                         $self->{'rule_plate'}, $self->{'rule_square_size'}, $self->{'rule_square_size'}, 
                                         $self->{'state_colors'}, 0 );
        $self->{'rule_result'}[$rule_index]->SetCallBack( sub { 
                $self->{'rule_nr'}->SetValue( $self->get_rule_number ); $self->{'call_back'}->() 
        });
        $self->{'rule_result'}[$rule_index]->SetToolTip('result of partial rule '.($rule_index+1));

        $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
    }
    for my $rule_index ($self->{'rules'}->part_rule_iterator){
        my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $row_sizer->AddSpacer(30);
        $row_sizer->Add( $self->{'rule_img'}[$rule_index], 0, &Wx::wxGROW);
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( $self->{'arrow'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );        
        $row_sizer->AddSpacer(15);
        $row_sizer->Add( $self->{'rule_result'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
        $row_sizer->AddSpacer(40);
        $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        $self->{'plate_sizer'}->AddSpacer(15);
        $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10); # ->Insert(4,
    }
    $self->Layout if $refresh;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub get_output_list {
    my ($self) = @_;
    map { $self->{'rule_result'}[$_]->GetValue } $self->{'rules'}->part_rule_iterator;
}
sub get_map {
    my ($self) = @_;
    my %map = map { $self->{'rules'}->input_pattern_from_nr($_) => 
                    $self->{'rule_result'}[$_]->GetValue } $self->{'rules'}->part_rule_iterator;
    \%map;
}
sub get_rule_number { $_[0]->{'rules'}->nr_from_output_list( $_[0]->get_output_list ) }

sub set_rule {
    my ($self) = shift;
    my ($rule, @list);
    if (@_ == 1) {
        $rule = shift;
        @list = $self->{'rules'}->output_list_from_nr( $rule );
    } else {
        @list = @_;
        $rule = $self->{'rules'}->nr_from_output_list( @list );
    }
    $self->{'rule_result'}[$_]->SetValue( $list[$_] ) for 0 .. $#list;
    $self->{'rule_nr'}->SetValue( $rule );
}

sub init { $_[0]->set_data( { nr => 18, size => 3, avg => 0 } ) }

sub get_data {
    my ($self) = @_;
    {
        f => [$self->get_output_list],
        nr => $self->{'rule_nr'}->GetValue,
        size => $self->{'input_size'},
        avg => $self->{'rules'}{'avg'},
    }
}    

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'nr'};
    $self->set_rule( $data->{'nr'} );
}    

sub prev_rule      { $_[0]->set_rule( $_[0]->{'rules'}->prev_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub next_rule      { $_[0]->set_rule( $_[0]->{'rules'}->next_nr( $_[0]->{'rule_nr'}->GetValue ) ) }

sub shift_rule_left  { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_left( $_[0]->{'rule_nr'}->GetValue ) ) }
sub shift_rule_right { $_[0]->set_rule( $_[0]->{'rules'}->shift_nr_right( $_[0]->{'rule_nr'}->GetValue ) ) }

sub opposite_rule  { $_[0]->set_rule( $_[0]->{'rules'}->opposite_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub symmetric_rule { $_[0]->set_rule( $_[0]->{'rules'}->symmetric_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub invert_rule    { $_[0]->set_rule( $_[0]->{'rules'}->inverted_nr( $_[0]->{'rule_nr'}->GetValue ) ) }
sub random_rule    { $_[0]->set_rule( $_[0]->{'rules'}->random_nr ) }

1;
