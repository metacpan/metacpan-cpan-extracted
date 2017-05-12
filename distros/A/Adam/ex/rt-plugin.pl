#!/usr/bin/env perl
use 5.10.0;
use lib qw(lib);
use Moses::Declare;

$INC{'RT/Plugin.pm'}++;

plugin RT::Plugin {
    use Try::Tiny;
    use RT::Client::REST;

    has [qw(server user pass)] => (
        isa        => 'Str',
        is         => 'ro',
        lazy_build => 1
    );

    sub _build_server { 'http://rt.cpan.org' }
    sub _build_user   { $ENV{RT_USER} }
    sub _build_pass   { $ENV{RT_PASS} }

    has rt => (
        isa        => 'RT::Client::REST',
        is         => 'ro',
        lazy_build => 1,
        handles    => { show_ticket => [ 'show', ( type => 'ticket' ) ] },
    );

    sub _build_rt {
        my $rt = RT::Client::REST->new( server => $_[0]->server );
        $rt->login( username => $_[0]->user, password => $_[0]->pass, );
        return $rt;
    }

    sub ticket {
        my ( $self, $id ) = @_;
        try {
            if ( my $t = $self->show_ticket( id => $id ) ) {
                return "$$t{Status} #${id}: $$t{Subject}";
            }
            return "Ticket $id not found";
        }
        catch {
            return "Problem talking to RT. $_";
        };
    }

    sub S_bot_addressed {
        my ( $self, $irc, $nickstring, $channels, $message ) = @_;
        given ($$message) {
            when (/^rt\s*#?\s*(\d+)$/) {
                $self->privmsg( $_ => $self->ticket($1) ) for @{$$channels};
                return PCI_EAT_ALL;
            }
            default { return PCI_EAT_NONE; };
        }
    }
}

bot rtBot {
    server 'irc.perl.org';
    channels '#moses';
    plugins RT => 'RT::Plugin';
}

rtBot->run;
