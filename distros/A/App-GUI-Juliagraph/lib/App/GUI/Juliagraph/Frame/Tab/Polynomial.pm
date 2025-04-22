use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Tab::Polynomial;
use base qw/Wx::Panel/;

use App::GUI::Juliagraph::Frame::Panel::Monomial;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'monomial_count'} = 4;
    $self->{$_} = App::GUI::Juliagraph::Frame::Panel::Monomial->new( $self, $_) for 1 .. $self->{'monomial_count'};

    my $std  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box  = $std | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $item = $std | &Wx::wxLEFT | &Wx::wxRIGHT;

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer(  10 );
    $sizer->Add( $self->{'1'},                    0, $item, 10);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10);
    $sizer->Add( $self->{'2'},                    0, $item, 10);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10);
    $sizer->Add( $self->{'3'},                    0, $item, 10);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10);
    $sizer->Add( $self->{'4'},                    0, $item, 10);
    $sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init         { $_[0]->{$_}->init() for 1 .. $_[0]->{'monomial_count'};  $_[0]->enable_coor(0) }

sub get_settings {  return {  map { $_ => $_[0]->{$_}->get_settings() } 1 .. $_[0]->{'monomial_count'} } }
sub set_settings {
    my ( $self, $settings ) = @_;
    return 0 unless ref $settings eq 'HASH' and exists $settings->{'1'};
    $self->{$_}->set_settings( $settings->{$_} ) for 1 .. $self->{'monomial_count'};
    1;
}

sub enable_coor {
    my ( $self, $on ) = @_;
    return unless defined $on;
    $self->{$_}->enable_coor( $on ) for 1 .. $self->{'monomial_count'};
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{$_}->SetCallBack($code) for 1 .. $self->{'monomial_count'};
}

1;
