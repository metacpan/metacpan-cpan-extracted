package Apache::DebugLog;

use warnings FATAL => 'all';
use strict;

use Apache::ModuleConfig        ();
use Apache::DebugLog::Config    ();
use Apache::LogF                ();
use XSLoader                    ();
use Carp                        ();

our $VERSION    = '0.02';

XSLoader::load(__PACKAGE__, $VERSION) if ($ENV{MOD_PERL});

=head1 NAME

Apache::DebugLog - Multidimensional debug logging in mod_perl 1.x

=head1 SYNOPSIS

    use Apache              ();
    use Apache::DebugLog    ();
    use Apache::Constants   qw(OK);
    
    sub handler {
        my $r = shift;

        # ...

        $r->log_debug('foo', 3, 'Some level three debug relating to "foo"');

        # ...

        $r->log_debugf('bar', 9, 'Esoteric debug concerning %s', $x);

        # ...

        return OK;
    }

=head1 FUNCTIONS

=head2 log_debug DOMAIN, LEVEL, MESSAGE

Adds $r->log_debug to the mod_perl request object. The first argument
is the domain or category to log, the second is the verbosity level.
The last is a list of strings to pass into error log.

=cut

sub Apache::log_debug {
    my ($r, $domain, $level, @msg)  = @_;
    my $conf = Apache::ModuleConfig->get($r);
    $r->log->debug("[$domain:$level] ", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

sub Apache::Server::log_debug {
    my ($s, $domain, $level, @msg)  = @_;
    my $conf = Apache::ModuleConfig->get($s);
    $s->log->debug("[$domain:$level] ", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

=head2 log_debugf DOMAIN, LEVEL, FORMAT, ARGS

Adds log_debugf to the mod_perl request object. Same as above, but
the last arguments are passed the same as one would to sprintf.

=cut

sub Apache::log_debugf {
    my ($r, $domain, $level, $fmt, @msg)  = @_;
    my $conf = Apache::ModuleConfig->get($r);
    $r->log->debugf("[$domain:$level] $fmt", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

sub Apache::Server::log_debugf {
    my ($s, $domain, $level, $fmt, @msg)  = @_;
    my $conf = Apache::ModuleConfig->get($s);
    $s->log->debugf("[$domain:$level] $fmt", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

=head1 SEE ALSO

L<Apache::DebugLog::Config>

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-debuglog@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-DebugLog>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 dorian taylor, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache::DebugLog
