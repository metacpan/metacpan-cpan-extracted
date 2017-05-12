package Bot::BasicBot::Pluggable::Module::HatenaStar;

use strict;
use warnings;
use Carp;
use WWW::HatenaStar;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.01';

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "hatena-star" ) {
        # FIXME fix error handling
        eval {
            my $count   = $self->add_stars($param);
            my $message = $self->_create_reply_message($count);
            $self->reply( $mess, $message );
        };
    }
}

sub add_stars {
    my ( $self, $uri ) = @_;
    croak 'username must be set' unless $self->{Param}->{username};
    croak 'password must be set' unless $self->{Param}->{password};

    my $star = WWW::HatenaStar->new(
        {   config => {
                username => $self->{Param}->{username},
                password => $self->{Param}->{password}
        }   }
    );
    my $count = $self->{Param}->{count} || 5;
    $star->stars( { uri => $uri, count => $count } );
    $count;
}

sub _create_reply_message {
    my ( $self, $count ) = @_;
    my $message = "\cC14" . "added " . $count . " stars :-)";
    $message;
}

sub help {
    return "\cC14Commands: 'hatena-star <term>'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::HatenaStar- add stars to a URL

=head1 SYNOPSIS



=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::HatenaStar module which adds start to a URL.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
