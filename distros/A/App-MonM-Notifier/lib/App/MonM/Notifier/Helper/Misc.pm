package App::MonM::Notifier::Helper::Misc; # $Id: Misc.pm 44 2017-12-01 19:41:48Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Helper::Misc - Internal helper's methods used by App::MonM::Notifier::Helper module

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

none

=head1 DESCRIPTION

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<App::MonM::Notifier::Helper>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut


use CTK::Util qw/ :BASE /;
use constant SIGNATURE => "misc";

use vars qw($VERSION);
$VERSION = '1.00';

sub build {
    my $self = shift;

    my $rplc = $self->{rplc};

    $self->maybe::next::method();
    return 1;
}
sub dirs {
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        #{
        #    path => '%BAZ%',
        #    mode => 0755,
        #},
        #{
        #    path => 'www',
        #    mode => 0755,
        #},
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool {
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;
__DATA__

-----BEGIN FILE-----
Name: %PROJECT%
File: etc/default/%PROJECT%
Mode: 644
Type: Unix

#
# This file must only contain KEY=VALUE lines. Do not use advanced
# shell script constructs!
#

## ScriptName (client program name)
SCRIPTNAME=%PROJECT%
DAEMONNAME=%PROJECT%d
-----END FILE-----

-----BEGIN FILE-----
Name: %PROJECT%
File: etc/logrotate.d/%PROJECT%
Mode: 644
Type: Unix

/var/log/%PROJECT%.*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
}
/var/log/%PROJECT%.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
}
/var/log/%PROJECT%d.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
}
/var/log/%PROJECT%_*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
}
-----END FILE-----

-----BEGIN FILE-----
Name: testscript.pl
File: %SITE_BIN%/testscript.pl
Mode: 711
Type: Unix

#!/usr/bin/perl -w
use strict;
use utf8;
use Encode;
use Encode::Locale;

my @in;
while(<>) {
  chomp;
  push @in, decode(locale => $_);
}

# . . . YOUR CODE STARTS FROM HERE ...

print encode(locale => join("\n", @in));
-----END FILE-----
