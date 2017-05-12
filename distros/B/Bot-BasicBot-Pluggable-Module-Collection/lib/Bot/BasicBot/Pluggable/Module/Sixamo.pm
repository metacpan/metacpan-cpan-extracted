package Bot::BasicBot::Pluggable::Module::Sixamo;

use strict;
use warnings;
use Carp;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "sixamo" || $command eq "sixamo:") {
        my $response = $self->talk_with_sixamo($param);
        my $message  = $self->_create_reply_message($response);
        $self->reply( $mess, $message );
    }
}

sub talk_with_sixamo {
    my ( $self, $body_text ) = @_;
    my $input;
    open( $input,
              $self->sixamo_path . ' '
            . $self->sixamo_dictionary_dir . ' "'
            . $body_text
            . '" |' );
    my $body = <$input>;
    utf8::decode($body) unless utf8::is_utf8($body);
    $body;
}

sub _create_reply_message {
    my ( $self, $text ) = @_;
    my $message = "\cC14" . $text;
    $message;
}

sub sixamo_path {
    my ( $self, ) = @_;
    croak 'sixamo_path must be set' unless $self->{Param}->{sixamo_path};
    $self->{Param}->{sixamo_path};
}

sub sixamo_dictionary_dir {
    my ( $self, ) = @_;
    croak 'dictonary_dir must be set' unless $self->{Param}->{dictionary_dir};
    $self->{Param}->{dictionary_dir};
}

sub help {
    return "\cC14Commands: 'sixamo <sentence>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Sixamo- create a link to

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::Sixamo;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::Sixamo module which creates a link to .

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
