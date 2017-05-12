package Acme::MilkyHolmes::Role::HasPersonalColor;
use Mouse::Role;
use Encode;

requires 'color';
requires 'color_enable';

my $ansi_colors = {
    pink        => '1;35', # Light Purple
    yellow      => '1;33',
    green       => '0;32',
    blue        => '0;34',
    black       => '0;30;47', #background is white
    white       => '1;37;40', #background is black
    cyan        => '0;36',
    red         => '0;31',
    purple      => '0;35',
    brown       => '0;33',
    lightgray   => '0;37',
    darkgray    => '1;30',
    lightblue   => '1;34',
    lightgreen  => '1;32',
    lightcyan   => '1;36',
    lightred    => '1;31',
    lightpurple => '1;35',
};

sub color_enable {
    my ($self) = shift;
    return 1;
}

sub color {
    my ($self) = @_;
    return $self->common->[0]->{color};
}


sub say {
    my ($self, $comment) = @_;

    my $message = encode_utf8($self->nickname . ': ' . $comment);

    if ( defined $self->color && $self->color_enable ) {
        $message = $self->_escaped_message($self->color, $message);

    }
    print "$message\n";
}

sub _escaped_color_begin {
    my ($self, $color_name) = @_;
    return "\e[" . $ansi_colors->{$color_name} . "m"
}

sub _escape_end {
    my ($self) = @_;
    return "\e[m";
}

sub _escaped_message {
    my ($self, $color_name, $message) = @_;
    return $self->_escaped_color_begin($color_name) . $message . $self->_escape_end();
}


1;

