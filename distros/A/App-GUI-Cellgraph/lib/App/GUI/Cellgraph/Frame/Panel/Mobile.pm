use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Mobile;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Compute::Rule;
use App::GUI::Cellgraph::Widget::RuleInput;
use App::GUI::Cellgraph::Widget::Action;
use App::GUI::Cellgraph::Widget::ColorToggle;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'rule_square_size'} = 20;
    $self->{'rule_plate'} = Wx::ScrolledWindow->new( $self );
    $self->{'rule_plate'}->ShowScrollbars(0,1);
    $self->{'rule_plate'}->EnableScrolling(0,1);
    $self->{'rule_plate'}->SetScrollRate( 1, 1 );
    $self->{'call_back'} = sub {};
    $self->{'input_size'} = 0;
    $self->{'state_count'} = 0;

    $self->{'action_nr'} = Wx::TextCtrl->new( $self, -1, 22222222, [-1,-1], [ 95, -1], &Wx::wxTE_PROCESS_ENTER );

    $self->{'btn'}{'1'}  = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'2'}  = Wx::Button->new( $self, -1, '2',  [-1,-1], [30,25] );
    $self->{'btn'}{'!'}  = Wx::Button->new( $self, -1, '!',  [-1,-1], [30,25] );
    $self->{'btn'}{'?'}  = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );

    #$self->{'btn'}{'sym'}->SetToolTip('choose symmetric rule (every rule swaps result with symmetric partner)');

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $all_attr = &Wx::wxGROW | &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL;

    my $act_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $act_sizer->AddSpacer( 12 );
    $act_sizer->Add( Wx::StaticText->new( $self, -1, 'Active :' ), 0, $all_attr, 10 );
    $act_sizer->AddSpacer( 15 );
    $act_sizer->Add( $self->{'btn'}{'!'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'1'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'2'}, 0, $all_attr, 5 );
    $act_sizer->Add( $self->{'btn'}{'?'}, 0, $all_attr, 5 );
    $act_sizer->AddSpacer( 15 );
    $act_sizer->Add( $self->{'action_nr'},   0, $all_attr, 5 );
    $act_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );

    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $act_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer( 10 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $std_attr | &Wx::wxALL|&Wx::wxRIGHT, 20 );
    $main_sizer->Add( $self->{'rule_plate'}, 1, $std_attr, 0);
    $self->SetSizer( $main_sizer );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub { $self->set_action( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'action_nr'}, sub { $self->set_action( $self->{'rule_nr'}->GetValue ); $self->{'call_back'}->() });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'1'},sub { $self->init_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'2'},sub { $self->grid_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'?'},sub { $self->random_action; $self->{'call_back'}->() } );
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'!'},sub { $self->invert_action; $self->{'call_back'}->() } );

    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'action_nr'}, sub {
        my ($self, $cmd) = @_;
        my $new_value = $cmd->GetString;
        my $old_value = $self->nr_from_action_list( $self->get_action_list );
        return if $new_value == $old_value;
        $self->set_action( $new_value );
        $self->{'call_back'}->();
    });

    $self->regenerate_rules( 3, 2, color('white')->gradient_to('black', 2) );
    $self->init;
    $self;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub init { $_[0]->set_settings( { nr => 22222222 } ) }

sub get_settings {
    my ($self) = @_;
    {
        nr => $self->{'action_nr'}->GetValue,
        f => [$self->get_action_list],
        sum => 0,
        threshold => 1,
    }
}

sub set_settings {
    my ($self, $settings) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'nr'};
    $self->set_action( $settings->{'nr'} );
}

sub get_action_number { join '', reverse $_[0]->get_action_list }
sub get_action_list {
    my ($self) = @_;
    map { $self->{'action'}[$_]->GetValue } $self->{'rules'}->part_rule_iterator;
}


sub set_action {
    my ($self) = shift;
    my ($nr, @list);
    if (@_ == 1) {
        $nr = shift;
        @list = $self->list_from_action_nr( $nr );
    } else {
        @list = @_;
        $nr = $self->nr_from_action_list( @list );
    }

    $self->{'action_nr'}->SetValue( $nr );
    $self->{'action'}[$_]->SetValue( $list[$_] ) for 0 .. $#list;
}

sub init_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->init } $self->{'rules'}->part_rule_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub grid_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->grid } $self->{'rules'}->part_rule_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub random_action {
    my ($self) = @_;
    my @list =  map { $self->{'action'}[$_]->rand } $self->{'rules'}->part_rule_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub invert_action {
    my ($self) = @_;
    my @list = map { $self->{'action'}[$_]->invert } $self->{'rules'}->part_rule_iterator;
    $self->{'action_nr'}->SetValue( $self->nr_from_action_list( @list ) );
}

sub list_from_action_nr { reverse split '', $_[1]}
sub nr_from_action_list { shift @_; join '', reverse @_ }

sub regenerate_rules {
    my ($self, $input_size, $state_count, @colors) = @_;
    return if @colors < 2;
    my $do_regenerate = 0;
    my $do_recolor = 0;
    $do_regenerate += !($self->{'state_count'} == $state_count);
    $do_regenerate += !($self->{'input_size'} == $input_size);
    for my $i (0 .. $#colors) {
        return unless ref $colors[$i] eq 'Graphics::Toolkit::Color';
        if (exists $self->{'state_colors'}[$i]) {
            my @rgb = $colors[$i]->rgb;
            $do_recolor += !( $rgb[$_] == $self->{'state_colors'}[$i][$_]) for 0 .. 2;
        } else { $do_recolor++ }
    }
    return unless $do_regenerate or $do_recolor;
    $self->{'state_count'} = $state_count;
    $self->{'input_size'} = $input_size;
    $self->{'rules'} = App::GUI::Cellgraph::Compute::Rule->new( $self->{'input_size'}, $self->{'state_count'} );
    $self->{'state_colors'} = [map {[$_->rgb]} @colors];
    my @sub_rule_pattern = ($self->{'rules'}->input_list);
    if ($do_regenerate){
        my $refresh = 0;
        if (exists $self->{'rule_input'}){
            $self->{'plate_sizer'}->Clear(1);
            $self->{'rule_input'} = [];
            $self->{'arrow'} = [];
            $self->{'action'} = [];
            $refresh = 1;
        } else {
            $self->{'plate_sizer'} = Wx::BoxSizer->new(&Wx::wxVERTICAL);
            $self->{'rule_plate'}->SetSizer( $self->{'plate_sizer'} );
        }
        my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
        for my $rule_index ($self->{'rules'}->part_rule_iterator){
            $self->{'rule_input'}[$rule_index] = App::GUI::Cellgraph::Widget::RuleInput->new (
                                      $self->{'rule_plate'}, $self->{'rule_square_size'},
                                      $sub_rule_pattern[$rule_index], $self->{'state_colors'}, $self->{'rules'}->sum_mode );

            $self->{'rule_input'}[$rule_index]->SetToolTip('input pattern of partial rule Nr.'.($rule_index+1));

            $self->{'action'}[$rule_index] = App::GUI::Cellgraph::Widget::Action->new( $self->{'rule_plate'}, $self->{'rule_square_size'}, [255, 255, 255] );
            $self->{'action'}[$rule_index]->SetCallBack( sub {
                    $self->{'action_nr'}->SetValue( $self->get_action_number ); $self->{'call_back'}->()
            });
            $self->{'action'}[$rule_index]->SetToolTip('transfer of activity by partial rule Nr.'.($rule_index+1));

            $self->{'arrow'}[$rule_index] = Wx::StaticText->new( $self->{'rule_plate'}, -1, ' => ' );
        }
        for my $rule_index ($self->{'rules'}->part_rule_iterator){
            my $row_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
            $row_sizer->AddSpacer(30);
            $row_sizer->Add( $self->{'rule_input'}[$rule_index], 0, &Wx::wxGROW);
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'arrow'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->AddSpacer(15);
            $row_sizer->Add( $self->{'action'}[$rule_index], 0, &Wx::wxGROW | &Wx::wxLEFT );
            $row_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
            $self->{'plate_sizer'}->AddSpacer(15);
            $self->{'plate_sizer'}->Add( $row_sizer, 0, $std_attr, 10);
        }
        $self->Layout if $refresh;
    } elsif ($do_recolor) {
        my @rgb = map {[$_->rgb]} @colors;
        $self->{'rule_input'}[$_]->SetColors( @rgb ) for $self->{'rules'}->part_rule_iterator;
    }
}


1;
