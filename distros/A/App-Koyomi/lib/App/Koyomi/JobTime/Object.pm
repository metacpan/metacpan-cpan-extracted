package App::Koyomi::JobTime::Object;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/year month day hour minute weekday/],
);

use App::Koyomi::JobTime::Formatter qw(time2str);

use version; our $VERSION = 'v0.6.0';

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::JobTime::Object> - JobTime object to use Formatter Mixin

=head1 SYNOPSIS

    use App::Koyomi::JobTime::Object;
    my $jt  = App::Koyomi::JobTime::Object->new;
    my $str = $jt->time2str;

=head1 DESCRIPTION

JobTime object to use Formatter Mixin.

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

