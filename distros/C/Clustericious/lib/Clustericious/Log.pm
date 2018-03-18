package Clustericious::Log;

use strict;
use warnings;
use List::Util qw( first );
use Log::Log4perl qw( :easy );
use MojoX::Log::Log4perl;
use File::ReadBackwards;
use Clustericious;

# ABSTRACT: A Log::Log4perl wrapper for use with Clustericious.
our $VERSION = '1.29'; # VERSION


sub import {
    my $class = shift;
    my $dest = caller;
    my %args = @_;
    if (my $app_name = $args{-init_logging}) {
        init_logging($app_name);
    }
    @_ = ($class, ':easy');
    goto \&Log::Log4perl::import;
}


our $initPid;
sub init_logging {
    my $app_name = shift;
    $app_name = shift if $app_name eq __PACKAGE__;
    $app_name = $ENV{MOJO_APP} unless $app_name && $app_name ne 'Clustericious::App';

    # Force reinitialization after a fork
    $Log::Log4perl::Logger::INITIALIZED = 0 if $initPid && $initPid != $$;
    $initPid = $$;

    # Logging
    $ENV{LOG_LEVEL} ||= 'WARN';

    my $l4p_dir; # dir with log config file.
    my $l4p_pat; # pattern for screen logging
    my $l4p_file; # file (global or app specific)

    $l4p_dir  = first { -d $_ && (-e "$_/log4perl.conf" || -e "$_/$app_name.log4perl.conf") } Clustericious->_config_path;
    $l4p_pat  = "[%d] [%Z %H %P] %5p: %m%n";
    if ($l4p_dir) {
        $l4p_file = first {-e "$l4p_dir/$_"} ("$app_name.log4perl.conf", "log4perl.conf");
    }

    Log::Log4perl::Layout::PatternLayout::add_global_cspec('Z', sub {$app_name});

    my $logger = MojoX::Log::Log4perl->new( $l4p_dir ? "$l4p_dir/$l4p_file":
      { # default config
       ($ENV{LOG_FILE} ? (
          "log4perl.rootLogger"              => "$ENV{LOG_LEVEL}, File1",
          "log4perl.appender.File1"          => "Log::Log4perl::Appender::File",
          "log4perl.appender.File1.layout"   => "PatternLayout",
          "log4perl.appender.File1.filename" => "$ENV{LOG_FILE}",
          "log4perl.appender.File1.layout.ConversionPattern" => "[%d] [%Z %H %P] %5p: %m%n",
        ):(
          "log4perl.rootLogger"               => "$ENV{LOG_LEVEL}, SCREEN",
          "log4perl.appender.SCREEN"          => "Log::Log4perl::Appender::Screen",
          "log4perl.appender.SCREEN.layout"   => "PatternLayout",
          "log4perl.appender.SCREEN.layout.ConversionPattern" => "$l4p_pat",
       )),
      # These categories (%c) are too verbose by default :
       "log4perl.logger.Mojolicious"                     => "WARN",
       "log4perl.logger.Mojolicious.Plugin.RequestTimer" => "WARN",
       "log4perl.logger.MojoX.Dispatcher.Routes"         => "WARN",
    });

    INFO("Initialized logger");
    INFO("Log config found : $l4p_dir/$l4p_file") if $l4p_dir;
    # warn "# started logging ($l4p_dir/log4perl.conf)\n" if $l4p_dir;
    return $logger;
}


sub tail {
    my $self = shift;
    my %args = @_;
    my $count = $args{lines} || 10;
    my %appenders = %{ Log::Log4perl->appenders };
    my ($first) = sort keys %appenders;
    my $obj = $appenders{$first}->{appender};
    $obj->can("filename") or return "no filename for appender $first";
    my $filename = $obj->filename;
    my $fp = File::ReadBackwards->new($filename) or return "Can't read $filename : $!";
    my @lines;
    my $line;
    while ( defined( $line = $fp->readline ) ) {
        unshift @lines, $line;
        last if ( (0 + @lines) >= $count);
    };
    return join '', @lines;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Log - A Log::Log4perl wrapper for use with Clustericious.

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 use Clustericious::Log -init_logging => "appname";
 
 use Clustericious::Log;
 INFO "Hi there!";

=head1 DESCRIPTION

This is a simple wrapper around L<Log::Log4perl> for use with
Clustericious.  It handles initialization and exporting of
convenient logging functions, and a default set of logging
patterns.  It also makes the name of the application available
for logging patterns (see the example).

=head1 EXAMPLE

Here is a sample C<~/etc/log4perl.conf> :

 log4perl.rootLogger=TRACE, LOGFILE
 log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
 log4perl.appender.LOGFILE.filename=/tmp/some.log
 log4perl.appender.LOGFILE.mode=append
 log4perl.appender.LOGFILE.layout=PatternLayout
 log4perl.appender.LOGFILE.layout.ConversionPattern=[%d{HH:mm:ss}] [%8.8Z] %C (%F{1}+%L) %5p: %m%n
 # Note 'Z' is the name of the Clustericious application.

=head1 METHODS

=over

=item init_logging

Start logging.  Looks for C<log4perl.conf> or C<$app.log4perl.conf>
in C<~/etc> and C</etc>.

=item tail

Returns a string with the last $n lines of the logfile.

If multiple log files are defined, it only uses the first one alphabetically.

=back

=head1 ENVIRONMENT

The following variables affect logging :

 LOG_LEVEL
 LOG_FILE
 MOJO_APP

=head1 SEE ALSO

L<Log::Log4perl>, L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
