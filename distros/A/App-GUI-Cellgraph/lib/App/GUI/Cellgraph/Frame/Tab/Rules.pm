
# panel to input subrule results

package App::GUI::Cellgraph::Frame::Tab::Rules;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::ColorToggle;
use App::GUI::Cellgraph::Compute::Rule;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $subrule_calculator ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calculator;
    $self->{'rules'}    = App::GUI::Cellgraph::Compute::Rule->new( $subrule_calculator );
    $self->{'rule_square_size'} = 20;
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;
    $self->{'rule_mode'} = '';
    $self->{'state_colors'} = [];
    $self->{'call_back'}  = sub {};
    App::GUI::Cellgraph::Compute::Grid::set_rules_tab( $self );

    $self->{'rule_nr'}   = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 115, -1], &Wx::wxTE_PROCESS_ENTER );
    $self->{'rule_nr'}->SetToolTip('number of currently displayed rule, works only on small subrule counts');
    $self->{'button'}{'prev'}   = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'button'}{'next'}   = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'button'}{'sh_l'}   = Wx::Button->new( $self, -1, '<<', [-1,-1], [35,25] );
    $self->{'button'}{'sh_r'}   = Wx::Button->new( $self, -1, '>>', [-1,-1], [35,25] );
    $self->{'button'}{'sym'}    = Wx::Button->new( $self, -1, '<>', [-1,-1], [35,25] );
    $self->{'button'}{'inv'}    = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'button'}{'opp'}    = Wx::Button->new( $self, -1, '%',  [-1,-1], [30,25] );
    $self->{'button'}{'rnd'}    = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'button'}{'undo'}   = Wx::Button->new( $self, -1, '<=', [-1,-1], [30,25] );
    $self->{'button'}{'redo'}   = Wx::Button->new( $self, -1, '=>', [-1,-1], [30,25] );

    $self->{'button'}{'prev'}->SetToolTip('decrease rule number by one');
    $self->{'button'}{'next'}->SetToolTip('increase rule number by one');
    $self->{'button'}{'sh_l'}->SetToolTip('rotate binary rule number one to left');
    $self->{'button'}{'sh_r'}->SetToolTip('rotate binary rule number one to right');
    $self->{'button'}{'sym'}->SetToolTip('choose symmetric rule (every partial rule swaps result with symmetric partner)');
    $self->{'button'}{'inv'}->SetToolTip('choose inverted rule (every partial rule that produces white, goes black and vice versa)');
    $self->{'button'}{'opp'}->SetToolTip('choose opposite rule ()');
    $self->{'button'}{'rnd'}->SetToolTip('choose random rule');
    $self->{'button'}{'undo'}->SetToolTip('undo the last rule changes');
    $self->{'button'}{'redo'}->SetToolTip('redo - take back the rule change undo');

    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $tb_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rule_sizer->AddSpacer( 10 );
    $rule_sizer->Add( Wx::StaticText->new( $self, -1, 'Rule :' ), 0, $all_attr, 10 );
    $rule_sizer->Add( $self->{'rule_nr'},     0, $all_attr, 5 );
    $rule_sizer->AddSpacer( 5 );
    $rule_sizer->Add( $self->{'button'}{'prev'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( $self->{'button'}{'next'}, 0, $tb_attr, 5 );
    $rule_sizer->AddSpacer( 23 );
    $rule_sizer->Add( $self->{'button'}{'undo'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( $self->{'button'}{'redo'}, 0, $tb_attr, 5 );
    $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rf_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $rf_sizer->AddSpacer( 63 );
    $rf_sizer->Add( $self->{'button'}{'sh_l'}, 0, $tb_attr, 5 );
    $rf_sizer->Add( $self->{'button'}{'sh_r'}, 0, $tb_attr, 5 );
    $rf_sizer->AddSpacer( 15 );
    $rf_sizer->Add( $self->{'button'}{'opp'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'button'}{'sym'}, 0, $all_attr, 5 );
    $rf_sizer->Add( $self->{'button'}{'inv'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer( 10 );
    $rf_sizer->Add( $self->{'button'}{'rnd'}, 0, $all_attr, 5 );
    $rf_sizer->AddSpacer(20);
    $rf_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $rule_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( $rf_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 5 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr|&Wx::wxLEFT|&Wx::wxRIGHT, 10 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'prev'}, sub { $self->set_result_values( $self->{'rules'}->prev_rule_nr  );     $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'next'}, sub { $self->set_result_values( $self->{'rules'}->next_rule_nr  );     $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'sh_l'}, sub { $self->set_result_values( $self->{'rules'}->shift_rule_nr_left); $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'sh_r'}, sub { $self->set_result_values( $self->{'rules'}->shift_rule_nr_right);$self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'sym'},  sub { $self->set_result_values( $self->{'rules'}->symmetric_rule_nr ); $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'inv'},  sub { $self->set_result_values( $self->{'rules'}->inverted_rule_nr  ); $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'opp'},  sub { $self->set_result_values( $self->{'rules'}->opposite_rule_nr  ); $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd'},  sub { $self->set_result_values( $self->{'rules'}->random_rule_nr );    $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'undo'}, sub { $self->set_result_values( $self->{'rules'}->undo_results   );    $self->{'call_back'}->(); });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'redo'}, sub { $self->set_result_values( $self->{'rules'}->redo_results   );    $self->{'call_back'}->(); });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'rule_nr'}, sub {
        my ($widget, $cmd) = @_;
        $self->set_result_values( $self->{'rules'}->result_list_from_rule_nr( $widget->GetValue ) );
        $self->{'call_back'}->();
    });
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'rule_nr'}, sub {
        my ($self, $cmd) = @_;
        $self->set_result_values( $self->{'rules'}->result_list_from_rule_nr( $cmd->GetString ) );
        $self->{'call_back'}->();
    });

    $self->regenerate_rules( color('white')->gradient_to('black', 2) );
    $self->init;
    $self;
}

sub regenerate_rules {
    my ($self, @colors) = @_;
    return if @colors < 2;
    my $do_regenerate = 0;
    my $do_recolor = 0;
    $do_regenerate += ($self->{'input_size'} != $self->{'subrules'}->input_size);
    $do_regenerate += ($self->{'state_count'} != $self->{'subrules'}->state_count);
    $do_regenerate += ($self->{'rule_mode'} ne $self->{'subrules'}->mode);
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->values('rgb');
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_regenerate or $do_recolor;
    $self->{'input_size'} = $self->{'subrules'}->input_size;
    $self->{'state_count'} = $self->{'subrules'}->state_count;
    $self->{'rule_mode'}   = $self->{'subrules'}->mode;
    $self->{'state_colors'} = [map {[$_->rgb]} @colors];

    if ($do_regenerate){
        my $refresh = 0; # set back refresh flag
        $self->{'rules'}->renew;
        $self->{'rule_nr'}->SetValue( $self->{'rules'}->get_rule_nr );
        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'rule_result'} = [];
            $self->{'rule_occur'} = [];
            map { $_->Destroy} @{$self->{'rule_input'}}, @{$self->{'rule_result'}}, @{$self->{'arrow'}};
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }

        my @sub_rule_pattern = $self->{'subrules'}->independent_input_patterns;
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_VERTICAL;
        my $item = $std_attr | &Wx::wxLEFT;
        my $row = $std_attr | &Wx::wxTOP;
        my $box = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
        for my $rule_index ($self->{'subrules'}->index_iterator){
            $self->{'rule_input'}[$rule_index]
                = App::GUI::Cellgraph::Widget::RuleInput->new ( $self->{'rule_plate'}, $self->{'rule_square_size'},
                                                                $sub_rule_pattern[$rule_index], $self->{'state_colors'} );
            $self->{'rule_input'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));
            $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
            $self->{'arrow'}[$rule_index]->SetToolTip('partial rule '.($rule_index+1).' input left, output right');
            $self->{'rule_result'}[$rule_index]
                = App::GUI::Cellgraph::Widget::ColorToggle->new( $self->{'rule_plate'}, $self->{'rule_square_size'},
                                                                 $self->{'rule_square_size'}, $self->{'state_colors'}, 0 );
            $self->{'rule_result'}[$rule_index]->SetValue( $self->{'rules'}->get_subrule_result($rule_index) );
            $self->{'rule_result'}[$rule_index]->SetCallBack( sub { $self->update_subrule_result( $rule_index, $_[0]); $self->{'call_back'}->(); });
            $self->{'rule_result'}[$rule_index]->SetToolTip('result of partial rule '.($rule_index+1).'left or right click to change it (rotate states)');
            $self->{'rule_occur'} [$rule_index] = Wx::TextCtrl->new( $self->{'rule_plate'}, -1, 0, [-1,-1], [ 60, -1], &Wx::wxTE_READONLY | &Wx::wxTE_RIGHT );
            $self->{'rule_occur'} [$rule_index]->SetToolTip('how many times this sub rul was applied ?');
        }
        my $label_length = length $self->{'subrules'}->independent_count;
        for my $rule_index ($self->{'subrules'}->index_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            my $label = Wx::StaticText->new( $self->{'rule_plate'}, -1, sprintf('%0'.$label_length.'u',$rule_index+1).' :  ' );
            $row_sizer->AddSpacer(20);
            $row_sizer->Add( $label,                              0, $row,   6);
            $row_sizer->Add( $self->{'rule_input'}[$rule_index],  0, $box,   3);
            $row_sizer->AddSpacer(13);
            $row_sizer->Add( $self->{'arrow'}[$rule_index],       0, $row,   6 );
            $row_sizer->AddSpacer(10);
            $row_sizer->Add( $self->{'rule_result'}[$rule_index], 0, $box,   3 );
            $row_sizer->Add( $self->{'rule_occur'}[$rule_index],  0, $item, 60 );
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(15);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'subrules'}->index_iterator;
        $self->{'rule_result'}[$_]->SetColors( @rgb ) for $self->{'subrules'}->index_iterator;
    }
}
sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub init         { $_[0]->set_settings( { summary => '01001000' } ) }
sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'summary'};
    $self->set_summary( $settings->{'summary'} );
}
sub get_settings { { summary => $_[0]->get_summary,                          } }
sub get_state    { { summary => $_[0]->get_summary, calc => $_[0]->{'rules'} } }

sub get_result_values { map { $_[0]->{'rule_result'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator }
sub set_result_values {
    my ($self, @values) = @_;
    return unless @values == $self->{'subrules'}->independent_count;
    $self->{'rule_result'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
    $self->update_widgets;
}

sub get_summary { join '', $_[0]->get_result_values }
sub set_summary {
    my ($self, $summary) = @_;
    my @values = split '', $summary;
    my $return = $self->{'rules'}->set_subrule_results( @values );
    $self->set_result_values( @values );
}

sub update_subrule_result {
    my ($self, $index, $result) = @_;
    my $summary = $self->{'rules'}->set_subrule_result( $index, $result );
    $self->update_widgets;
}

sub update_subrule_occurance {
    my ($self, @occurance) = @_;
    for my $rule_index ($self->{'subrules'}->index_iterator){
        $self->{'rule_occur'}[$rule_index]->SetValue( $occurance[$rule_index] );
    }
}
sub update_widgets {
    my ($self) = shift;
    $self->{'rule_nr'}->SetValue( $self->{'rules'}->get_rule_nr );
    $self->{'button'}{'undo'}->Enable( $self->{'rules'}->can_undo );
    $self->{'button'}{'redo'}->Enable( $self->{'rules'}->can_redo );
}

1;
