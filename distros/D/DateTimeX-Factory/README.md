# NAME

DateTimeX::Factory - DateTime factory module with default options.

# VERSION

This document describes DateTimeX::Factory version 1.00.

# SYNOPSIS

    use DateTimeX::Factory;

    my $factory = DateTimeX::Factory->new(
        time_zone => 'Asia/Tokyo',
    );
    my $now = $factory->now;

# DESCRIPTION

DateTime factory module with default options.
This module include wrapper of default constructors and some useful methods.

# METHODS

## `new(%params)`

Create factory instance. all parameters thrown to factory methods

    my $factory = DateTimeX::Factory->new(time_zone => 'Asia/Tokyo');

## `create(%params)`

Call DateTime->new with default parameter.

    my $datetime = $factory->create(year => 2012, month => 1, day => 24, hour => 23, minute => 16, second => 5);

## `now(%params)`, `today(%params)`, `from_epoch(%params)`, `last_day_of_month(%params)`, `from_day_of_year(%params)`

See document of [DateTime](http://search.cpan.org/perldoc?DateTime).
But, these methods create DateTime instance by original method with default parameter.

## `strptime($string, $pattern)`

Parse string by DateTime::Format::Strptime with default parameter.

    my $datetime = $factory->strptime('2012-01-24 23:16:05', '%Y-%m-%d %H:%M:%S');

## `from_mysql_datetime($string)`

Parse MySQL DATETIME string with default parameter.

    #equals my $datetime = $factory->strptime('2012-01-24 23:16:05', '%Y-%m-%d %H:%M:%S');
    my $datetime = $factory->from_mysql_datetime('2012-01-24 23:16:05');

## `from_mysql_date($string)`

Parse MySQL DATE string with default parameter.

    #equals my $date = $factory->strptime('2012-01-24', '%Y-%m-%d');
    my $date = $factory->from_mysql_date('2012-01-24');

## `from_ymd($string, $delimiter)`

Parse string like DateTime::ymd return value with default parameter.

    #equals my $date = $factory->strptime('2012/01/24', '%Y/%m/%d');
    my $date = $factory->from_ymd('2012-01-24', '/');

## `tommorow(%params)`

Create next day DateTime instance.

    #equals my $tommorow = $factory->today->add(days => 1);
    my $tommorow = $factory->tommorow;

## `yesterday(%params)`

Create previous day DateTime instance.

    #equals my $yesterday = $factory->today->subtract(days => 1);
    my $yesterday = $factory->yesterday;

# DEPENDENCIES

Perl 5.10.1 or later.
[Class::Accessor::Lite](http://search.cpan.org/perldoc?Class::Accessor::Lite)
[DateTime](http://search.cpan.org/perldoc?DateTime)
[DateTime::Format::Strptime](http://search.cpan.org/perldoc?DateTime::Format::Strptime)

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](http://search.cpan.org/perldoc?perl)

# AUTHOR

Nishibayashi Takuji <takuji31@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Nishibayashi Takuji. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
