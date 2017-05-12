package Apache::LogF;

use warnings FATAL => 'all';
use strict;

use Carp            ();
use Apache::Log     ();

=head1 NAME

Apache::LogF - Format Apache log messages like sprintf

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Apache           ();
    use Apache::LogF     ();

    use Apache::Constants qw(OK);

    sub handler {
        my $r   = shift;
        my $log = $r->log;
        # ...

        $log->debugf('%d is a curious value', $curious_value);

        $log->infof('%s is really fantastic.', $interesting_stuff);

        $log->noticef('current user is %s', $r->user);
        
        $log->warnf('%s happened %d times', $thing, $times);

        $log->errorf('bzzzt. you already did this %d times.', $times);

        $log->critf('ah crap now you went and did %s.', $bad_thing);

        $log->alertf('uhoh the process is taking %0.2f megs of ram.', $megs);

        $log->emergf('okay now we are on fire over %s.', $where);
        
        # ...
        return OK;
    }

=head1 METHODS

take your favourite Apache::Log convenience method (emerg, alert,
crit, error, warn, notice, info, debug) and add an 'f' to the end.
now treat it like sprintf. fan-tastic.

=cut

# mwa ha ha.
for my $meth (qw(emerg alert crit error warn notice info debug)) {
    no strict 'refs';
    *{"Apache::Log::${meth}f"} = sub {
        Carp::croak("${meth}f: \$fmt, \$arg [, ...]") unless @_ >= 3;
        &{"Apache::Log::$meth"}($_[0], sprintf($_[1], @_[2..$#_]));
    };
}

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-logf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-LogF>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 dorian taylor, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Apache::LogF
