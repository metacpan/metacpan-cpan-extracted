
# panel to change the values that control cell activity dependent on current subrule

package App::GUI::Cellgraph::Frame::Tab::Action;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::SliderCombo;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $subrule_calculator ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'subrules'} = $subrule_calculator;
    $self->{'rule_square_size'} = 20;
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;
    $self->{'rule_mode'} = '';
    $self->{'call_back'} = sub {};
    my $merge_condition = sub {
        my ($now, $last_time) = @_;
        return 0 unless ref $last_time eq 'ARRAY';
        return 0 unless @$now == 2 and @$last_time == 2 and $now->[0] == $last_time->[0];
        return ($now->[1] - $last_time->[1]) < 2;
    };
    $self->{'result_history'} = App::GUI::Cellgraph::Compute::History->new();
    $self->{'spread_history'} = App::GUI::Cellgraph::Compute::History->new();
    $self->{'result_history'}->set_merge_condition( $merge_condition );
    $self->{'spread_history'}->set_merge_condition( $merge_condition );

    $self->{'label'}{'result'} = Wx::StaticText->new( $self, -1, 'Gain :' );
    $self->{'label'}{'result'}->SetToolTip('Functions to change all the turn based activity gain values');
    $self->{'label'}{'spread'} = Wx::StaticText->new( $self, -1, 'Spread :' );
    $self->{'label'}{'spread'}->SetToolTip('Functions to change all the turn based activity spread values');

    my $btn_data = {result => [
        ['init', '1', 15, 'put all activity gain value to default'],
        ['copy', '=',  0, 'set all activity gains to the value of the first subrule'],
        ['sub',  '-', 10, 'decrease all activity value gains by 0.05'],
        ['add',  '+',  0, 'increase all activity value gains by 0.05'],
        ['div',  '/', 10, 'decrease large and increase small values of activity gains'],
        ['mul',  '*',  0, 'increase large and decrease small values of activity gains'],
        ['wave', '%', 10, 'increase activity gain of odd numbered subrules and decrease them of even the numbered'],
        ['+rnd', '~', 10, 'change all activity gains by a small random value'],
        ['rnd',  '?',  0, 'set all activity gains to a random value'],
        ['undo','<=', 10, 'undo last gain value change'],
        ['redo','=>',  0, 'redo gain value changes'],
    ], spread => [
        ['init', '1',  0, 'put all activity spread value on default'],
        ['copy', '=',  0, 'set all activity spread to the value of the first subrule'],
        ['sub',  '-', 10, 'decrease all activity spread by 0.05'],
        ['add',  '+',  0, 'increase all activity spread by 0.05'],
        ['div',  '/', 10, 'decrease large and increase small values of activity spread'],
        ['mul',  '*',  0, 'increase large and decrease small values of activity spread'],
        ['wave', '%', 10, 'increase activity spread of odd numbered subrules and decrease them of even the numbered'],
        ['+rnd', '~', 10, 'change all activity spread by a small random value'],
        ['rnd',  '?',  0, 'set all activity spread to a random value'],
        ['undo','<=', 10, 'undo last gain value change'],
        ['redo','=>',  0, 'redo spread value changes'],
    ]};


    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_VERTICAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL;
    my $sizer;
    for my $type (keys %$btn_data){
        next unless ref $btn_data->{$type} eq 'ARRAY';
        $sizer->{ $type } = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $sizer->{ $type }->AddSpacer( 10 );
        $sizer->{ $type }->Add( $self->{'label'}{ $type }, 0, $all_attr, 10 );

        for my $btn_data (@{$btn_data->{$type}}){
            my $ID = $btn_data->[0];
            my $button = $self->{'button'}{ $type }{ $ID } = Wx::Button->new( $self, -1, $btn_data->[1], [-1,-1], [30,25] );
            $button->SetToolTip( $btn_data->[3] );
            Wx::Event::EVT_BUTTON( $self, $button, sub { $self->change_values_command( $type, $ID ); $self->{'call_back'}->() } );
            $sizer->{ $type }->AddSpacer( $btn_data->[2] );
            $sizer->{ $type }->Add( $button, 0, $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM, 5 );
        }
        $sizer->{ $type }->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    }
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'result'}{'undo'}, sub {
        my @values = list_from_summary( $self->{'result_history'}->undo );
        $self->{'action_result'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
        $self->update_button_state;        $self->{'call_back'}->();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'result'}{'redo'}, sub {
        my @values = list_from_summary( $self->{'result_history'}->redo );
        $self->{'action_result'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
        $self->update_button_state;        $self->{'call_back'}->();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'spread'}{'undo'}, sub {
        my @values = list_from_summary( $self->{'spread_history'}->undo );
        $self->{'action_spread'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
        $self->update_button_state;        $self->{'call_back'}->();
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'spread'}{'redo'}, sub {
        my @values = list_from_summary( $self->{'spread_history'}->redo );
        $self->{'action_spread'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
        $self->update_button_state;        $self->{'call_back'}->();
    });

    $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $sizer->{'result'}, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $sizer->{'spread'}, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT, 20 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

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
    my @sub_rule_pattern = $self->{'subrules'}->independent_input_patterns;

    if ($do_regenerate){
        my $refresh = 0;# set back refresh flag

        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'action_result'} = []; # was action before
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
        for my $i ($self->{'subrules'}->index_iterator){
            $self->{'rule_input'}[$i] = App::GUI::Cellgraph::Widget::RuleInput->new (
                $self->{'rule_plate'}, $self->{'rule_square_size'}, $sub_rule_pattern[$i], $self->{'state_colors'}
            );
            $self->{'rule_input'}[$i]->SetToolTip('input pattern of partial rule Nr.'.($i+1));
            $self->{'arrow'}[$i] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
            $self->{'arrow'}[$i]->SetToolTip('partial action rule Nr.'.($i+1).' input left, output right');

            my $help_text = 'turn based gain of activity value at partial rule Nr.'.($i+1);
            $self->{'action_result'}[$i] = App::GUI::Cellgraph::Widget::SliderCombo->new
                    ( $self->{'rule_plate'}, 80, '', $help_text, -1, 1, 0.7, 0.02, 'turn based activity value gain');
            $self->{'action_result'}[$i]->SetToolTip( $help_text );
            $self->{'action_result'}[$i]->SetCallBack( sub { $self->update_result_history($i); $self->{'call_back'}->() });

            my $help_txt = 'spread of activity value to neighbouring cells from partial rule Nr.'.($i+1);
            $self->{'action_spread'}[$i] = App::GUI::Cellgraph::Widget::SliderCombo->new
                    ( $self->{'rule_plate'}, 0, '', $help_txt, -1, 1, 0.3, 0.02, 'spread of activity value');
            $self->{'action_spread'}[$i]->SetToolTip( $help_txt );
            $self->{'action_spread'}[$i]->SetCallBack( sub { $self->update_spread_history($i); $self->{'call_back'}->() });
        }
        my $label_length = length $self->{'subrules'}->independent_count;
        my $v_attr = &Wx::wxALIGN_CENTER_VERTICAL;
        for my $i ($self->{'subrules'}->index_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            $row_sizer->AddSpacer(20);
            $row_sizer->Add( Wx::StaticText->new( $self->{'rule_plate'}, -1, sprintf('%0'.$label_length.'u',$i+1).' :  ' ), 0, $v_attr);
            $row_sizer->Add( $self->{'rule_input'}[$i], 0, $v_attr );
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'arrow'}[$i], 0, $v_attr );
            $row_sizer->AddSpacer(0);
            $row_sizer->Add( $self->{'action_result'}[$i], 0, $v_attr );
            $row_sizer->Add( $self->{'action_spread'}[$i], 0, $v_attr );
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(10);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 0);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'subrules'}->index_iterator;
    }
}
sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

########################################################################
sub init {
    $_[0]->change_values_command( 'result', 'init', );
    $_[0]->change_values_command( 'spread', 'init', );
}

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'result_summary'} and exists $settings->{'spread_summary'};
    $self->set_result_values( list_from_summary( $settings->{'result_summary'} ) );
    $self->set_spread_values( list_from_summary( $settings->{'spread_summary'} ) );
}
sub get_settings {
    my ($self) = @_;
    my $state = $self->get_state;
    delete $state->{'result_list'};
    delete $state->{'spread_list'};
    return $state;
}
sub get_state {
    my ($self) = @_;
    my @results = $self->get_result_values;
    my @spreads = $self->get_spread_values;
    {
        result_summary => summary_from_list(@results),
        spread_summary => summary_from_list(@spreads),
        result_list => [@results],
        spread_list => [@spreads],
    }
}

sub get_result_values { map { $_[0]->{'action_result'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator }
sub get_spread_values { map { $_[0]->{'action_spread'}[$_]->GetValue } $_[0]->{'subrules'}->index_iterator }

sub set_result_values {
    my ($self, @values) = @_;
    return unless @values == $self->{'subrules'}->independent_count;
    $self->{'action_result'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
    $self->update_result_history( );
}
sub update_result_history {
    my ($self, $nr) = @_;
    return if defined $nr and not exists $self->{'action_result'}[$nr];
    $self->{'result_history'}->add_value( summary_from_list( $self->get_result_values ), (defined $nr) ? ($nr, time) : () );
    $self->update_button_state;
}

sub set_spread_values {
    my ($self, @values) = @_;
    return unless @values == $self->{'subrules'}->independent_count;
    $self->{'action_spread'}[$_]->SetValue( $values[$_], 'silent' ) for $self->{'subrules'}->index_iterator;
    $self->update_spread_history( );
}
sub update_spread_history {
    my ($self, $nr) = @_;
    return if defined $nr and not exists $self->{'action_spread'}[$nr];
    $self->{'spread_history'}->add_value( summary_from_list( $self->get_spread_values ), (defined $nr) ? ($nr, time) : () );
    $self->update_button_state
}
sub update_button_state {
    my ($self) = @_;
    $self->{'button'}{'result'}{'undo'}->Enable( $self->{'result_history'}->can_undo );
    $self->{'button'}{'result'}{'redo'}->Enable( $self->{'result_history'}->can_redo );
    $self->{'button'}{'spread'}{'undo'}->Enable( $self->{'spread_history'}->can_undo );
    $self->{'button'}{'spread'}{'redo'}->Enable( $self->{'spread_history'}->can_redo );
}



sub list_from_summary { split ',', $_[0] }
sub summary_from_list { join ',', @_ }

########################################################################
sub change_values_command {
    my ($self, $type, $command) = @_;
    my $sub_rule_count = $self->{'subrules'}->independent_count;
    if ($type eq 'result'){
        my @values = $self->get_result_values;
        if    ($command eq 'init'){ @values = map { 0.65      }  @values }
        elsif ($command eq 'copy'){ @values = map { $values[0]}  @values }
        elsif ($command eq 'add') { @values = map { $_ + 0.02 }  @values }
        elsif ($command eq 'sub') { @values = map { $_ - 0.02 }  @values }
        elsif ($command eq 'mul') { @values = map { $_ * 1.1  }  @values }
        elsif ($command eq 'div') { @values = map { $_ / 1.2  }  @values }
        elsif ($command eq 'wave'){ @values = map { ($_ % 2) ? ($values[$_] - 0.1) : ($values[$_] + 0.1) } 0 .. $#values }
        elsif ($command eq '+rnd'){ @values = map { $_ + ((rand 0.2)-0.1)} @values }
        elsif ($command eq 'rnd') { @values = map { (rand 2) - 1} @values }
        else { return; }
        $self->set_result_values( @values );
    } elsif ($type eq 'spread'){
        my @values = $self->get_spread_values;
        if    ($command eq 'init'){ @values = map { 0.2       }  @values }
        elsif ($command eq 'copy'){ @values = map { $values[0]}  @values }
        elsif ($command eq 'add') { @values = map { $_ + 0.02 }  @values }
        elsif ($command eq 'sub') { @values = map { $_ - 0.02 }  @values }
        elsif ($command eq 'mul') { @values = map { $_ * 1.05 }  @values }
        elsif ($command eq 'div') { @values = map { $_ / 1.1  }  @values }
        elsif ($command eq 'wave'){ @values = map { ($_ % 2) ? ($values[$_] - 0.1) : ($values[$_] + 0.1) } 0 .. $#values }
        elsif ($command eq '+rnd'){ @values = map { $_ + ((rand 0.2)-0.1)} @values }
        elsif ($command eq 'rnd') { @values = map { (rand 2) - 1} @values }
        else { return; }
        $self->set_spread_values( @values );
    }
}

1;
