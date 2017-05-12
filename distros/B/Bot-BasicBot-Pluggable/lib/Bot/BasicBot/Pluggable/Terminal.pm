package Bot::BasicBot::Pluggable::Terminal;
$Bot::BasicBot::Pluggable::Terminal::VERSION = '1.20';
use warnings;
use strict;
use base qw(Test::Bot::BasicBot::Pluggable);

# Loader lets you tell the bot to load other modules.

sub run {
    my $self = shift;
    while (1) {
        last if eof STDIN;
        my $in = <STDIN>;
        chomp $in;

        # strip off whitespace before and after the message
        $in =~ s!(^\s*|\s*$)!!g;

        last if $in eq 'quit';
        my $ret = $self->tell( $in, 1, 1, $ENV{USER} );
        print "$ret\n" if $ret;
    }
}

1;

__END__

=head1 NAME

bot-basicbot-pluggable.pl - A standard Bot::BasicBot::Pluggable script

=head1 VERSION

version 1.20

=head1 DESCRIPTION

A standard Bot::BasicBot::Pluggable interface. You can /query the bot
to load in more modules. Change the admin password ASAP - See perldoc
L<Bot::BasicBot::Pluggable::Auth> for details of this.

=head1 USAGE

  bot-basicbot-pluggable-cli

=head2 SEE ALSO

Bot::BasicBot::Pluggable
