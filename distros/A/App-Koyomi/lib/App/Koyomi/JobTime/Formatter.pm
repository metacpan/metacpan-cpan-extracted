package App::Koyomi::JobTime::Formatter;

use strict;
use warnings;
use 5.010_001;
use Carp qw(croak);

use parent qw(Exporter);
our @EXPORT_OK = qw(time2str str2time);

use version; our $VERSION = 'v0.6.0';

sub time2str {
    my $self = shift;
    sprintf(q{%s/%s/%s %s:%s (%s)}, map { $self->$_ } qw/year month day hour minute weekday/);
}

sub str2time {
    my $string = shift;

    if ($string =~ m{^([\*\d]+)/([\*\d]+)/([\*\d]+) ([\*\d]+):([\*\d]+) \(([\*\d])\)$}) {
        return +{
            year => $1, month  => $2, day     => $3,
            hour => $4, minute => $5, weekday => $6,
        };
    } else {
        croak "Can't decode string!! string = $string";
    }
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::JobTime::Formatter> - Mixin to enhance job_times data object

=head1 SYNOPSIS

    use App::Koyomi::JobTime::Formatter qw(time2str str2time);
    my $string = $self->time2str;
    my $time   = str2time($string);

=head1 DESCRIPTION

Mixin to enhance job_times data object.
And utility for job_times date format.

=head1 MIXIN METHODS

=over 4

=item B<time2str>

Convert object's datetime into short string.

Ex) '2010/10/20 11:10 (*)', '*/*/* *:5 (*)'

=back

=head1 SUBROUTINES

=over 4

=item B<str2time>

Convert datetime string whose format is described above into I<Hash Reference>.

=back

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

