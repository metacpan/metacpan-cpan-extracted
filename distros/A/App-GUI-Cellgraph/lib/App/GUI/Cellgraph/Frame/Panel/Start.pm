use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Start;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::ColorToggle;
use App::GUI::Cellgraph::Widget::SliderCombo;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1);
    
    
    $self->{'state_count'} = 2;
    $self->{'state_colors'} = [map {[$_->rgb]} color('white')->gradient_to('black', $self->{'state_count'})];

    my $rule_cell_size = 20;
    $self->{'length'} = my $length = 20;
    $self->{'switch'}   = [ map { App::GUI::Cellgraph::Widget::ColorToggle->new( $self, $rule_cell_size, $rule_cell_size, $self->{'state_colors'}, 0) } 1 .. $length];
    $self->{'start_int'}  = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 78, -1] );
    $self->{'start_int'}->SetToolTip('condensed content of start row');
    $self->{'repeat_start'} = Wx::CheckBox->new( $self, -1, '  Repeat');
    $self->{'btn'}{'prev'}  = Wx::Button->new( $self, -1, '<',  [-1,-1], [30,25] );
    $self->{'btn'}{'next'}  = Wx::Button->new( $self, -1, '>',  [-1,-1], [30,25] );
    $self->{'btn'}{'one'}   = Wx::Button->new( $self, -1, '1',  [-1,-1], [30,25] );
    $self->{'btn'}{'rnd'}   = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] );
    #$self->{'rule_size_lbl'} = Wx::StaticText->new( $self, -1, 'Size :');
    #$self->{'rule_type_lbl'} = Wx::StaticText->new( $self, -1, 'Rules :');
    #$self->{'rule_size'} = Wx::ComboBox->new( $self, -1, 3,        [-1,-1],[65, -1], [2, 3, 4, 5], &Wx::wxTE_READONLY);
    #$self->{'rule_type'} = Wx::ComboBox->new( $self, -1, 'pattern', [-1,-1],[110, -1], [qw/pattern average median/], &Wx::wxTE_READONLY);
    $self->{'call_back'} = sub {};
    
    #$self->{'rule_type'}->SetToolTip('set rule type');
    
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'prev'}, sub { $self->prev_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'next'}, sub { $self->next_start;  $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'one'},  sub { $self->reset_start; $self->{'call_back'}->() }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'rnd'},  sub { $self->random_start;$self->{'call_back'}->() }) ;
    Wx::Event::EVT_CHECKBOX( $self, $self->{$_}, sub { $self->{'call_back'}->() }) for qw/repeat_start/;
    $_->SetCallBack( sub { $self->{'start_int'}->SetValue( $self->get_number ); $self->{'call_back'}->() }) for @{$self->{'switch'}};
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxGROW | &Wx::wxALIGN_CENTER_HORIZONTAL;
    my $row_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr = $std_attr | &Wx::wxALL;

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
    $main_sizer->AddSpacer( 15 );
    $main_sizer->Add( $int_sizer, 0, $std_attr, 20);
    $main_sizer->AddSpacer(20);
    $main_sizer->Add( $io_sizer, 0, $std_attr, 0);
    $main_sizer->Add( $self->{'repeat_start'}, 0, $all_attr, 23);
    $main_sizer->Add( Wx::StaticLine->new( $self, -1), 0, $row_attr|&Wx::wxRIGHT, 20 );

 #   $main_sizer->Add( $self->{'rule_size'}, 0, $row_attr, 23);
    $main_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $main_sizer );
    $self->init;
    $self;
}

sub regenerate_cells {
    my ($self, $data) = @_;
    return if ref $data eq 'HASH' and $self->{'state_count'} == $data->{'global'}{'state_count'};
    $self->{'state_count'} = $data->{'global'}{'state_count'};
    $self->{'state_colors'} = [map {[$_->rgb]} color('white')->gradient_to('black', $self->{'state_count'})];
    $self->{'switch'}[$_]->SetColors( $self->{'state_colors'} ) for 0 .. $self->{'length'} - 1;
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
    # remove starting 0
    unless ($self->{'repeat_start'}->GetValue){ shift @list while @list and not $list[0] }
    @list;
}


sub init        { $_[0]->set_data({ value => 1 }) }
sub reset_start { $_[0]->set_start_row(1) }

sub get_data {
    my ($self) = @_;
    {
        list => [$self->get_list],
        value => $self->{'start_int'}->GetValue,
        repeat => $self->{'repeat_start'}->GetValue,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->set_start_row( $data->{'value'} );
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
    $self->set_start_row( $int );
}

sub next_start {
    my ($self) = @_;
    my $int = $self->{'start_int'}->GetValue;
    $int++;
    $self->set_start_row( $int );
}

1;
