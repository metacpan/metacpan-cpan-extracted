package Apache2::DebugLog;

use warnings FATAL => 'all';
use strict;

# cargo cult, do i even need to load RequestRec?
use Apache2::RequestRec ();
use Apache2::ServerRec  ();
use Apache2::Module     ();
use Apache2::LogF       ();

# import must be called so we use this normally
use Apache::DebugLog::Config;

our $VERSION    = '0.02';

=head1 NAME

Apache2::DebugLog - Multidimensional debug logging in mod_perl 2.x

=head1 SYNOPSIS

    use Apache2::RequestRec ();
    use Apache2::DebugLog   ();
    use Apache2::Const  -compile => qw(OK);
    
    sub handler {
        my $r = shift;

        # ...

        $r->log_debug('foo', 3, 'Some level three debug relating to "foo"');

        # ...

        $r->log_debugf('bar', 9, 'Esoteric debug concerning %s', $x);

        # ...

        return Apache2::Const::OK;
    }

=head1 FUNCTIONS

=head2 log_debug DOMAIN, LEVEL, MESSAGE

Adds $r->log_debug to the mod_perl request object. The first argument
is the domain or category to log, the second is the verbosity level.
The last is a list of strings to pass into error log.

=cut

sub Apache2::RequestRec::log_debug {
    my ($r, $domain, $level, @msg)  = @_;
    my $conf = Apache2::Module::get_config
                (__PACKAGE__, $r->server, $r->per_dir_config);
    $r->log->debug("[$domain:$level] ", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}


sub Apache2::ServerRec::log_debug {
    my ($s, $domain, $level, @msg)  = @_;
    my $conf = Apache2::Module::get_config(__PACKAGE__, $s);
    $s->log->debug("[$domain:$level] ", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

=head2 log_debugf DOMAIN, LEVEL, FORMAT, ARGS

Adds $r->log_debugf to the mod_perl request object. Same as above, but
the last arguments are passed the same as one would to sprintf.

=cut

sub Apache2::RequestRec::log_debugf {
    my ($r, $domain, $level, $fmt, @msg)  = @_;
    my $conf = Apache2::Module::get_config
                (__PACKAGE__, $r->server, $r->per_dir_config);
    $r->log->debugf("[$domain:$level] $fmt", @msg) if ($level >= $conf->{level} 
        and ($conf->{domain}{'*'} or $conf->{domain}{$domain}));
}

sub Apache2::ServerRec::log_debugf {
    my ($s, $domain, $level, $fmt, @msg)  = @_;
    my $conf = Apache2::Module::get_config(__PACKAGE__, $s);
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

1; # End of Apache2::DebugLog
