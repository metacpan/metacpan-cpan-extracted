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
        rw => {
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
Class::Data::Inheritable 2619253/s                       --                 -38%
Class::Data::Lite        4191169/s                      60%                   --
