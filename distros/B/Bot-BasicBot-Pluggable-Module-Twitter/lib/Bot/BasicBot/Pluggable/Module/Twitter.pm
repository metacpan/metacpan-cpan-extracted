package Bot::BasicBot::Pluggable::Module::Twitter;

use warnings;
use strict;
use Carp;

use Bot::BasicBot::Pluggable::Module;
use base qw(Bot::BasicBot::Pluggable::Module);

use Net::Twitter;

our $VERSION = '0.0.3';

=head1 NAME

Bot::BasicBot::Pluggable::Module::Twitter - Post message to twitter


=head1 SYNOPSIS

    $bot->load( "Twitter" );
    my $twi_handler = $bot->handler( "Twitter" );
    $twi_handler->set(
        {   username => "myusername",
            password => "mypassword",
        }
    );

=head1 DESCRIPTION

A plugin module for L<Bot::BasicBot::Pluggable> to send message to a twitter account.

=head2 METHODS

=cut

=head3 init

=cut

sub init {
    my $self = shift;
}

=head3 help

    !help
    
will return a help message

=cut

sub help {
    my $self = shift;
    my $mess = "!twitter <str> : will post a message to twitter";
    $mess
        .= "\n!twitter_all : will return the last 5 public messages from the public timeline";
    return $mess;
}

=head3 said

    !twitter my message
    !twitter_all
    
will send to twitter your message
will get the last 5 messages from the public timeline

=cut

sub said {
    my ( $self, $mess, $pri ) = @_;

    return unless $pri == 2;

    $self->{ body }    = $mess->{ body };
    $self->{ who }     = $mess->{ who };
    $self->{ channel } = $mess->{ channel };

    if ( $self->{ body } =~ /^!twitter\s(.*)$/ ) {
        my $result = $self->{ twit }->update( $1 );
        if ( !defined $result ) {
            $self->tell( $self->{ channel },
                $self->{ who } . ": an error occurs." );
        }
        else {
            $self->tell( $self->{ channel },
                $self->{ who } . ": consider it noted." );
        }
    }
    elsif ( $self->{ body } =~ /^!twitter_all/ ) {
        my $result = $self->{ twit }->public_timeline;
        my $i      = 0;
        foreach my $t ( @{ $result } ) {
            my $str = $t->{ user }->{ name }. " :". $t->{text};
            $self->tell( $self->{ channel }, $str );
            $i++;
            last if $i == 5;
        }
    }
}

=head3 set

    $twitter_handler->set(
        {   username => "myusername",
            password => "mypassword",
        }
    );
    
will set the username and the password for the bot.

=cut

sub set {
    my ( $self, $params ) = @_;

    foreach my $key ( keys %{ $params } ) {
        $self->{ $key } = $$params{ $key };
    }

    croak "Error: no twitter username specified" unless $self->{ username };
    croak "Error: no twitter password specified" unless $self->{ password };

    $self->{ twit } = Net::Twitter->new(
        username => $self->{ username },
        password => $self->{ password }
    );

    return $self;
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-twitter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

franck cuny  C<< <franck.cuny@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, franck cuny C<< <franck.cuny@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
