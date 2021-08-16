#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use CPANPLUS::Dist::Debora::Pod;

use open ':std', ':encoding(utf8)';
use Test::More tests => 5;

my $pod = CPANPLUS::Dist::Debora::Pod->find('CPANPLUS::Dist::Debora', 'lib');

isa_ok $pod, 'CPANPLUS::Dist::Debora::Pod';

isnt $pod->summary,      q{},     'summary is not empty';
isnt $pod->description,  q{},     'description is not empty';
isa_ok $pod->copyrights, 'ARRAY', 'copyrights';

my $copyrights_text = <<'END_TEXT';
Copyright (c) 2002-2013 by Jane Roe <jane@example.com> and John Doe <john@example.com>. Some rights reserved.
Copyright 2014, 2017, John Q. Public (JPUBLIC), https://www.example.com/. This is free software.
END_TEXT

my $copyrights_expected = [
    {year => '2002-2013',  holder => 'Jane Roe and John Doe'},
    {year => '2014, 2017', holder => 'John Q. Public'},
];

my $copyrights = $pod->_copyrights_from_text($copyrights_text);
is_deeply $copyrights, $copyrights_expected, 'can parse copyright notices';
