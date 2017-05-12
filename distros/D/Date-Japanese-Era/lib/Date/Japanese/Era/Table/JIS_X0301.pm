package Date::Japanese::Era::Table::JIS_X0301;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use vars qw(@ISA @EXPORT %ERA_TABLE %ERA_JA2ASCII %ERA_ASCII2JA);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(%ERA_TABLE %ERA_JA2ASCII %ERA_ASCII2JA);

%ERA_TABLE = (
    # era => [ $ascii, @begin_ymd, @end_ymd ]
    "\x{660E}\x{6CBB}" => [ 'meiji', 1868, 9, 8, 1912, 7, 30 ],
    "\x{5927}\x{6B63}" => [ 'taishou', 1912, 7, 31, 1926, 12, 25 ],
    "\x{662D}\x{548C}" => [ 'shouwa', 1926, 12, 26, 1989, 1, 7 ],
    "\x{5E73}\x{6210}" => [ 'heisei', 1989, 1, 8, 2999, 12, 31 ], # XXX
);

%ERA_JA2ASCII = map { $_ => $ERA_TABLE{$_}->[0] } keys %ERA_TABLE;
%ERA_ASCII2JA = reverse %ERA_JA2ASCII;

1;
__END__

=head1 NAME

Date::Japanese::Era::Table::JIS_X0301 - yet another conversion Table for Date::Japanese::Era

=head1 SYNOPSIS

  use Date::Japanese::Era 'JIS_X0301';

=head1 DESCRIPTION

This module defines conversion table used by Date::Japanese::Era.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Date::Japanese::Era>

=cut
