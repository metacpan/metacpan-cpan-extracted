=head1 NAME

Bot::Jabbot - simple pluggable jabber bot

=head1 SYNOPSIS

  #!/usr/bin/perl
  use Bot::Jabbot;
  use warnings;
  use strict;
  
  my $bot = Bot::Jabbot->new("./config.yaml");
  $bot->start();

=head1 DESCRIPTION

Bot::Jabbot allows you to easily create jabber bot. All you need is to write config file and use or write some modules that will handle messages.

=head1 METHODS

   

=cut

package Bot::Jabbot;

use strict;
use utf8;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/node_jid res_jid/;
use Encode qw(decode_utf8);
use Config::Any::YAML;
use Data::Dumper;
use Class::MOP;
use Data::Localize;

our $VERSION = 0.41;

=head2 new(...)

Creates new bot instance.
Accepts path to configuration file in yaml format as first param (defaults to ./bot.conf)

=cut


sub new
{
    my $class = shift;
    my $conf = shift || "./bot.conf";
    my $self = {};

    $self->{config}=Config::Any::YAML->load($conf) || die("Can't open config file\n");
    die "No jid or password specified\n" if (!$self->{config}->{jid} || !$self->{config}->{password});
    $self->{j}       = AnyEvent->condvar;
    $self->{cl}      = AnyEvent::XMPP::Client->new (debug => $self->{config}->{debug} || 0);
    my $disco   = AnyEvent::XMPP::Ext::Disco->new;
    my $version = AnyEvent::XMPP::Ext::Version->new;
    $version->set_name    ("Jabbot");
    $version->set_version ($VERSION);
    $version->set_os      ("Windows 8 build 8501");
    $self->{muc} = AnyEvent::XMPP::Ext::MUC->new (disco => $disco);
    $self->{cl}->add_extension ($disco);
    $self->{cl}->add_extension ($version);
    $self->{cl}->add_extension ($self->{muc});

    $self->{cl}->set_presence (undef, $self->{config}->{status} || "", 1);
    $self->{cl}->add_account ($self->{config}->{jid}, $self->{config}->{password},undef,undef,{resource => "Bot"});
    while (my ($name,$mod)=each(%{$self->{config}->{modules}}))
    {
        print "loading $mod \n";
        Class::MOP::load_class($mod);
        $self->{modules}->{$name}=$mod->new($self->{config}->{lang} || "en");
    }
    my $calldir = $class;
    $calldir =~ s{::}{/}g;
    my $file = "$calldir.pm";
    my $path = $INC{$file};
    $path =~ s{\.pm$}{/I18N};

    $self->{loc} = Data::Localize->new();
    $self->{loc}->add_localizer( 
        class => "Gettext",
        path  => $path."/*.po"
    );
    $self->{loc}->auto(1);
    $self->{loc}->set_languages($self->{config}->{lang} || "en");

    bless($self, $class);
    return $self;
}

=head2 start()

Initializes required modules and starts bot.

=cut


sub start
{
    my $self=shift;

    $self->{cl}->reg_cb(
        session_ready => sub {
            my ($cl, $acc) = @_;
            while (my ($name,$mod)=each(%{$self->{modules}}))
            {
                $mod->init($cl,$acc->connection->jid);
            }

            foreach my $room(@{$self->{config}->{rooms}})
            {
                if (ref $room eq 'HASH')
                {
                    my @keys=keys %{$room};
                    $self->{muc}->join_room ($acc->connection, $keys[0], $self->{config}->{nickname},%{$room->{$keys[0]}});
                }
                else
                {
                    $self->{muc}->join_room ($acc->connection, $room, $self->{config}->{nickname});
                }
            }

            $self->{muc}->reg_cb(
                message => sub {
                    my ($cl, $room, $msg, $is_echo) = @_;
                    return if $is_echo;
                    return if $msg->is_delayed;
                    return if !$msg->from_nick;
                    my $mynick = res_jid ($room->nick_jid);
                    if ($msg->any_body=~m/^!help (.+)/)
                    {
                        if(my $mod=$self->{modules}->{$1})
                        {
                            if ($mod->can("muc_help"))
                            {
                                my $ans=$mod->muc_help();
                                my $repl = $msg->make_reply;
                                $repl->add_body ($ans);
                                $repl->send;
                            }
                        }
                    }
                    elsif ($msg->any_body=~m/^!help\s*/)
                    {
                        my $ans=$self->{loc}->localize("Following modules are loaded:\n");
                        while ( my ($key, $mod) = each(%{$self->{modules}}) )
                        {
                            if ($mod->can("muc_help"))
                            {
                                $ans.="$key\n";
                            }
                        }
                        $ans.=$self->{loc}->localize("For details type !help <module_name>");
                        my $repl = $msg->make_reply;
                        $repl->add_body ($ans);
                        $repl->send;
                    }
                    else
                    {
                        while ( my ($key, $mod) = each(%{$self->{modules}}) )
                        {
                            if ($mod->can("muc"))
                            {
                                my $ans=$mod->muc($msg,$mynick,$self);
                                if ($ans)
                                {
                                    my $repl = $msg->make_reply;
                                    $repl->add_body($ans);
                                    $repl->send;
                                }
                            }
                        }
                    }
                },
                subject_change => sub {
                    my ($cl, $room, $msg,$is_echo) = @_;
                    if(!$is_echo)
                    {
                        while ( my ($key, $mod) = each(%{$self->{modules}}) )
                        {
                            if ($mod->can("muc_subject_change"))
                            {
                                $mod->muc_subject_change($room,$msg,$cl);
                            }
                        }
                    }
                },
                join => sub {
                    my ($cl, $room, $user) = @_;
                    while ( my ($key, $mod) = each(%{$self->{modules}}) )
                    {
                        if ($mod->can("muc_join"))
                        {
                            $mod->muc_join($user,$room,$cl);
                        }
                    }
                },
                part => sub {
                    my ($cl, $room, $user) = @_;
                    while ( my ($key, $mod) = each(%{$self->{modules}}) )
                    {
                        if ($mod->can("muc_part"))
                        {
                            $mod->muc_part($user,$room,$cl);
                        }
                    }
                },
                presence => sub {
                    my ($cl, $room, $user) = @_;
                    my $mynick = res_jid ($room->nick_jid);
                    while ( my ($key, $mod) = each(%{$self->{modules}}) )
                    {
                        if ($mod->can("muc_presence"))
                        {
                            $mod->muc_presence($user,$room,$cl);
                        }
                    }
                }
            );
        },
        message => sub {
            my ($cl, $acc, $msg) = @_;
            if ($msg->any_body=~m/^!help (.+)/)
            {
                if(my $mod=$self->{modules}->{$1})
                {
                    if($mod->can("help"))
                    {
                        my $ans=$mod->help();
                        my $repl = $msg->make_reply;
                        $repl->add_body ($ans);
                        $repl->send;
                    }
                }
            }
            elsif ($msg->any_body=~m/^!help\s*/)
            {
                my $ans=$self->{loc}->localize("Following modules are loaded:\n");
                while ( my ($key, $mod) = each(%{$self->{modules}}) )
                {
                    if ($mod->can("help"))
                    {
                        $ans.="$key\n";
                    }
                }
                $ans.=$self->{loc}->localize("For details type !help <module_name>");
                my $repl = $msg->make_reply;
                $repl->add_body ($ans);
                $repl->send;
            }
            else
            {
                while ( my ($key, $mod) = each(%{$self->{modules}}) )
                {
                    if ($mod->can("message"))
                    {
                        my $ans=$mod->message($msg,$self);
                        if ($ans)
                        {
                            my $repl = $msg->make_reply;
                            $repl->add_body ($ans);
                            $repl->send;
                        }
                    }
                }
            }
        },
        contact_request_subscribe => sub {
            my ($cl, $acc, $roster, $contact) = @_;
            $contact->send_subscribed;
        },
        error => sub {
            my ($cl, $acc, $error) = @_;
            warn "Error encountered: ".$error->string."\n";
            $self->{j}->broadcast;
        },
        disconnect => sub {
            warn "Got disconnected: [@_]\n";
            $self->{j}->broadcast;
        },
    );
    $self->{cl}->start;
    $self->{j}->wait;
}

=head2 setlang()

Changes currently used language for bot and all loaded modules.

=cut


sub setlang
{
    my ($self,$lang) = @_;
    $self->{loc}->set_languages($lang || "en");
    while ( my ($modname, $module) = each(%{$self->{config}->{modules}}) )
    {
        $self->{modules}->{$modname}->setlang($lang || "en");
    }
    return;
}

1;
__END__

=head1 CONFIGURATION

  jid: jabbot@somehost.ru
  password: somepassword
  nickname: Jabbot
  debug: 0
  modules:
    replier: Bot::Jabbot::Module::Replier
    replier: Bot::Jabbot::Module::Replier
    replier: Bot::Jabbot::Module::Replier
  rooms:
    - someroom@conference.somehost.ru
        password: secret
    - someotherroom@conference.somehost.ru
  status: "I'm bot, i'm bot, you know that i'm a bot"
  lang: en

B<jid> - jid of jabber bot

B<password> - password for jabber bot

B<nickname> - nickname for MUC

B<modules> - hash of module name => module package. You can define any unical module name, as it used only for !help command

B<rooms> - list of MUC rooms jid's. Room can be eather a string or a hash with join parameters (for info look at %args description in AnyEvent::XMPP::Ext::MUC join_room method)

B<debug> - enable debug output

B<status> - status text

B<lang> - language of the bot (Language files are stored in the Jabbot/I18N subdirectory for bot, and ModuleName/I18N subdirectory for modules)

=head1 DEPENDENCIES

=over 4

=item AnyEvent

=item AnyEvent::XMPP

=item Class::MOP

=item Config::Any

=item Encode

=back

=head1 AUTHOR

Epifanov Ivan C<isage@aumi.ru>

=head1 COPYRIGHT

    This module copyright (c) 2009 Ivan Epifanov.
    All rights reserved. This module is free software; you can redistribute it 
    and/or modify it under the terms of the Perl Artistic License.
    (see http://www.perl.com/perl/misc/Artistic.html)

=cut