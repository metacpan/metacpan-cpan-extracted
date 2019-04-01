package Date::Japanese::Era::Table::JIS_X0301;

use utf8;
use strict;
our $VERSION = '0.01';

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(%ERA_TABLE %ERA_JA2ASCII %ERA_ASCII2JA);

our %ERA_TABLE = (
    # era => [ $ascii, @begin_ymd, @end_ymd ]
    "明治" => [ 'meiji', 1868, 9, 8, 1912, 7, 30 ],
    "大正" => [ 'taishou', 1912, 7, 31, 1926, 12, 25 ],
    "昭和" => [ 'shouwa', 1926, 12, 26, 1989, 1, 7 ],
    "平成" => [ 'heisei', 1989, 1, 8, 2019, 4, 30 ],
    "令和" => [ 'reiwa', 2019, 5, 1, 2999, 12, 31 ], # XXX
);

our %ERA_JA2ASCII = map { $_ => $ERA_TABLE{$_}->[0] } keys %ERA_TABLE;
our %ERA_ASCII2JA = reverse %ERA_JA2ASCII;

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
