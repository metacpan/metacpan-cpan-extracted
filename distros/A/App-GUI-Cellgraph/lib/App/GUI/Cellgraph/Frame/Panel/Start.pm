use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Start;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::Rule;
use App::GUI::Cellgraph::Widget::ColorToggle;
use App::GUI::Cellgraph::Widget::SliderCombo;

sub new {
    my ( $class, $parent, $state, $act_state ) = @_;
    # my $x = 10;
    # my $y = 10;
    my $self = $class->SUPER::new( $parent, -1);
    
    my $colors = [[255,255,255], [0,0,0]];
    my $rule_cell_size = 20;
    $self->{'length'} = my $length = 20;
    $self->{'switch'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $colors, 0) } 1 .. $length];
    $self->{'start_int'}  = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 78, -1] );
    $self->{'start_int'}->SetToolTip('condensed content of start row');
    $self->{'repeat_start'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}  = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'one'}   = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}   = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    $self->{'grid_lbl'} = Wx::StaticText->new( $self, -1, 'Grid :');
    #$self->{'rule_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    #$self->{'rule_type_lbl'} = Wx::StaticText->new( $self, -1, 'Rules :');
    $self->{'cell_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    $self->{'grid'}      = Wx::ComboBox->new( $self, -1, 'lines', [-1,-1],[95, -1], ['lines', 'gaps', 'no']);
    #$self->{'rule_size'} = Wx::ComboBox->new( $self, -1, 3,        [-1,-1],[65, -1], [2, 3, 4, 5], &Wx::wxTE_READONLY);
    #$self->{'rule_type'} = Wx::ComboBox->new( $self, -1, 'pattern', [-1,-1],[110, -1], [qw/pattern average median/], &Wx::wxTE_READONLY);
    $self->{'cell_size'} = Wx::ComboBox->new( $self, -1, '3', [-1,-1],[75, -1], [qw/1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 25 30/], &Wx::wxTE_READONLY);
    $self->{'call_back'} = sub {};
    
    #$self->{'rule_type'}->SetToolTip('set rule type');
    
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'one'},  sub { $self->reset_start; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_start;$self->{'call_back'}->() }) ;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/grid cell_size /;# rule_size rule_type
    Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/repeat_start/;
    $_->SetCallBack( sub { $self->{'start_int'}->SetValue( $self->get_number ); $self->{'call_back'}->() }) for @{$self->{'switch'}};
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

    my $grid_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $grid_sizer->AddSpacer( 23 );
    $grid_sizer->Add( $self->{'grid_lbl'}, 0, $all_attr, 7);
    $grid_sizer->Add( $self->{'grid'}, 0, $row_attr, 8);
    $grid_sizer->AddSpacer( 31 );
    $grid_sizer->Add( $self->{'cell_size_lbl'}, 0, $all_attr, 7);
    $grid_sizer->AddSpacer( 3 );
    $grid_sizer->Add( $self->{'cell_size'}, 0, $row_attr, 8);
    $grid_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    #~ my $rule_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    #~ $rule_sizer->AddSpacer( 12 );
    #~ $rule_sizer->Add( $self->{'rule_type_lbl'}, 0, $all_attr, 10);
    #~ $rule_sizer->Add( $self->{'rule_type'}, 0, $all_attr, 5);
    #~ $rule_sizer->AddSpacer( 8 );
    #~ $rule_sizer->Add( $self->{'rule_size_lbl'}, 0, $all_attr, 10);
    #~ $rule_sizer->AddSpacer( 13 );
    #~ $rule_sizer->Add( $self->{'rule_size'}, 0, $all_attr, 5);
    #~ $rule_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $int_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $int_sizer->AddSpacer( 7 );
    $int_sizer->Add( Wx::StaticText->new( $self, -1, 'First Row: ' ), 0, &Wx::wxGROW | &Wx::wxALL, 10 );        
    $int_sizer->Add( $self->{'btn'}{'prev'}, 0, $all_attr, 5 );
    $int_sizer->Add( $self->{'start_int'}, 0, $all_attr, 5 );
    $int_sizer->Add( $self->{'btn'}{'next'}, 0, $all_attr, 5 );
    $int_sizer->Add( $self->{'btn'}{'one'}, 0, $all_attr, 5 );
    $int_sizer->Add( $self->{'btn'}{'rnd'}, 0, $all_attr, 5 );
    $int_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $io_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $io_sizer->AddSpacer(20);
    $io_sizer->Add( $self->{'switch'}[$_-1], 0, &Wx::wxGROW ) for 1 .. $self->{'length'};
    $io_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $main_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $main_sizer->AddSpacer( 20 );
    $main_sizer->Add( $grid_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 25 );
    #~ $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, 20 );
    #~ $main_sizer->AddSpacer( 25 );
    #~ $main_sizer->Add( $rule_sizer, 0, $std_attr, 0);
    $main_sizer->AddSpacer( 25 );
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, 20 );
    $main_sizer->AddSpacer( 25 );
    $main_sizer->Add( $int_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer(20);
    $main_sizer->Add( $io_sizer, 0, $std_attr, 0);
    $main_sizer->Add( $self->{'repeat_start'}, 0, $all_attr, 23);

 #   $main_sizer->Add( $self->{'rule_size'}, 0, $row_attr, 23);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub get_number {
    my ($self) = @_;
    my $number = 0;
    for (reverse $self->get_list){
        $number <<= 1;
        $number++ if $_;
    }
    $number;
}

sub get_list {
    my ($self) = @_;
    my @list = map { $self->{'switch'}[$_]->GetValue } 0 .. $self->{'length'} - 1;
    pop @list while @list and not $list[-1];
    if ($self->{'repeat_start'}->GetValue){ unshift @list, [] }
    else                                  { shift @list while @list and not $list[0] }
    @list;
}


sub init        { $_[0]->set_data({ value => 1, grid => 'lines', cell_size => 3 }) }
sub reset_start { $_[0]->set_start_row(1) }

sub get_data {
    my ($self) = @_;
    {
        list => [$self->get_list],
        value => $self->{'start_int'}->GetValue,
        cell_size => $self->{'cell_size'}->GetValue,
        grid => $self->{'grid'}->GetValue,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->set_start_row( $data->{'value'} );
    $self->{'grid'}->SetValue( $data->{'grid'} );
    $self->{'cell_size'}->SetValue( $data->{'cell_size'} );
}

sub set_start_row {
    my ($self, $int) = @_;
    $self->{'start_int'}->SetValue( $int );
    my $max = (2 ** $self->{'length'}) - 1;
    $int = int $int;
    $int = $max if $int > $max;
    $int =    0 if $int < 0;
    for my $i ( 0 .. $self->{'length'} - 1 ) {
        $self->{'switch'}[$i]->SetValue($int & 1);
        $int >>= 1;
    }
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

sub random_start {
    my ($self) = @_;
    my $int = 0;
    for my $i ( 0 .. $self->{'length'} - 1 ) {
        my $v = int rand 2;
        $self->{'switch'}[$i]->SetValue( $v );
        $int <<= 1;
        $int++ if $v;
    }
    $self->{'start_int'}->SetValue( $int );
}

sub prev_start {
    my ($self) = @_;
    my $int = $self->{'start_int'}->GetValue;
    $int-- if $int > 1;
    $self->set_data( $int );
}

sub next_start {
    my ($self) = @_;
    my $int = $self->{'start_int'}->GetValue;
    $int++;
    $self->set_data( $int );
}

1;
