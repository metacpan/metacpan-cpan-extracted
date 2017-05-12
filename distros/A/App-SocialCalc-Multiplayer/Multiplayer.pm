package App::SocialCalc::Multiplayer;
use 5.008001;
our $VERSION = 20110626;

1;

__END__

=encoding utf8

=head1 NAME

App::SocialCalc::Multiplayer - Multiplayer SocialCalc Server with WebSocket

=head1 SYNOPSIS

Run this in a host computer:

    % socialcalc-multiplayer.pl
    Accepting requests at http://0.0.0.0:9999/

Then connect to port 9999 with two or more browsers, and start collaboratively
edit a web-based spreadsheet.

=head1 DESCRIPTION

This is a convenient bundle around a prototypical WebSocket-SocialCalc
integration hack, based on the demonstration in a YAPC::Tiny talk for Chupei.pm
during late October 2009.

Please see L<https://github.com/audreyt/socialcalc/wiki> for more information.

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

This work is derived from the SocialCalc program:

    Copyright (C) 2009-2011 Socialtext, Inc.
    All Rights Reserved.

The upstream source tree was derived from:

    http://github.com/DanBricklin/socialcalc

Other than the CPAL license asserted by copyright holders above (see 
F<socialcalc/LEGAL.txt> and F<socialcalc/LICENSE.txt>), 唐鳳 places no
additional copyright claims over the collaborative editing extensions,
as detailed in the paragraph below.

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<App::SocialCalc::Multiplayer>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
