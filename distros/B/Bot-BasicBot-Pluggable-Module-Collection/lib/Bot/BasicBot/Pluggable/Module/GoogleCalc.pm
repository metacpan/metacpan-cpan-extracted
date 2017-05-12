package Bot::BasicBot::Pluggable::Module::GoogleCalc;

use strict;
use warnings;
use WWW::Google::Calculator;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "calc" ) {
        my $api    = WWW::Google::Calculator->new;
        my $result = $api->calc($param);
        my $message;
        if ( $api->error ) {
            $message
                = "Can't calculate a term like " . $param . ":" . $api->error;
        }
        else {
            $message = $self->_create_reply_message($result);
        }
        $self->reply( $mess, $message );
    }
}

sub _create_reply_message {
    my ( $self, $result ) = @_;
    my $message = "\cC14" . $result;
    $message;
}

sub help {
    return
        "\cC14Commands: 'calc <term>'. See also http://www.google.com/help/calculator.html";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::GoogleCalc- calculate a term with Google Calculator

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::GoogleCalc;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::GoogleCalc is module which fetches weather information from Google Calculator.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
