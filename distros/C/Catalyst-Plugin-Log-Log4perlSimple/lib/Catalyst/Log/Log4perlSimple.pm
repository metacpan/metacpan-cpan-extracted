package Catalyst::Log::Log4perlSimple;
BEGIN {
  $Catalyst::Log::Log4perlSimple::VERSION = '0.3';
}

use 5.010;
use strict;

use Moose;
use Log::Log4perl;
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Appender::ScreenColoredLevels;
use Log::Log4perl::Appender::File;

=head1 NAME

Catalyst::Log::Log4perlSimple

=head1 SYNOPSIS

Generally speaking you probably don't want to use this directly, instead you
should use L<Catalyst::Plugin::Log::Log4perlSimple>.

If you do want do use it, generally it would be in the form:

    __PACKAGE__->log(Catalyst::Log::Log4perlSimple->new);

=head1 DESCRIPTION

This is a replacement for Catalyst's L<Catalyst::Log> object. It provides the
same functionality (including flush/abort) so that plugins that don't want to
log particular requests can do so successfully.

=head1 AUTHOR

Martyn Smith <martyn@catalyst.net.nz>

=head1 METHODS

=cut

has autoflush       => ( is => 'rw', isa => 'Bool', default => 0 );
has abort           => ( is => 'rw', isa => 'Bool', default => 0 );
has proxy           => (
    is => 'rw',
    isa => 'Log::Log4perl::Appender',
);

=head2 _flush()

This method is the same as L<Catalyst::Log>'s _flush method. Depending on the
abort flag it either clears the buffer, or flushes it to screen/file.

=cut

sub _flush {
    my ($self) = @_;

    if ( $self->abort ) {
        $self->proxy->clear;
        $self->abort(0);
    }

    $self->proxy->flush;
}

has screen_output   => ( is => 'rw', isa => 'Bool', default => 0, trigger => sub {
    my ($self, $value) = @_;
    if ( $value ) {
        $self->proxy->add_appender($self->screen_appender);
    }
    else {
        $self->proxy->remove_appender($self->screen_appender);
    }
});
has file_output     => ( is => 'rw', isa => 'Maybe[Str]', default => undef, trigger => sub {
    my ($self, $value) = @_;

    if ( $self->file_appender ) {
        $self->proxy->remove_appender($self->file_appender);
    }

    if ( $value ) {
        my $appender = Log::Log4perl::Appender::File->new(
            filename => $value,
            mode     => 'append',
        );
        $self->proxy->add_appender($appender);
        $self->file_appender($appender);
    }
});
has screen_appender => (
    is  => 'rw',
    isa => 'Log::Log4perl::Appender',
    required => 1,
    default => sub {
        my $class = -t STDIN && -t STDOUT ? 'Log::Log4perl::Appender::ScreenColoredLevels' : 'Log::Log4perl::Appender::Screen';
        $class->new(
            color => {
                warn  => 'magenta',
                error => 'red',
                fatal => 'red',
            },
        );
    },
);
has file_appender => (
    is  => 'rw',
    isa => 'Maybe[Log::Log4perl::Appender]',
    default => undef,
);

=head2 debug(...)

=head2 info(...)

=head2 warn(...)

=head2 error(...)

=head2 fatal(...)

=head2 is_debug(...)

=head2 is_info(...)

=head2 is_warn(...)

=head2 is_error(...)

=head2 is_fatal(...)

=cut

{
    my @levels = qw(debug info warn error fatal);

    foreach my $name ( @levels ) {
        no strict 'refs';
        *{$name} = sub {
            my ( $self, @message ) = @_;
            my ( $package ) = caller;
            {
                local $Log::Log4perl::caller_depth;
                $Log::Log4perl::caller_depth++;
                Log::Log4perl->get_logger($package)->$name(@message);
            }
        };
        *{"is_$name"} = sub {
            my ( $self, @message ) = @_;
            my ( $package ) = caller;
            my $func   = "is_" . $name;
            return Log::Log4perl->get_logger($package)->$func;
        };
    }
}

=head2 BUILD()

Invoked by Moose after the object is constructed, this just initialises
Log4perl using a custom config which uses the
L<Log::Log4perl::Appender::CatalystProxy> appender.

=cut

sub BUILD {
    my ($self) = @_;
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->init(\qq{
            log4perl.rootLogger = DEBUG, PROXY

            log4perl.appender.PROXY=Log::Log4perl::Appender::CatalystProxy
            log4perl.appender.PROXY.autoflush=0
            log4perl.appender.PROXY.layout=PatternLayout
            log4perl.appender.PROXY.layout.ConversionPattern=%d{HH:mm:ss} %18c{2} [%4L]: %m%n
        });
    }
    my $proxy = Log::Log4perl->appender_by_name('PROXY');
    unless ( UNIVERSAL::isa($proxy, 'Log::Log4perl::Appender::CatalystProxy') ) {
        die q{Can't find the PROXY Log4perl Appender};
    }
    $self->proxy($proxy);
}


1;
