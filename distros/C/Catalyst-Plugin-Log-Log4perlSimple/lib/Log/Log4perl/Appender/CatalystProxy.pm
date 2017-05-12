package Log::Log4perl::Appender::CatalystProxy;
BEGIN {
  $Log::Log4perl::Appender::CatalystProxy::VERSION = '0.3';
}

our @ISA = qw(Log::Log4perl::Appender);

use 5.010;
use warnings;
use strict;

use Log::Log4perl::Level;

=head1 NAME

Log::Log4perl::Appender::CatalystProxy

=head1 SYNOPSIS

Generally speaking you probably don't want to use this directly, instead you
should use L<Catalyst::Plugin::Log::Log4perlSimple>.

If you do want do use it, refer to the L<Log::Log4perl> documentation.

=head1 DESCRIPTION

This is a custom appender for L<Log::Log4perl> that proxies messages to other
appenders. It is capable of pushing messages out to multiple appenders, and
also of buffering messages until an appender is allocated to it.

=head1 AUTHOR

Martyn Smith <martyn@catalyst.net.nz>

=head1 METHODS

=head2 new(%options)

Create an instance of this appender.

Options are:
    
- autoflush (boolean that indicates if logged messages should be proxied immediately)
- appenders (arrayref of appenders to proxy to; defaults to [])

=cut

sub new {
    my ($class, @options) = @_;

    my $self = {
        name      => 'unknown name',
        buffer    => [],
        autoflush => 1,
        appenders => [],
        @options,
    };

    return bless $self, $class;
};

=head2 log(%params)

Implementation of the log method for L<Log::Log4perl::Appender>

=cut

sub log {
    my ($self, %params) = @_;

    if ( $self->{autoflush} and @{$self->{appenders}} ) {
        foreach my $appender ( @{$self->{appenders}} ) {
            $appender->log(%params);
        }
    }
    else {
        push @{$self->{buffer}}, \%params;
    }
}

=head2 appenders()

Return a list of the appenders this object it proxying to

=cut

sub appenders { return @{shift->{appenders}} }

=head2 add_appender($appender)

Add $appender to the list of appenders this object is proxying for

=cut

sub add_appender {
    my ($self, $appender) = @_;

    push @{$self->{appenders}}, $appender;

    $self->flush if $self->{autoflush};
};

=head2 remove_appender($appender)

Remove $appender from the list of appenders this object is proxying for

=cut

sub remove_appender {
    my ($self, $appender) = @_;

    @{$self->{appenders}} = grep { $_ != $appender } @{$self->{appenders}};
}

=head2 flush()

Push everything in the buffer out to configured appenders then empty the
buffer.

=cut

sub flush {
    my ($self) = @_;

    return unless @{$self->{appenders}};

    foreach my $message ( @{$self->{buffer}} ) {
        foreach my $appender ( @{$self->{appenders}} ){
            $appender->log(%{$message});
        }
    }
    $self->{buffer} = [];
}

=head2 clear()

Clear the buffer without pushing the messages out to configured appenders

=cut

sub clear {
    my ($self) = @_;

    $self->{buffer} = [];
}

1;
