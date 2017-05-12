use strict;
use warnings;
use utf8;

use Acme::MadokaMagica;
use Test::More;


subtest 'Soulgem' => sub{
    my ($mami) = Acme::MadokaMagica->alone_members;
    is ref $mami,'Acme::MadokaMagica::TvMembers::TomoeMami';
    is $mami->color,'yellow';

































































































    is $mami->color,undef;


};

done_testing;
