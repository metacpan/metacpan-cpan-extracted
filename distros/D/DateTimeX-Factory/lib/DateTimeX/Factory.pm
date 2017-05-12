package DateTimeX::Factory;
use 5.010_001;
use strict;
use warnings;

our $VERSION = '1.00';

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/default_options/],
);

use DateTime;
use DateTime::Format::Strptime;

sub new {
    my ($class, %default_options) = @_;
    bless {default_options => \%default_options}, $class;
}

sub create            {shift->_call_factory_method('new' => @_)}
sub now               {shift->_call_factory_method('now' => @_)}
sub from_epoch        {shift->_call_factory_method('from_epoch' => @_)}
sub today             {shift->_call_factory_method('today' => @_)}
sub last_day_of_month {shift->_call_factory_method('last_day_of_month' => @_)}
sub from_day_of_year  {shift->_call_factory_method('from_day_of_year' => @_)}

sub _call_factory_method {
    my ($self, $method, @params) = @_;
    DateTime->$method(%{$self->default_options}, @params);
}

sub strptime {
    my ($self, $string, $pattern) = @_;
    return DateTime::Format::Strptime->new(
        pattern => $pattern,
        %{$self->default_options},
    )->parse_datetime($string);
}

sub from_mysql_datetime {
    my ($self, $string) = @_;

    return if !defined $string ||  $string eq '0000-00-00 00:00:00';

    return $self->strptime($string, '%Y-%m-%d %H:%M:%S');
}

sub from_ymd {
    my ($self, $string, $delimiter) = @_;

    $delimiter //= '-';
    return $self->strptime($string, join($delimiter, '%Y','%m','%d'));
}

sub from_mysql_date {
    my ($self, $string) = @_;

    return if !defined $string ||  $string eq '0000-00-00';
    return $self->from_ymd($string);
}

sub yesterday {shift->today(@_)->subtract(days => 1)}
sub tommorow  {shift->today(@_)->add(days => 1)}

1;
__END__

=head1 NAME

DateTimeX::Factory - DateTime factory module with default options.

=head1 VERSION

This document describes DateTimeX::Factory version 1.00.

=head1 SYNOPSIS

    use DateTimeX::Factory;

    my $factory = DateTimeX::Factory->new(
        time_zone => 'Asia/Tokyo',
    );
    my $now = $factory->now;

=head1 DESCRIPTION

DateTime factory module with default options.
This module include wrapper of default constructors and some useful methods.

=head1 METHODS

=head2 C<< new(%params) >>

Create factory instance. all parameters thrown to factory methods

  my $factory = DateTimeX::Factory->new(time_zone => 'Asia/Tokyo');

=head2 C<< create(%params) >>

Call DateTime->new with default parameter.

  my $datetime = $factory->create(year => 2012, month => 1, day => 24, hour => 23, minute => 16, second => 5);

=head2 C<< now(%params) >>, C<< today(%params) >>, C<< from_epoch(%params) >>, C<< last_day_of_month(%params) >>, C<< from_day_of_year(%params) >>

See document of L<DateTime>.
But, these methods create DateTime instance by original method with default parameter.

=head2 C<< strptime($string, $pattern) >>

Parse string by DateTime::Format::Strptime with default parameter.

  my $datetime = $factory->strptime('2012-01-24 23:16:05', '%Y-%m-%d %H:%M:%S');

=head2 C<< from_mysql_datetime($string) >>

Parse MySQL DATETIME string with default parameter.

  #equals my $datetime = $factory->strptime('2012-01-24 23:16:05', '%Y-%m-%d %H:%M:%S');
  my $datetime = $factory->from_mysql_datetime('2012-01-24 23:16:05');

=head2 C<< from_mysql_date($string) >>

Parse MySQL DATE string with default parameter.

  #equals my $date = $factory->strptime('2012-01-24', '%Y-%m-%d');
  my $date = $factory->from_mysql_date('2012-01-24');

=head2 C<< from_ymd($string, $delimiter) >>

Parse string like DateTime::ymd return value with default parameter.

  #equals my $date = $factory->strptime('2012/01/24', '%Y/%m/%d');
  my $date = $factory->from_ymd('2012-01-24', '/');

=head2 C<< tommorow(%params) >>

Create next day DateTime instance.

  #equals my $tommorow = $factory->today->add(days => 1);
  my $tommorow = $factory->tommorow;

=head2 C<< yesterday(%params) >>

Create previous day DateTime instance.

  #equals my $yesterday = $factory->today->subtract(days => 1);
  my $yesterday = $factory->yesterday;

=head1 DEPENDENCIES

Perl 5.10.1 or later.
L<Class::Accessor::Lite>
L<DateTime>
L<DateTime::Format::Strptime>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Nishibayashi Takuji E<lt>takuji31@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Nishibayashi Takuji. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
