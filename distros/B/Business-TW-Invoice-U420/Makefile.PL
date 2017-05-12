#!/usr/bin/perl
use inc::Module::Install;
use 5.008;
name        ('Business-TW-Invoice-U420');
author      ('Chia-liang Kao <clkao@aiink.com>');
license     ('perl');
all_from    ('lib/Business/TW/Invoice/U420.pm');


requires    ('Test::More');
requires    ('Class::Accessor::Fast');

auto_install;
WriteAll;

