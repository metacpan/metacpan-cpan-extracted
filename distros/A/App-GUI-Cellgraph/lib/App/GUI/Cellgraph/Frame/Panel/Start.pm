
# tab to input states and action values of firs row of automata

package App::GUI::Cellgraph::Frame::Panel::Start;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'state_count'} = 2;
    $self->{'cells_in_row'} = my $cell_count = 20;
    $self->{'cells_iterator'} = [0 .. $cell_count - 1];
    $self->{'call_back'} = sub {};
    my $rule_cell_size = 20;

    $self->{'state_colors'}   = [map { [$_->values('rgb')]} color('white')->gradient_to('black', $self->{'state_count'})];
    $self->{'state_switches'} = [map { App::GUI::Cellgraph::Widget::ColorToggle->new
                                       ( $self, $rule_cell_size, $rule_cell_size, $self->{'state_colors'}, 0) } @{$self->{'cells_iterator'}}];
    $self->{'state_switches'}[$_]->SetToolTip('click with left or right to change state of this cell in starting row') for @{$self->{'cells_iterator'}};
    # $self->{'state_switches'}[0]->Enable(0);
    $self->{'action_colors'}   = [map {[$_->values('rgb')]} color('white')->gradient_to('orange', 6)];
    $self->{'action_switches'} = [map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $self->{'action_colors'}, 0) } @{$self->{'cells_iterator'}}];
    $self->{'action_switches'}[$_]->SetToolTip('click with left or right to change action value of this cell in starting row') for @{$self->{'cells_iterator'}};

    $self->{'widget'}{'state_summary'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 180, -1] );
    $self->{'widget'}{'state_summary'}->SetToolTip('condensed content of start row states');
    $self->{'widget'}{'action_summary'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [ 180, -1] );
    $self->{'widget'}{'state_summary'}->SetToolTip('condensed content of start row activity values');
    $self->{'widget'}{'repeat_states'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'widget'}{'repeat_action'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'widget'}{'repeat_states'}->SetToolTip('repeat this pattern to fill first row');
    $self->{'widget'}{'repeat_action'}->SetToolTip('repeat this pattern to fill first row');
    $self->{'widget'}{'button'}{'prev_state'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'next_state'}  = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'prev_action'} = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'next_action'} = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'init_state'}  = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'rnd_state'}   = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'init_action'} = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'rnd_action'}  = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'widget'}{'button'}{'prev_state'}->SetToolTip('decrement number that summarizes all cell states of starting row');
    $self->{'widget'}{'button'}{'next_state'}->SetToolTip('increment number that summarizes all cell states of starting row');
    $self->{'widget'}{'button'}{'prev_action'}->SetToolTip('decrement number that summarizes the  activity values of all starting cells');
    $self->{'widget'}{'button'}{'next_action'}->SetToolTip('increment number that summarizes all cell activity values');
    $self->{'widget'}{'button'}{'init_state'}->SetToolTip('reset cell states in starting row to initial values');
    $self->{'widget'}{'button'}{'rnd_state'}->SetToolTip('generate random cell state values in starting row');
    $self->{'widget'}{'button'}{'init_action'}->SetToolTip('reset cell activity values to initial values');
    $self->{'widget'}{'button'}{'rnd_action'}->SetToolTip('generate random cell activity values in starting row');
    $self->{'label'}{'state_rules'}    = Wx::StaticText->new( $self, -1, 'Cell States' );
    $self->{'label'}{'action_rules'}   = Wx::StaticText->new( $self, -1, 'Activity Values' );
    $self->{'label'}{'state_summary'}  = Wx::StaticText->new( $self, -1, 'Summary:' );
    $self->{'label'}{'action_summary'} = Wx::StaticText->new( $self, -1, 'Summary:' );
    $self->{'label'}{'state_summary'}->SetToolTip('ID of current starting row configuration');
    $self->{'label'}{'action_summary'}->SetToolTip('ID of the configuration of activity values');

    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'prev_state'},  sub { $self->prev_state;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'next_state'},  sub { $self->next_state;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'init_state'},  sub { $self->init_state;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'rnd_state'},   sub { $self->random_state;$self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'prev_action'}, sub { $self->prev_action;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'next_action'}, sub { $self->next_action;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'init_action'}, sub { $self->init_action;  $self->{'call_back'}->() });
    Wx::Event::EVT_BUTTON( $self, $self->{'widget'}{'button'}{'rnd_action'},  sub { $self->random_action;$self->{'call_back'}->() });
    Wx::Event::EVT_CHECKBOX($self,$self->{'widget'}{$_}, sub { $self->{'call_back'}->() }) for qw/repeat_states repeat_action/;
    $_->SetCallBack( sub { $self->set_state_list( $self->get_state_list ); $self->{'call_back'}->() }) for @{$self->{'state_switches'}};
    $_->SetCallBack( sub { $self->set_action_list( $self->get_action_list ); $self->{'call_back'}->() }) for @{$self->{'action_switches'}};


    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL;
    my $sep_attr = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT | &Wx::wxGROW;
    my $tb_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $indent   = 15;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $state_summary_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $state_summary_sizer->AddSpacer( 20 );
    $state_summary_sizer->Add( $self->{'label'}{'state_summary'}, 0, $std_attr, 0 );
    $state_summary_sizer->Add( $self->{'widget'}{'state_summary'}, 0, $row_attr, 10 );
    $state_summary_sizer->AddSpacer( 15 );
    $state_summary_sizer->Add( $self->{'widget'}{'button'}{'prev_state'}, 0, $tb_attr, 5 );
    $state_summary_sizer->Add( $self->{'widget'}{'button'}{'next_state'}, 0, $tb_attr, 5 );
    $state_summary_sizer->AddSpacer( 15 );
    $state_summary_sizer->Add( $self->{'widget'}{'button'}{'init_state'}, 0, $tb_attr, 5 );
    $state_summary_sizer->AddSpacer( 10 );
    $state_summary_sizer->Add( $self->{'widget'}{'button'}{'rnd_state'},  0, $tb_attr, 5 );
    $state_summary_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $state_row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $state_row_sizer->AddSpacer(20);
    $state_row_sizer->Add( $self->{'state_switches'}[$_], 0, &Wx::wxGROW ) for @{$self->{'cells_iterator'}};
    $state_row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_row_sizer->AddSpacer(20);
    $action_row_sizer->Add( $self->{'action_switches'}[$_], 0, &Wx::wxGROW ) for @{$self->{'cells_iterator'}};
    $action_row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $action_summary_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $action_summary_sizer->AddSpacer( 10 );
    $action_summary_sizer->Add( $self->{'label'}{'action_summary'}, 0, &Wx::wxGROW | &Wx::wxALL, 10 );
    $action_summary_sizer->Add( $self->{'widget'}{'action_summary'}, 0, $row_attr, 5 );
    $action_summary_sizer->AddSpacer( 15 );
    $action_summary_sizer->Add( $self->{'widget'}{'button'}{'prev_action'}, 0, $tb_attr, 5 );
    $action_summary_sizer->Add( $self->{'widget'}{'button'}{'next_action'}, 0, $tb_attr, 5 );
    $action_summary_sizer->AddSpacer( 15 );
    $action_summary_sizer->Add( $self->{'widget'}{'button'}{'init_action'}, 0, $tb_attr, 5 );
    $action_summary_sizer->AddSpacer( 10 );
    $action_summary_sizer->Add( $self->{'widget'}{'button'}{'rnd_action'},  0, $tb_attr, 5 );
    $action_summary_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $row_space = 15;
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'label'}{'state_rules'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( $row_space );
    $main_sizer->Add( $state_summary_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 20 );
    $main_sizer->Add( $state_row_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'widget'}{'repeat_states'}, 0, $row_attr, 23);
    $main_sizer->AddSpacer(10);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $sep_attr, $row_space );
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'label'}{'action_rules'}, 0, &Wx::wxALIGN_CENTER_HORIZONTAL , 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $action_summary_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 20 );
    $main_sizer->Add( $action_row_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( $self->{'widget'}{'repeat_action'}, 0, $row_attr, 23);
    $main_sizer->AddSpacer( 10 );

    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub init { $_[0]->set_settings({ state_summary => 1, repeat_states => 0,
                                 action_summary => 5, repeat_action => 1,
})}
sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH';
    $self->set_state_summary( $settings->{'state_summary'} );
    $self->set_action_summary( $settings->{'action_summary'} );
    $self->{'widget'}{$_}->SetValue( $settings->{$_} ) for qw/repeat_states repeat_action/;
}
sub get_settings {
    my ($self) = @_;
    {
        state_summary => $self->get_state_summary,
        action_summary => $self->get_action_summary,
        repeat_states => $self->{'widget'}{'repeat_states'}->GetValue ? 1 : 0,
        repeat_action => $self->{'widget'}{'repeat_action'}->GetValue ? 1 : 0,
    }
}
sub get_state { # of app
    my ($self) = @_;
    my $state = $self->get_settings;
    $state->{'state_list'} = [$self->get_state_list];
    $state->{'action_list'} = [$self->get_action_list];
    $state;
}

sub get_state_summary {
    my ($self) = @_;
    $self->{'widget'}{'state_summary'}->GetValue
        ? $self->{'widget'}{'state_summary'}->GetValue : 0;
}
sub get_action_summary {
    my ($self) = @_;
    $self->{'widget'}{'action_summary'}->GetValue
        ? $self->{'widget'}{'action_summary'}->GetValue : 0;
}
sub set_state_summary {
    my ($self, $summary) = @_;
    return unless defined $summary and length($summary) <= $self->{'cells_in_row'};
    return if $summary eq $self->get_state_summary;
    my @list = split('', $summary);
    map {return if $_ !~ /\d/ or $_ < 0 or $_ >= $self->{'state_count'}} @list;
    $self->{'widget'}{'state_summary'}->SetValue( $summary );
    $self->set_state_list( @list );
}
sub set_action_summary {
    my ($self, $summary) = @_;
    return unless defined $summary and length($summary) <= $self->{'cells_in_row'};
    return if $summary eq $self->get_action_summary;
    my @list = split('', $summary);
    map {return unless is_action_nr($_) } @list;
    $self->{'widget'}{'action_summary'}->SetValue( $summary );
    $self->set_action_list( @list );
}

sub get_state_list {
    my ($self) = @_;
    my @list = map {$self->{'state_switches'}[$_]->GetValue} @{$self->{'cells_iterator'}};
    pop @list while @list and not $list[-1];    # remove zeros in suffix
    #unless ($self->{'widget'}{'repeat_states'}->GetValue){ shift @list while @list and not $list[0] }
    @list;
}
sub get_action_list {
    my ($self) = @_;
    my @list = map {$self->{'action_switches'}[$_]->GetValue} @{$self->{'cells_iterator'}};
    pop @list while @list and not $list[-1];    # remove zeros in suffix
    #unless ($self->{'widget'}{'repeat_action'}->GetValue){ shift @list while @list and not $list[0] }
    @list;
}
sub set_state_list {
    my ($self, @list) = @_;
    @list = (0) unless @list;
    return unless @list <= $self->{'cells_in_row'};
    map {return if $_ !~ /\d/ or $_ < 0 or $_ >= $self->{'state_count'}} @list;
    $self->set_state_summary( join '', @list );
    push @list, 0 until @list == $self->{'cells_in_row'};
    map {$self->{'state_switches'}[$_]->SetValue( $list[$_] )
            if exists $list[$_] and $list[$_] ne $self->{'state_switches'}[$_]->GetValue } @{$self->{'cells_iterator'}};
    @list;
}
sub set_action_list {
    my ($self, @list) = @_;
    @list = $self->get_action_list() unless @list;
    return unless @list <= $self->{'cells_in_row'};
    map {return unless is_action_nr($_) } @list;
    $self->set_action_summary( join '', @list );
    push @list, 0 until @list == $self->{'cells_in_row'};
    map { $self->{'action_switches'}[$_]->SetValue( $list[$_] )
            if exists $list[$_] and $list[$_] ne $self->{'action_switches'}[$_]->GetValue } @{$self->{'cells_iterator'}};
    @list;
}


sub update_cell_colors {
    my ($self, @colors) = @_;
    return if @colors < 2;
    my $do_recolor = @colors == $self->{'state_count'} ? 0 : 1;
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->rgb;
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_recolor;
    my @rgb = map {[$_->values('rgb')]} @colors;
    $self->{'state_switches'}[$_]->SetColors( @rgb ) for @{$self->{'cells_iterator'}};
    $self->{'state_count'} = @colors;
}

sub set_callback {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

########################################################################
sub prev_state {
    my ($self) = @_;
    my @list = $self->get_state_list;
    return $self->set_state_list( ($self->{'state_count'} - 1) x $self->{'cells_in_row'})
        if @list == 1 and $list[0] == 1;
    my $pos = 0;
    while ($pos < @list){
        $list[$pos]--;
        return $self->set_state_list(@list) if $list[$pos] >= 0;
        $list[$pos] = $self->{'state_count'} - 1;
        $pos++;
    }
    $self->set_state_list( ($self->{'state_count'} - 1) x $self->{'cells_in_row'});
}

sub next_state {
    my ($self) = @_;
    my @list = $self->get_state_list;
    my $pos = 0;
    while ($pos < @list){
        $list[$pos]++;
        return $self->set_state_list(@list) unless $list[$pos] == $self->{'state_count'};
        $list[$pos] = 0;
        $pos++;
    }
    if (@list == $self->{'cells_in_row'}) {$self->set_state_list(1) }
    else {
        push @list, 1;
        $self->set_state_list(@list);
    }
}

sub prev_action {
    my ($self) = @_;
    my @list = $self->get_action_list;
    return $self->set_action_list( (5) x $self->{'cells_in_row'})
        if @list == 1 and $list[0] == 1;
    my $pos = 0;
    while ($pos < @list){
        $list[$pos]--;
        return $self->set_action_list(@list) if $list[$pos] >= 0;
        $list[$pos] = 5;
        $pos++;
    }
    $self->set_action_list( (5) x $self->{'cells_in_row'} );
}

sub next_action {
    my ($self) = @_;
    my @list = $self->get_action_list;
    my $pos = 0;
    while ($pos < @list){
        $list[$pos]++;
        return $self->set_action_list(@list) unless $list[$pos] == 6;
        $list[$pos] = 0;
        $pos++;
    }
    if (@list == $self->{'cells_in_row'}) {$self->set_action_list(1) }
    else {
        push @list, 1;
        $self->set_action_list(@list);
    }
}

sub init_state   { $_[0]->set_state_list(1) }
sub random_state { $_[0]->set_state_list( map {int rand $_[0]->{'state_count'}} 0 .. int rand $_[0]->{'cells_in_row'}) }

sub init_action   { $_[0]->set_action_list(5) }
sub random_action { $_[0]->set_action_list( map {int rand 6} 0 .. int rand $_[0]->{'cells_in_row'}) }

#sub trim_list { }
sub is_action_nr { (defined $_[0] and $_[0] =~ /\d/ and $_[0] >= 0 and $_[0] <= 5) ? 1 : 0 }
sub action_value_from_nr { (defined $_[0]) ? ($_[0] / 5) : 0 }
sub action_nr_from_value { (defined $_[0]) ? ($_[0] * 5) : 0 }

1;
