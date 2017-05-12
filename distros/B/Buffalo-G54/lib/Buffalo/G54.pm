###########################################
package WWW::Mechanize::Retry;
###########################################
use Log::Log4perl qw(:easy);
use base 'WWW::Mechanize';

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = __PACKAGE__->SUPER::new();

      # Defaults
    $self->{__PACKAGE__}->{nof_retries}           = 5;
    $self->{__PACKAGE__}->{sleep_between_retries} = 2;

    for(keys %options) {
        $self->{__PACKAGE__}->{$_} = $options{$_};
    }

      # Rebless
    bless $self, $class;
}

###########################################
sub get {
###########################################
    my($self, $url, @params) = @_;

    for(0..$self->{__PACKAGE__}->{nof_retries}) {

        if($_) {
            my $sleep = $self->{__PACKAGE__}->{sleep_between_retries};
            DEBUG "Sleeping $sleep secs";
            sleep $sleep;
            DEBUG "Retrying $url";
        }

        DEBUG "Fetching URL $url (#$_)";

        my $resp = $self->SUPER::get("$url");

        if($resp->is_success()) {
            DEBUG "Success: ", $resp->code(), 
                  " content=[", $resp->content(), "]";
            return $resp;
        }
    
        WARN "Error: " . $resp->code() . " (" . $resp->message() . " )";
        LOGDIE "Unauthorized" if $resp->code() == 401;
    }

    LOGDIE "Out of retries for ", $url;
}

###########################################
package Buffalo::G54;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);

our $VERSION = "0.03";

###########################################
sub new {
###########################################
    my($class) = @_;

    my $self = { 
        defaults    => { user => "root",
                         ip   => "192.168.0.1",
                       },
        realm       => "BUFFALO WBR2-G54",
        nof_retries => 5,
        sleep_between_retries => 2,
    };

    bless $self, $class;
}

###########################################
sub connect {
###########################################
    my($self, %options) = @_;

    if($ENV{BUFFALO}) {
          # For regression tests only
        my ($ip, $user, $password) = split /:/, $ENV{BUFFALO};
        $self->{ip}       = $ip;
        $self->{user}     = $user;
        $self->{password} = $password;
    } else {
        for(qw(user ip)) {
            $self->{$_} = def_or($options{$_}, 
                                 $self->{$_},
                                 $self->{defaults}->{$_}
                                );
        }
        $self->{password} = def_or($options{password}, 
                                   $self->{password},
                                   ""
                                  );
    }

    $self->{agent} = WWW::Mechanize::Retry->new(
        map { $_ => $self->{$_} } qw(nof_retries sleep_between_retries)
    );

    DEBUG "Setting credentials for $self->{ip}:80 $self->{user} $self->{realm}";

    $self->{agent}->credentials(
        "$self->{ip}:80", 
        $self->{realm},
        $self->{user},
        $self->{password}
    );

    $self->{url} = "http://$self->{ip}";

    $self->geturl("/");
}

###########################################
sub geturl {
###########################################
    my($self, $relurl) = @_;

    my $resp = $self->{agent}->get($self->{url} . $relurl);
    LOGDIE "Failed for fetch $relurl" if $resp->is_error();
    my $content = $resp->content();
    return $content;
}

###########################################
sub version {
###########################################
    my($self) = @_;

    my $content = $self->geturl("/advance/ad-admin-system.htm");
    if($content =~ /WBR2-G54 Ver.([0-9.]+)/) {
        DEBUG "Found Buffalo Version $1";
        return $1;
    }

    ERROR "Version not found ($content)";
    return undef;
}

###########################################
sub def_or {
###########################################
    my($def, @alts) = @_;

      # Still waiting for //= ...

    for my $alt ($def, @alts) {
        if(defined $alt) {
            return $alt;
        }
    }
    
    return undef;
}

###########################################
sub wireless {
###########################################
    my($self, $action) = @_;

    if(!defined $action) {
        return $self->is_wireless_on();
    } 

    if($action eq "on") {
        return $self->wireless_on();
    } elsif($action eq "off") {
        return $self->wireless_off();
    }

    LOGDIE "Unknown action '$action'";
}

###########################################
sub is_wireless_on {
###########################################
    my($self) = @_;

    $self->geturl("/advance/advance-lan-wireless.htm");
    my $agent = $self->{agent};
    $agent->follow_link(n => 3);

    my $content = $agent->content();

    if($content =~ /wl_radio" value="1.*?checked/) {
        DEBUG "wireless is on";
        return 1;
    } elsif($content =~ /wl_radio" value="0.*?checked/) {
        DEBUG "wireless is off";
        return 0;
    }

    LOGDIE "Cannot determine wireless state: $content";
}

###########################################
sub wireless_on {
###########################################
    my($self) = @_;

    my $agent = $self->{agent};

    $self->geturl("/advance/advance-lan-wireless.htm");
    $agent->follow_link(n => 3);
    $agent->form_number(1);
    $agent->field("wl_radio", "1");
    $agent->submit_form(form_number => "1");
}

###########################################
sub wireless_off {
###########################################
    my($self) = @_;

    my $agent = $self->{agent};

    $self->geturl("/advance/advance-lan-wireless.htm");

    $agent->follow_link(n => 3);
    $agent->form_number(1);
    $agent->field("wl_radio", "0");
    $agent->submit_form(form_number => "1");
}

###########################################
sub lan_proto {
###########################################
    my($self, $proto) = @_;

    my $agent = $self->{agent};

    $self->geturl("/advance/ad-lan-dhcp.htm");
    my $form = $agent->form_number(1);

    if(defined $proto) {
        $agent->field("lan_proto", $proto);
        $agent->submit_form(form_number => "1");
    } else {
        return $form->find_input("lan_proto")->value();
    }
}

###########################################
sub dhcp {
###########################################
    my($self, $status) = @_;

    if(defined $status) {
        if($status eq "on") {
            $self->lan_proto("dhcp");
        } elsif($status eq "off") {
            $self->lan_proto("static");
        }
    }

    my $lan_proto = $self->lan_proto();

    if($lan_proto eq "dhcp") {
        return 1;
    } elsif ($lan_proto eq "static") {
        return 0;
    } else { 
        LOGDIE "Unknown return lan_proto value";
    }
}

###########################################
sub reboot {
###########################################
    my($self) = @_;

    my $agent = $self->{agent};

    $self->geturl("/advance/ad-admin-init.htm");
    $agent->submit_form(form_number => "1");
}

###########################################
sub password {
###########################################
    my($self) = @_;

    system("stty -echo");
    $|++;
    print "Password: ";
    my $password = <STDIN>;
    system("stty echo");
    chomp $password;
    $self->{password} = $password;
}

1;

__END__

=head1 NAME

Buffalo::G54 - Limited scraping API for Buffalo WBR2-G54 routers

=head1 SYNOPSIS

    use Buffalo::G54;

=head1 DESCRIPTION

This module implements a limited API to control a Buffalo WBR2-G54 router 
by scraping its Web interface. 

=head2 METHODS

Currently, only the following methods are implemented:

=over 4

=item C<my $buf = Buffalo::G54-E<gt>new()>

Constructor.

=item C<$buf-E<gt>connect(...)>

Connects to the router's Web interface, takes the following key value pairs:

    ip       => "192.168.0.1",
    user     => "root",
    password => "topsecret!",

Returns C<1> if the router's Web interface responded properly, and
C<undef> otherwise.

=item C<$buf-E<gt>version()>

Ask the router for the version of its firmware. Returns something
like "WBR2-G54 Ver.2.21" if successful, or C<undef> on failure.

    http://192.168.0.1/advance/advance-admin-system.htm

=item C<$buf-E<gt>reboot()>

Reboot the router.

=item C<$buf-E<gt>wireless($status)>

Switch the router's wireless network on or off -- or query its status.

To query the status of the router's wireless network, call C<wireless()>
without parameters:

      # Returns "on" or "off"
    my $status = $buf->wireless();

It will return C<"on"> or C<"off">, or C<undef> if an error occurred.

      # Switch wireless off if it's on
    if($buf->wireless() eq "on") {
        $buf->wireless("off");
    }

To switch the wireless network on or off, pass a C<$status> value of
C<"on"> or C<"off"> to the C<wireless()> method.

Note that switching the wireless network on and off requires having
set up the wireless network in the first place. C<wireless()> is just
going to toggle the on/off switch, it doesn't configure the SSID,
encryption and other important settings.

=item C<$buf-E<gt>dhcp($status)>

Turns the DHCP server on or off or queries its status:

    $buf->dhcp("on");
    $buf->dhcp("off");

    if($buf->dhcp() eq "on") {
        print "dhcp is on!\n";
    }

=back

=head1 LEGALESE

Copyright 2006 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2006, Mike Schilli <cpan@perlmeister.com>
