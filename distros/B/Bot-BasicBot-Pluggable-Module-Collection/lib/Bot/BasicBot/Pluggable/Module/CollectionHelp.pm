package Bot::BasicBot::Pluggable::Module::CollectionHelp;

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

    if ( $command eq "help" ) {
        my $message = $self->_create_help_message();
        $self->reply( $mess, $message );
    }
}

sub _create_reply_message {
    my ( $self, ) = @_;
    my $message = 'help: TBD';
    $message;
}

sub help {
    return "\cC14Commands: 'help'";
}



1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::CollectionHelp -

=head1 SYNOPSIS

  use Bot::BasicBot::Pluggable::Module::CollectionHelp;

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::Module::CollectionHelp is

=head1 AUTHOR

DannE<lt>techmemo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
