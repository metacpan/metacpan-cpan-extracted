package Bot::BasicBot::CommandBot;

use strict;
use warnings;
use 5.014;

our $VERSION = 0.05;

use Tie::RegexpHash 0.16;
use List::Util qw(any);

use Exporter 'import';
use base qw/Bot::BasicBot/;

our @EXPORT_OK = qw(command autocommand);

my %command;
my %autocommand;

sub command {
    (caller)[0]->declare_command(@_);
}

sub autocommand {
    (caller)[0]->declare_autocommand(@_);
}

sub declare_autocommand {
    my ($package, $sub) = @_;
    $autocommand{$package} = $sub;
}

sub declare_command {
    my $package = shift;
    my $sub = pop;
    my $command = pop;

    my %options = @_;

    $options{events} //= ['said'];

    if (not exists $command{$package}) {
        $command{$package} = {};
        tie %{$command{$package}}, 'Tie::RegexpHash';
    }

    $command{$package}{$command} = {
        sub => $sub,
        %options,
    };
}


sub new {
    my $class = shift;
    my %opts = @_;

    my $address = delete $opts{address};
    my $trigger = delete $opts{trigger};
    my $bark    = delete $opts{bark} // 1;

    my $self = $class->SUPER::new(%opts);
    $self->{trigger} = $trigger if defined $trigger;
    $self->{address} = $address if defined $address;
    $self->{bark}    = $bark;

    return $self;
}

sub said {
    my $self = shift;
    my ($data) = @_;

    $self->{command} = $data;
    my $package = ref $self;

    my ($cmd, $message) = split ' ', $data->{body}, 2;

    my $autosay = $self->_auto($data->{body});

    if ($self->{address} and not $data->{address}) {
        return $autosay;
    }

    if ($self->{trigger} and $data->{body} !~ s/^\Q$self->{trigger}//) {
        return $autosay;
    }

    my $found = $command{$package}{$cmd};

    if (!$found) {
        return "What is $cmd?" if $self->{bark};
        return $autosay;
    }

    my $say;
    if (any { $_ eq 'said' } @{$found->{events}}) {
        $say = $found->{sub}->($self, $cmd, $message);
    }

    return $say // $autosay;
}

sub emoted {
}

sub noticed {
}

sub _auto {
    my ($self, $message) = @_;
    join ' ', map $_->($self, $message), values %autocommand;
}

1;

__END__

=head1 NAME

Bot::BasicBot::CommandBot

=head1 DESCRIPTION

Simple declarative syntax for an IRC bot that responds to commands.

=head1 SYNOPSIS

    command hello => sub {
        my ($self, $cmd, $message) = @_;
        return "Hello world!"
    }

    command qr/^a+/ => sub {
        return 'a' x rand 6;
    }

    sub _auto {
        return "hi" if shift =~ /hello/;
    }

=head1 CONSTRUCTION

Construction of the bot is the same as Bot::BasicBot, as is running it.

CommandBot takes three new options to C<new>:

=over

=item C<bark>

If true, the bot will ask "What is $cmd?" for any command for which no
appropriate handler is found. If not, the bot will remain silent. This defaults
to true.

=item C<trigger>

If provided, this string will be required at the start of any message for it to
be considered a bot command. Common examples include C<!>, C<?> and C<@>.

This string will be removed from the command.

=item C<address>

If provided and a true value, the bot will only respond if directly addressed.
"Addressed" is actually defined by Bot::BasicBot, so if the bot is not
addressed, nothing will happen.

=back

Despite the above, autocommands will always be called, regardless.

If both options are provided, the bot must be addressed I<and> the command must
be prefixed with the trigger for a response to happen.

=head1 COMMANDS

A command is considered to be the first contiguous string of non-whitespace
after the preprocessing done by the address and trigger detection.

    !command text text
    Commandbot: command text text
    Commandbot: !command text text

In all these cases, C<command> is the B<command>. C<text text> is then a single
string, regardless of how long it is.  This is the B<message>.

The command string is then looked up in the list of declared commands. If it is
exactly equal to a command declared as a string, or matches a command declared
with a regex, the associated subref is run.

If it does not match, the bot says "What is $command?".

=head1 DECLARING COMMANDS

=head2 command

The C<command> function declares a command. It accepts either a string or a
regex, and a subref. The subref will be called whenever the bot is activated
with a matching string.

The subref receives C<$self>, C<$cmd> and C<$message>: The bot object, the
matched command and the rest of the message.

    command qr/^./ => sub {
        ...
    };

The return value from this subref is then spoken in the same place the
original message was received.

C<$self> is an instance of Bot::BasicBot::CommandBot, which of course extends
Bot::BasicBot, and therefore all things that can do, your bot can do.

=head2 declare_command

This function is called by C<command>. It is a package method. It takes the
same arguments as C<command>, but it is called on a package:

    __PACKAGE__->declare_command(qr/^./, sub { ... });

This can be helpful if you don't want to put all your commands in the same
module - you can declare them all on the same package.

    sub import {
        my $caller = (caller)[0];
        $caller->declare_command(...);
    }

=head2 autocommand

An autocommand will be processed regardless of whether the message was
interpreted as a command or not.

    autocommand => sub {
        my $self = shift;
        my $message = shift;
    };

This is intended as a hook for you to perform any actions necessary as a result
of people talking in general, or for bots that think they're human and want to
join in.

It is not generally considered sensible to return a value from autocommands,
but if you wish to, be aware that the return value of autocommands is only
spoken if an actual command does not say something. Also, the return values
from all autocommands across all packages will be joined together

=head2 declare_autocommand

The equivalent of C<declare_command> for autocommands. Lets you create an
autocommand from a package besides one that extends the bot.
