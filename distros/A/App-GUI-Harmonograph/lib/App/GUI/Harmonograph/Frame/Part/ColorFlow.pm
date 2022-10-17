use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::ColorFlow;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

sub new {
    my ( $class, $parent, $frame ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    my $flow_label = Wx::StaticText->new( $self, -1, 'Color Change');
    $self->{'frame'} = $frame;
    $self->{'type'}    = Wx::ComboBox->new( $self, -1, 'linear', [-1,-1], [115, -1], [qw/no linear alternate circular/] );
    $self->{'type'}->SetToolTip("type of color flow: - linear - from start to end color \n  - alter(nate) - linearly between start and end color \n   - cicular - around the rainbow from start color visiting end color");
    $self->{'dynlabel'} = Wx::StaticText->new( $self, -1, 'Dynamics');
    $self->{'dynamic'}  = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[65, -1], [1,2,3,4,5,6,7,8, 9, 10], 1);
    $self->{'dynamic'}->SetToolTip('dynamics of linear and alternating color change (1 = equal distanced colors change,\n larger = starting with slow color change becoming faster - or vice versa when dir activated)');
    $self->{'stepsize'}  = App::GUI::Harmonograph::Widget::SliderCombo->new( $self,  94, 'Step Size','after how many circles does color change', 1, 100, 1);
    $self->{'period'}    = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Period','amount of steps from start to end color', 2, 50, 10);
    $self->{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'direction'}->SetToolTip('if on color change starts fast getting slower, if odd starting slow ...');

    Wx::Event::EVT_COMBOBOX( $self, $self->{'type'},  \&update_enable);


    my $cf_attr = &Wx::wxLEFT|&Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL;
    
    my $row_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row_sizer->Add( $flow_label,           0, $cf_attr,  20);
    $row_sizer->Add( $self->{'type'},       0, $cf_attr,  10);
    $row_sizer->Add( $self->{'stepsize'},   0, $cf_attr,  59);
    $row_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $row2_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $row2_sizer->Add( $self->{'dynlabel'},   0, $cf_attr,  20);
    $row2_sizer->Add( $self->{'dynamic'},    0, $cf_attr,  35);
    $row2_sizer->Add( $self->{'direction'},  0, $cf_attr,  12);
    $row2_sizer->Add( $self->{'period'},     0, $cf_attr,  63);
    $row2_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $row_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $row2_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxTOP, 10);

    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ type => 'no', dynamic => 1, period => 10, stepsize => 1 } );
}

sub get_data {
    my ( $self ) = @_;
    {
        type     => $self->{'type'}->GetValue,
        dynamic  => $self->{'direction'}->IsChecked ? 1 / $self->{'dynamic'}->GetValue : $self->{'dynamic'}->GetValue ,
        stepsize => $self->{'stepsize'}->GetValue,
        period   => $self->{'period'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{$_}->SetValue( $data->{$_} ) for qw/type stepsize period/, 
    $self->{ 'dynamic' }->SetValue( $data->{'dynamic'} < 1 ? 1 / $data->{'dynamic'} : $data->{'dynamic'} );
    $self->{ 'direction' }->SetValue( $data->{'dynamic'} < 1 );
    $self->update_enable( );
}

sub update_enable {
    my ($self) = @_;
    my $type = $self->{'type'}->GetValue();
    $self->{'stepsize'}->Enable( $type ne 'no' );
    $self->{'dynlabel'}->Enable( $type eq 'alternate' or $type eq 'linear' );
    $self->{'dynamic'}->Enable( $type eq 'alternate' or $type eq 'linear' );
    $self->{'direction'}->Enable( $type eq 'alternate' or $type eq 'linear' );
    $self->{'period'}->Enable( $type eq 'alternate' or $type eq 'circular' );
    $self->{'frame'}{'color'}{'end'}->Enable( $type ne 'no' );
}

1;
