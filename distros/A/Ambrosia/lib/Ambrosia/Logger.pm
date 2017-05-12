package Ambrosia::Logger;
use strict;
use warnings;

use File::Path;
use IO::File;
use Data::Dumper;
use Time::HiRes qw ( time );
use Scalar::Util "blessed";

use Ambrosia::error::Exceptions;

use base qw/Exporter/;
our @EXPORT = qw/logger/;

our $VERSION = 0.010;

our %PROCESS_MAP = ();
our %LOGGERS = ();

sub import
{
    my $pkg = shift;
    my %prm = @_;
    assign($prm{assign}) if $prm{assign};

    Ambrosia::Logger->export_to_level(1, @EXPORT);
}

sub assign
{
    $PROCESS_MAP{$$} = shift;
}

sub instance
{
    my $pkg = shift;
    my $key = shift;
    my %params = @_;

    my ($mday, $mon, $year) = (localtime)[3..5];
    return $LOGGERS{$key}->{object} if defined $LOGGERS{$key} && defined $LOGGERS{$key}->{date}->{$year . ' ' . $mon . ' ' . $mday};

    my $self;
    if ( $self = $LOGGERS{$key}->{object} )
    {
        close($key);
    }
    else
    {
        $self = {
            _log => undef,
            _prefix => ( $params{-prefix} || '' ),
            _op => ( $params{-op} || '' ),
            _dir => $params{-dir},
            _time => {},
        };
        $pkg .= $key;
        bless $self, $pkg;

        no strict 'refs';
        no warnings 'redefine';

        push @{"${pkg}::ISA"}, __PACKAGE__;

        if ( $params{INFO} )
        {
            *{"${pkg}::log_info"} = sub { goto &__info; };
        }
        else
        {
            *{"${pkg}::log_info"} = sub { };
        }

        if ( $params{INFO_EX} )
        {
            *{"${pkg}::log_info_ex"} = sub { goto &__info_ex; };
        }
        else
        {
            *{"${pkg}::log_info_ex"} = sub { goto *{"${pkg}::log_info"}; };
        }

        if ( $params{DEBUG} )
        {
            *{"${pkg}::log_debug"} = sub { goto &__debug; };
        }
        else
        {
            *{"${pkg}::log_debug"} = sub { goto *{"${pkg}::log_info_ex"}; };
        }

        if ( $params{TIME} )
        {
            *{"${pkg}::log_time"} = sub { goto &__log_time; };
        }
        else
        {
            *{"${pkg}::log_time"} = sub {};
        }

        $LOGGERS{$key}->{object} = $self;
    }

    if ( $self->{_dir} )
    {
        mkpath($self->{_dir}, 0, oct(777)) unless -d $self->{_dir};
        # Name of logfile is YYYYMMDD.log, where YYYYMMDD - is current date.
        $self->{_logname} = sprintf("%s/%s%04d%02d%02d.log", $self->{_dir}, $self->{_prefix}, $year + 1900, $mon + 1, $mday);
        $self->{_log} = new IO::File;
        $self->{_log}->autoflush(1);
        unless ($self->{_log}->open(">>$self->{_logname}"))
        {
            throw Ambrosia::error::Exception::BadParams 'Cannot open logfile: ' . $self->{_logname} . "[ $! ]";
        }
    }
    else
    {
        $self->{_log} = \*STDERR;
    }

    $LOGGERS{$key}->{date}->{$year . ' ' . $mon . ' ' . $mday} = 1;

    return $self;
}

sub logger
{
    return __PACKAGE__->instance($PROCESS_MAP{$$} ||= 'default');
}

sub op
{
    $_[0]->{_op} = $_[1];
}

################################################################################
# Close log handlers
sub close
{
    my @keys = shift || keys %LOGGERS;

    foreach ( @keys )
    {
        my $obj = $LOGGERS{$_}->{object};
        $obj->{_log}->close if $obj->{_log} && $obj->{_dir};
    }
}

sub error
{
    __info_ex(shift, 'ERROR: ', map { ref $_ && blessed($_) && $_->isa('Ambrosia::error::Exception::Error') ? "$_" : $_ } @_);
}

sub log
{
    my ($self, @msg) = @_;
    my($sec, $min, $hour) = (localtime)[0..2];
    @msg = ('EMPTY') unless @msg;
    @msg = map { defined $_ ? $_ : 'undef' } @msg;
    __tolog($self, sprintf("%02d:%02d:%02d (op = %s) %s\n", $hour, $min, $sec, $self->{_op}, join (' ', @msg)));
}

sub __tolog
{
    my $log = $_[0]->{_log};
    print $log $_[1];
}

sub __log_time
{
    my $self = shift;
    my $msg = shift;
    my $key = shift;
    if ( $msg )
    {
        if ( $self->{_time}->{$key} )
        {
            $self->log( $msg, " -::- ^^^^^^^^^^^^^^^^^^^ $key |", sprintf("%.4f", time - $self->{_time}->{$key} ) );
            delete $self->{_time}->{$key};
            return;
        }
        else
        {
            $self->log( $msg, " -::- vvvvvvvvvvvvvvvvvvv $key" );
        }
    }
    $self->{_time}->{$key} = time if $key;
}


sub __debug
{
    my ($self, @msg) = @_;
    my $p = __PACKAGE__;
    my $x = 0;
    my ($package, $line, $subroutine);
    my @callers;
 
    while ( do { package DB; ($package, $line, $subroutine) = (caller($x++))[0, 2, 3] } )
    {
        my @arg = $subroutine !~ /^$p\:\:/ ? @DB::args : ('...');
        unshift @callers, "\t$subroutine"
            . ( $subroutine ne '(eval)' ? ('( '.(join ", ", @arg).' )'):'')
            . ' At ' . $package
            . ' line ' . $line;
    }
    push @msg, "\nstack frames = [\n", (join "\n", @callers), "\n]";
    $self->log_info_ex(@msg);
}

sub __info_ex
{
    local $Data::Dumper::Indent = 1;
    shift->log( map { ref $_ ? Dumper($_) : $_ } @_);
}

sub __info
{
    shift->log( map { ref $_ ? ref $_ : $_ } @_);
}

sub DESTROY
{}

1;

__END__

=head1 NAME

Ambrosia::Logger - a class for create global object for logging.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::Logger;
    BEGIN {
        instance Ambrosia::Logger('myApplication', DEBUG => 1, INFO_EX => 1, INFO => 1, -prefix => 'GoogleCoupon_', -dir => $logger_path);
        Ambrosia::Logger::assign 'myApplication';
    }

    logger->log('is just message', 'other message' );
    logger->log_info('is simple info', ... );
    logger->log_info_ex('is dump of structures info', {foo=>1}, [{bar=>1},{baz=>2}] );
    logger->error('message about errors');
    logger->debug('write with the message and the stack of calls');

=head1 DESCRIPTION

C<Ambrosia::Logger> is a class for create global object for logging.
Implement the pattern B<Singleton>.

=head2 instance

Instances the named object of type C<Ambrosia::Logger> in the pool.
This method not exported. Use as constructor: C<instance Ambrosia::Logger(.....)>

=head2 logger

Returns the global object of type C<Ambrosia::Logger>.
C<logger(name)> - the name is optional param. Call with name if you not assign current process to logger yet.

=head2 assign

Assigns current process to the global named object of type C<Ambrosia::Logger>.

=head1 DEPENDENCIES

L<File::Path>
L<IO::File>
L<Data::Dumper>
L<Time::HiRes>
L<Scalar::Util>
L<Exporter>
L<Ambrosia::error::Exceptions>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
