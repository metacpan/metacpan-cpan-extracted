use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Panel::Polynomial;
use base qw/Wx::Panel/;

use App::GUI::Juliagraph::Frame::Part::Monomial;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{$_} = App::GUI::Juliagraph::Frame::Part::Monomial->new( $self, $_-1) for 1 .. 4;

    my $base_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $vert_attr = $base_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $all_attr  = $base_attr | &Wx::wxALL;

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5 );
    $sizer->Add( $self->{'1'},                    0, $all_attr,  5);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $all_attr, 10);
    $sizer->Add( $self->{'2'},                    0, $all_attr,  5);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $all_attr, 10);
    $sizer->Add( $self->{'3'},                    0, $all_attr,  5);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $all_attr, 10);
    $sizer->Add( $self->{'4'},                    0, $all_attr,  5);
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->{$_}->init() for 1 .. 4;
    $self->{1}->set_settings({active => 1, use_factor => 1, factor_r => 0, factor_i => 0, exponent => 0});
    $self->{2}->set_settings({active => 1, use_factor => 1, factor_r => 1, factor_i => 1, exponent => 2});
}

sub get_settings {
    my ( $self ) = @_;
    (
        monomial_1 => $self->{'1'}->get_settings(),
        monomial_2 => $self->{'2'}->get_settings(),
        monomial_3 => $self->{'3'}->get_settings(),
        monomial_4 => $self->{'4'}->get_settings(),
    )
}

sub set_settings {
    my ( $self, $data ) = @_;
    return 0 unless ref $data eq 'HASH' and exists $data->{'monomial_1'};
    $self->{$_}->set_settings($data->{'monomial_'.$_}) for 1..4;
    1;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{$_}->SetCallBack($code) for 1 .. 4
}

1;
