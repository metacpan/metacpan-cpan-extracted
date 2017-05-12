package Dancer::Logger::Syslog;
BEGIN {
  $Dancer::Logger::Syslog::AUTHORITY = 'cpan:SUKRIA';
}
# ABSTRACT: Dancer logger engine for Sys::Syslog
$Dancer::Logger::Syslog::VERSION = '0.6';
use strict;
use warnings;

use base 'Dancer::Logger::Abstract';
use File::Basename 'basename';
use Sys::Syslog qw(:DEFAULT setlogsock);

use Dancer::Config 'setting';

sub init {
    my ($self) = @_;
    setlogsock('unix');

    my $conf = setting('syslog');

    $self->{facility} = $conf->{facility} || 'USER';
    $self->{ident}    = $conf->{ident}    
                            || setting('appname') 
                            || $ENV{DANCER_APPDIR} 
                            || basename($0);
    $self->{logopt}   = $conf->{logopt}   || 'pid';
}

sub DESTROY { closelog() }

sub _log {
    my ($self, $level, $message) = @_;

    if (!$self->{log_opened}) {
        openlog($self->{ident}, $self->{logopt}, $self->{facility});
        $self->{log_opened} = 1;
    }

    my $syslog_levels = {
        core    => 'debug',
        debug   => 'debug',
        warning => 'warning',
        error   => 'err',
        info    => 'info',
    };

    $level = $syslog_levels->{$level} || 'debug';
    my $fm = $self->format_message($level => $message);
    return syslog($level, $fm);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Logger::Syslog - Dancer logger engine for Sys::Syslog

=head1 VERSION

version 0.6

=head1 DESCRIPTION

This module implements a logger engine that send log messages to syslog,
through the Sys::Syslog module.

=head1 CONFIGURATION

The setting B<logger> should be set to C<syslog> in order to use this session
engine in a Dancer application.

You can also specify the other configuration via the 'syslog' config key, e.g.

 syslog:
   facility: 'local0'
   ident: 'my_app'

The allowed options are:

=over 4

=item facility 

Which syslog facility to use, defaults to 'USER'

=item ident 

String prepended to every log line, defaults to the configured I<appname> or,
if not defined, to the executable's basename.

=item logopt

Log options passed top C<openlog()> as per Sys::Syslog's docs. Defaults to
'pid'. 

=back

=head1 METHODS

=head2 init()

The init method is called by Dancer when creating the logger engine
with this class.

=head2 format_message()

This method defines how to format messages for Syslog, it's a bit different 
than the standard one provided by L<Dancer::Logger::Abstract> because Syslog
already provides a couple of information.

=head1 DEPENDENCY

This module depends on L<Sys::Syslog>.

=head1 SEE ALSO

See L<Dancer> for details about logging in route handlers.

=head1 AUTHORS

=over 4

=item *

Alexis Sukrieh <sukria@sukria.net>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
