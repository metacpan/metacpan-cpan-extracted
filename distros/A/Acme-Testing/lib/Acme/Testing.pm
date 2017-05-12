package Acme::Testing;

use strict;
use warnings;
use Test::More;
use Class::Monkey;

our $VERSION = '0.002';

$Acme::Testing::excuses = [
    'Finalizing test...',
    'Rejigging the thrompletotes in the cardequanter...',
    'Test halted temporarily due to BBIAB...',
    'Test gone AFK momentarily...',
    'Running CHKDSK... Please wait.'
];

sub import {
    my $class  = shift;
    my $caller = caller;
    canpatch 'Test::More';
    distribute($caller)
        unless $caller->can('ok');
}

sub distribute {
    my $caller  = shift;
    my $base    = $Test::Reuse::base;
    my $excuses = $Acme::Testing::excuses;
    localscope: {
        no strict 'refs';
        no warnings;
        for my $method (keys %{"Test::More::"}) {
            unless( substr($method, 0, 1) eq '_' or $method eq uc $method or substr($method, 0, 1) eq uc(substr($method, 0, 1)) or $method eq 'builder')  {
                after $method => sub {
                    print $excuses->[rand(@$excuses)] . "\n";
                    sleep 15;
                },
                qw<Test::More>;
                *{"${caller}::${method}"} = *{"Test::More::${method}"};
            }
        }
    }
} 

=head1 NAME

Acme::Testing - Leave me alone, it's testing!

=head1 DESCRIPTION

A silly module that extends each test by 15 seconds, so you've got more time to do the things YOU want to do. By just running 2 tests you've already regained 30 seconds of your life. Fantastic!
It works the same as Test::More, except you only need to C<use Acme::Testing>. The module will export all the Test::More test functions to your script for you.

=head1 SYNOPSIS

    use Acme::Testing;

    ok 1, 'This could take a while..';
    is 2+2, 4, 'Just going for a bite to eat.. back soon';

    done_testing();

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
