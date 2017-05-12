package Bot::BasicBot::Pluggable::Module::commands;

use strict;
use warnings;
our $VERSION = '0.01';

use base qw(Bot::BasicBot::Pluggable::Module);

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    return unless ( $pri == 2 );

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "help" && $param eq 'commands' ) {
        my $message = $self->_create_reply_message();
        $self->reply( $mess, $message );
    }
}

sub _create_reply_message {
    my ( $self, ) = @_;

    # TO BE FIXED
    my $message = "\cC14Commands: calc, translate, j2e, e2j, wikipedia, fortune, weather, hatena-keyword, youravhost, favtape, sixamo";
    $message;
}

sub help {
    return "\cC14Commands: 'calc, translate, wikipedia, fortune'";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::commands -

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::commands;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::commands is

=head1 AUTHOR

DannE<lt>techmemo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
