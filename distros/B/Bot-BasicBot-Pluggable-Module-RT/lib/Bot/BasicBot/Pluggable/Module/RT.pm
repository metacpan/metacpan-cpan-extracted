#
# This file is part of Bot-BasicBot-Pluggable-Module-RT
#
# This software is copyright (c) 2011 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

package Bot::BasicBot::Pluggable::Module::RT;
BEGIN {
  $Bot::BasicBot::Pluggable::Module::RT::VERSION = '0.20';
}

# ABSTRACT: This is a plugin to access information about RT tickets on IRC

use base qw(Bot::BasicBot::Pluggable::Module);

use RT::Client::REST;
use RT::Client::REST::Ticket;

sub init {
    my ($self) = @_;

    # default value for vars.
    foreach (qw(user_server user_login user_password)) {
        next if $self->get($_);
        $self->set($_, '** SET ME **')
   }
   defined $self->get('user_output')
       or $self->set('user_output', 'RT %i: %s - %S');
   defined $self->get('user_regexp')
       or $self->set('user_regexp', '(?:^|\s)rt\s*#?\s*(\d+)');
}

my $rt_handler;
my $connected = 0;

sub told {
    my ( $self, $mess ) = @_;
    my $bot = $self->bot();

    my $body = $mess->{body};

    my $regexp = $self->get('user_regexp');

    my ($nb) = $body =~ /$regexp/i
        or return;

    if (!$connected) {
        $rt_handler = RT::Client::REST->new(server => $self->get('user_server'));
        $rt_handler->login(
            username => $self->get('user_login'),
            password => $self->get('user_password')
        );
        $connected = 1;
    }

    my $ticket = RT::Client::REST::Ticket->new(
        rt  => $rt_handler,
        id  => $nb,
    );
    return unless defined $ticket;

    $ticket->retrieve();
    my %fields = (
        '%i' => $ticket->id(),
        '%q' => $ticket->queue(),
        '%c' => $ticket->creator(),
        '%s' => $ticket->subject(),
        '%S' => $ticket->status(),
        '%p' => $ticket->priority(),
        '%C' => $ticket->created(),
    );

    my $output = $self->get('user_output');
    while (my ($k, $v) = each(%fields)) {
        $output =~ s/\Q$k\E/$v/g;
    }
    return $output;
}

sub emoted {
    my $self = shift;
    $self->told(@_);
}

sub help { q(catch anything that looks like an RT number : /RT#?\s*(\d+)/i. it requires the RT server url, a login and password. Set them using '!set RT server', '!set RT login', '!set RT password'. The information displayed can be configured by setting the output string : '!set RT output some_string'. in the string, you can use the following placeholders :
%i : id of the ticket
%q : queue of the ticket
%c : creator of the ticket
%s : subject of the ticket
%S : status of the ticket
%p : priotity of the ticket
%C : time where it was created
Default is : 'RT %i: %s - %S';

The matching can be configured using : '!set RT regexp some_regexp'. The default is (?:^|\s)rt\s*#?\s*(\d+) .

You need to have the Vars module loaded before setting keys.
) }

1;



=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::RT - This is a plugin to access information about RT tickets on IRC

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    < you> RT#12345
    < bot> RT 12345: there is a bug in the matrix! - open

=head1 DESCRIPTION

This module uses RT::Client::REST::Ticket to connect to a RT server and grab
information on tickets.

=head1 NAME

Bot::BasicBot::Pluggable::Module::RT - Retrieves information of RT tickets

=head1 IRC USAGE

See synopsis

=head1 VARS

=over

=item server

The url of the RT server. Set it using:

  !set RT server <url>

=item login

The login to use. Set it using:

  !set RT login <login>

=item password

The password to use. Set it using:

  !set RT password <password>

=item output

The output format the bot should use to display information. Set it using:

  !set RT output <output_string>. 

the string can contain the following placeholders :

  %i : id of the ticket
  %q : queue of the ticket
  %c : creator of the ticket
  %s : subject of the ticket
  %S : status of the ticket
  %p : priotity of the ticket
  %C : time where it was created

Default is : 'RT %i: %s - %S';

=item regexp

The regexp that is used to extract the rt number from the body. Set it using:

  !set RT regexp <some_regexp>.

Its first match should be the rt number.
Default is (?:^|\s)rt\s*#?\s*(\d+)

=back

=head1 COMPLETE EXAMPLE

  #!/usr/bin/perl 
  
  use strict;
  use warnings;
  use Bot::BasicBot::Pluggable;
  
  my $bot = Bot::BasicBot::Pluggable->new(
      server => "server",
      port   => "6667",
      channels => ["#bottest"],
      nick      => "arty",
      alt_nicks => ["arty_", "_arty"],
      username  => "RT",
      name      => "RT Bot",
      charset => "utf-8", # charset the bot assumes the channel is using
  );
  
  my $rt_module=$bot->load("RT");
  $rt_module->set(user_server => 'http://rt.yourcompany.com');
  $rt_module->set(user_login => "user");
  $rt_module->set(user_password => "password");
  
  $bot->run();

=head1 AUTHOR

Damien "dams" Krotkine, C<< <dams@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-basicbot-pluggable-module-rt@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/>. I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2011 Damien "dams" Krotkine, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

