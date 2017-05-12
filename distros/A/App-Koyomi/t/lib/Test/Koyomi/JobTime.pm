package Test::Koyomi::JobTime;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite;
use Smart::Args;

use App::Koyomi::Job;

use version; our $VERSION = 'v0.1.0';

Class::Accessor::Lite->mk_ro_accessors(@App::Koyomi::Job::TIME_FIELDS);

sub mock {
    args_pos(
        my $class,
        my $year    => 'Str',
        my $month   => 'Str',
        my $day     => 'Str',
        my $hour    => 'Str',
        my $minute  => 'Str',
        my $weekday => 'Str',
    );
    return bless +{
        year    => $year,
        month   => $month,
        day     => $day,
        hour    => $hour,
        minute  => $minute,
        weekday => $weekday,
    }, $class;
}

1;

__END__

=encoding utf8

=head1 NAME

B<Test::Koyomi::JobTime> - koyomi job test module

=head1 SYNOPSIS

    use Test::Koyomi::JobTime;

=head1 DESCRIPTION

This module is for test about job.

=head1 METHODS

=over 4

=item B<mock>

Create mock job time object.

=back

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

