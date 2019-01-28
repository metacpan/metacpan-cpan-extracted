#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw/:all :hireswallclock/;

{
    package CDI;
    use parent 'Class::Data::Inheritable';
    __PACKAGE__->mk_classdata('hoge', 'bbb');
}

{
    package CDL;
    use Class::Data::Lite (
        ro => {
            hoge => 'bbb',
        },
    );
}

cmpthese 0 => {
    'Class::Data::Inheritable' => sub {
        my $i = CDI->hoge;
    },
    'Class::Data::Lite' => sub {
        my $i = CDL->hoge;
    },
};

__END__
                              Rate Class::Data::Inheritable    Class::Data::Lite
Class::Data::Inheritable 2711452/s                       --                 -41%
Class::Data::Lite        4561454/s                      68%                   --
