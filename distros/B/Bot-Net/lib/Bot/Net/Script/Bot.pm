use strict;
use warnings;

package Bot::Net::Script::Bot;
use base qw/ App::CLI::Command Class::Accessor::Fast /;

use Bot::Net;
use File::Copy;
use File::Spec;
use FindBin;
use UNIVERSAL::require;

__PACKAGE__->mk_accessors( qw{
    bot_class bot_file bot_conf bot_state

    mixin_classes

    clone_class clone_conf
});

=head1 NAME

Bot::Net::Script::Bot - Create a new bot

=head1 SYNOPSIS

  bin/botnet bot --name <bot name> [ <options> ]

=head1 DESCRIPTION

This command will create a single bot and automatically generate any additional files such as basic tests, stub configuration file, etc. 

With no options other than the bot name, this will create a vanilla bot that uses the L<Bot::Net::Bot> mixin and nothing else. The options can further customize this situation.

=head1 OPTIONS

  --name <bot name>        - The name of the bot class to create
  --mixin <mixin name>     - The name of a bot mixin to add to the class. This 
                             option may be specified multiple times.
  --clone <bot name>       - The name of a bot to clone from. If given, the new
                             bot will inherit from the given bot's class and 
                             the configuration for that bot will also be used 
                             as the basis for the new class

=head1 METHODS

=head2 options

Returns the arguments used by this script. See L<App::CLI::Command>.

=cut

sub options {
    ( 
        'name=s'   => 'name',
        'mixin=s@' => 'mixins',
        'clone=s'  => 'clone',
    );
}

=head2 run

Creates the bot according to the options specified.

=cut

sub run {
    my ($self, @args) = @_;

    defined $self->{name}
        or die "No bot name given with required --name option.\n";

    $self->bot_class( Bot::Net->net_class('Bot', $self->{name}) );
    $self->bot_file( 
        File::Spec->catfile(
            $FindBin::Bin, '..', 'lib', 
            split(/::/, $self->bot_class)
        ) . '.pm'
    );
    $self->bot_conf(
        File::Spec->catfile(
            $FindBin::Bin, '..', 'etc', 'bot', 
            split(/::/, $self->{name})
        ) . '.yml'
    );
    $self->bot_state(
        File::Spec->catfile(
            $FindBin::Bin, '..', 'var', 'bot',
            split(/::/, $self->{name})
        ) . '.db'
    );

    my @mixins = @{ $self->{mixins} || [] };
    my @mixin_classes = (
        'Bot::Net::Bot',
        map { 'Bot::Net::Mixin::Bot::'.$_ } @mixins
    );

    $self->mixin_classes( \@mixin_classes );

    if ($self->{clone}) {
        $self->clone_class( Bot::Net->net_class('Bot', $self->{clone}) );

        $self->clone_config( 
            File::Spec->catfile(
                $FindBin::Bin, '..', 'etc', 'bot', 
                split(/::/, $self->{clone})
            ) . '.yml'
        );
    }
    
    $self->_create_bot_module;
    $self->_create_bot_config;
    # TODO XXX FIXME Add _create_bot_test()
#    $self->_create_bot_test;
}

sub _create_bot_module {
    my $self = shift;
    
    open my $botmod, '>', $self->bot_file
        or die "Cannot write to @{[$self->bot_file]}: $!";

    print "Creating ",$self->bot_file,"...\n";

    print $botmod <<"END_OF_BOT_MODULE_START";
use strict;
use warnings;

package @{[$self->bot_class]};
END_OF_BOT_MODULE_START

    if ($self->{clone}) {
        print $botmod <<"END_OF_BOT_MODULE_CLONE";

use base qw/ @{[$self->clone_class]} /;

END_OF_BOT_MODULE_CLONE
    }

    else {
        print $botmod <<"END_OF_BOT_MODULE_NEW";

@{[join "\n", map { 'use '.$_.';' } @{ $self->mixin_classes }]}

END_OF_BOT_MODULE_NEW
    }

    print $botmod <<"END_OF_BOT_MODULE_END";
=head1 NAME

@{[$self->bot_class]} - A semi-autonomous agent that does something

=head1 SYNOPSIS

  bin/botnet run --bot $self->{name}

=head1 DESCRIPTION

A semi-autonomous agent that does something. This documentation needs replacing.

=cut

1;

END_OF_BOT_MODULE_END
}

sub _create_bot_config {
    my $self = shift;

    if ($self->{clone} and -f $self->clone_conf) {
        print "Copying ",$self->clone_conf," to ",$self->bot_conf,"...\n";
        copy($self->clone_conf, $self->bot_conf);
    }

    else {
        print "Creating ",$self->bot_conf,"...\n";

        my @configs;
        for my $mixin_class (@{ $self->mixin_classes || [] }) {
            $mixin_class->require;
            if (my $method = $mixin_class->can('default_configuration')) {
                push @configs, $method->($mixin_class, $self->bot_class);
            }
        }

        my $bot_conf = Hash::Merge::merge( @configs );

        YAML::Syck::DumpFile( $self->bot_conf, $bot_conf );
    }
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
