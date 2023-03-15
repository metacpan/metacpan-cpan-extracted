package Test::Bot::BasicBot::Pluggable;
$Test::Bot::BasicBot::Pluggable::VERSION = '1.30';
use warnings;
use strict;
use base qw( Bot::BasicBot::Pluggable );

sub new {
    my ( $class, %args ) = @_;
    my $bot = $class->SUPER::new(
        store => 'Memory',
        nick  => 'test_bot',
        %args
    );
    return bless $bot, $class;
}

sub tell_private {
    return shift->tell( shift, 1, 1 );
}    # tell the module something privately

sub tell_direct { return shift->tell( shift, 0, 1 ) }

sub tell_indirect {
    return shift->tell( shift, 0, 0 );
}    # the module has seen something

sub tell {
    my ( $bot, $body, $private, $addressed, $who ) = @_;
    my @reply;
    my $message = {
        body       => $body,
        who        => $who || 'test_user',
        channel    => $private ? 'msg' : '#test',
        address    => $addressed,
        reply_hook => sub { push @reply, $_[1]; },    # $_[1] is the reply text
    };
    if ( $body =~ /^help/ and $addressed ) {
        push @reply, $bot->help($message);
    }
    else {
        $bot->said($message);
    }
    return join "\n", @reply;
}

sub connect {
    my $self = shift;
    $self->dispatch('connected');
}

# otherwise AUTOLOAD in Bot::BasicBot will be called
sub DESTROY { }

1;

__END__

=head1 NAME

Test::Bot::BasicBot::Pluggable - utilities to aid in testing of Bot::BasicBot::Pluggable modules

=head1 VERSION

version 1.30

=head1 SYNOPSIS

  use Test::More;
  use Test::Bot::BasicBot::Pluggable;

  my $bot = Test::Bot::BasicBot->new();
  $bot->load('MyModule');

  is ( $bot->tell_direct('foo'),   'bar');
  is ( $bot->tell_indirect('foo'), 'bar');
  is ( $bot->tell_private('foo'),  'bar');

=head1 DESCRIPTION

Test::Bot::BasicBot::Pluggable was written to provide a
minimalistic testing bot in order to write cleaner unit tests for
Bot::BasicBot::Pluggable modules. 

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new Test::Bot::BasicBot::Pluggable object, which is
basically just a subclass of Bot::BasicBot::Pluggable with a few
special methods. The default nickname is 'test_bot' and it contains
a in-memory store instead of sqlite. It takes the same arguments as
Bot::BasicBot::Pluggable.

=head1 INSTANCE METHODS

=head2 tell_direct

Sends the provided string to the bot like it was send directly to the bot in a public channel. The channel is called '#test' and the sending user 'test_user'.

  test_user@#test> test_bot: foo

=head2 tell_indirect

Sends the provided string to the bot like it was send to a public channel without addressing. The channel is called '#test' and the sending user 'test_user'.

  test_user@#test> foo

=head2 tell_private

Sends the provided string to the bot like it was send in a private channel. The sending user 'test_user'.

  test_user@test_bot> foo

=head2 tell

This is the working horse of Test::Bot::BasicBot::Pluggable. It
basically builds a message hash as argument to the bots said()
function. You should never have to call it directly.

=head2 connect

Dispatch the connected event to all loaded modules without actually
connecting to anything.

=head2 DESTROY

The special subroutine is explicitly overridden with an empty
subroutine as otherwise AUTOLOAD in Bot::BasicBot will be called
for it.

=head1 BUGS AND LIMITATIONS

There are no methods to test join, part and emote.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
