#!perl -T

my @MODULES = qw/
AnyEvent::XMPP::IM::Contact
AnyEvent::XMPP::IM::Roster
AnyEvent::XMPP::IM::Connection
AnyEvent::XMPP::IM::Presence
AnyEvent::XMPP::IM::Account
AnyEvent::XMPP::IM::Message
AnyEvent::XMPP::Ext::Disco::Info
AnyEvent::XMPP::Ext::Disco::Items
AnyEvent::XMPP::Ext::DataForm
AnyEvent::XMPP::Ext::OOB
AnyEvent::XMPP::Ext::Pubsub
AnyEvent::XMPP::Ext::Registration
AnyEvent::XMPP::Ext::Disco
AnyEvent::XMPP::Ext::RegisterForm
AnyEvent::XMPP::Namespaces
AnyEvent::XMPP::Util
AnyEvent::XMPP::Ext
AnyEvent::XMPP::Error::SASL
AnyEvent::XMPP::Error::IQ
AnyEvent::XMPP::Error::Register
AnyEvent::XMPP::Error::Exception
AnyEvent::XMPP::Error::Stanza
AnyEvent::XMPP::Error::Stream
AnyEvent::XMPP::Error::Parser
AnyEvent::XMPP::Error::Presence
AnyEvent::XMPP::Error::Message
AnyEvent::XMPP::Client
AnyEvent::XMPP::SimpleConnection
AnyEvent::XMPP::Extendable
AnyEvent::XMPP::Writer
AnyEvent::XMPP::Component
AnyEvent::XMPP::Parser
AnyEvent::XMPP::Connection
AnyEvent::XMPP::Error
AnyEvent::XMPP::Node
AnyEvent::XMPP
/;

use Test::More;
plan tests => scalar @MODULES;
use_ok $_ for @MODULES;

diag( "Testing AnyEvent::XMPP $AnyEvent::XMPP::VERSION, Perl $], $^X" );

