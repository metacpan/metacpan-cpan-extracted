package Apache2::Profiler;

use strict;

use mod_perl2 1.999022;
use Apache2::Log;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use APR::Pool;
use Time::HiRes qw(gettimeofday);

our $VERSION = '0.10';

sub handler {
    my $r = shift;

    my $start_time = gettimeofday();

    $r->pool->cleanup_register(\&compute, [$r, $start_time]);
}

sub compute {
    my ($r, $start_time) = (@_ && ref $_[0] eq 'ARRAY' ? @{ +shift } : @_);

    return unless defined $start_time;

    my $now  = gettimeofday();
    my $diff = $now - $start_time;

    my $threshold = $r->dir_config('ProfileLongerThan') || 0;
    if ($diff >= $threshold) {
        my $uri   = $r->uri;

        # handle query string
        if (my $query = $r->args) {
            $uri .= "?$query";
        }

        $r->log->notice("uri: $uri takes $diff seconds");
    }
}

1;

__END__

=head1 NAME

Apache2::Profiler - profiles time seconds needed for every request

=head1 SYNOPSIS

  <Location /cgi-bin>
  PerlInitHandler Apache2::Profiler
  </Location>

=head1 DESCRIPTION

Apache2::Profiler is a mod_perl init (and cleanup) handler to profile time
taken to process one request. Profiled data is reported to the
Apache Log file. It'd be useful to profile some heavy application taking a long
time to proceed.

Apache2::Profiler is for C<mod_perl> version 2.0 or later.  If you are using
C<mod_perl> version 1.x, you need Apache::Profiler instead.

It uses L<Time::HiRes> to take milliseconds, and outputs profiled data
as Apache log C<notice> level like:

  [Tue Oct  7 20:52:53 2003] [notice] [client 127.0.0.1] uri: /test.html takes 0.0648910999298096 seconds

=head1 CONFIGURATION

=over 4

=item ProfileLongerThan

  PerlSetVar ProfileLongerThan 0.5

specifies lower limit of request time taken to profile. This example only logs
requests which takes longer than 0.5 seconds. This value is set to 0 by
default, which means it logs all requests.

=back

=head1 TODO

=over 4

=item *

customizable log format (exportable to some profiling tools)

=item *

profiles CPU time rather than C<gettimeofday>

=back

patches are always welcome!

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/apache-profiler

 git clone git://github.com/mschout/apache-profiler.git

=head1 BUGS

Please report any bugs or feature requests to
bug-apache-profiler@rt.cpan.org, or through the web
interface at http://rt.cpan.org/

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

Initial implementation by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Schout.

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=head1 SEE ALSO

L<Apache::Profiler>, L<Time::HiRes>

=cut
