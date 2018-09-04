package Datahub::Factory::Logger;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Moo::Role;
use MooX::Aliases;
use namespace::clean;

with 'MooX::Role::Logger';

alias log => '_logger';

1;

__END__

=head1 NAME

Datahub::Factory::Logger - A role for classes that need logging capabilities

=head1 SYNOPSIS

    package MyApp::View;
    use Moo;

    with 'Datahub::Factory::Logger';

    sub something {
        my ($self) = @_;
        $self->log->debug("started bar"); # logs with default class catergory "MyApp::View"
        $self->log->error("started bar");
    }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Any>.  Connecting
a Log::Any::Adapter should be performed prior to logging the first log message,
otherwise nothing will happen, just like with Log::Any.

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Any::Adapter;
    use Log::Log4perl;

    Log::Any::Adapter->set('Log4perl');
    Log::Log4perl::init('./log4perl.conf');

    my $app = MyApp::View->new;
    $app->something();  # will print debug and error messages

with log4perl.conf like:

    log4perl.rootLogger=DEBUG,OUT
    log4perl.appender.OUT=Log::Log4perl::Appender::Screen
    log4perl.appender.OUT.stderr=1
    log4perl.appender.OUT.utf8=1

    log4perl.appender.OUT.layout=PatternLayout
    log4perl.appender.OUT.layout.ConversionPattern=%d [%P] - %p %l time=%r : %m%n

See L<Log::Log4perl> for more configuration options and selecting which messages
to log and which not.

=head1 DATAHUB FACTORY COMMAND LINE

When using the L<dhconveyor> command line, the logger can be activated using the
-D option on all Datahub Factory commands:

     $ dhconveyor -D transport ...

=head1 METHODS

L<Log::Any>

=head1 ACKNOWLEDGMENTS

Code and documentation blatantly stolen from C<Catmandu> who got it from
C<MooX::Log::Any>.

=cut
