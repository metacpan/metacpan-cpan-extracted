#!/usr/bin/perl
use inc::Module::Install;
use 5.008;
name        ('Business-TW-TSIB-CStorePayment');
author      ('Chia-liang Kao <clkao@aiink.com>');
license     ('perl');
all_from    ('lib/Business/TW/TSIB/CStorePayment.pm');


requires    ('Test::More');
requires    ('Class::Accessor::Fast');
requires    ('List::MoreUtils');
requires    ('DateTime');

auto_install;
WriteAll;
