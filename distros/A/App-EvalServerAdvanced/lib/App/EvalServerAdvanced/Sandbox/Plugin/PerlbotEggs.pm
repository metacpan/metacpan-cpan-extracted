package App::EvalServerAdvanced::Sandbox::Plugin::PerlbotEggs;

use strict;
use warnings;
use Moo::Role;

# This started out as a bad babylon 5 joke, now it's a weird 
# meta class that captures all method calls and arguments
# Slightly used to 
do {
    package 
    Zathras; 
    our $AUTOLOAD; 
    use overload '""' => sub { ## no critic
        my $data = @{$_[0]{args}}? qq{$_[0]{data}(}.join(', ', map {"".$_} @{$_[0]{args}}).qq{)} : qq{$_[0]{data}};
        my $old = $_[0]{old};

        my ($pack, undef, undef, $meth) = caller(1);

        if ($pack eq 'Zathras' && $meth ne 'Zahtras::dd_freeze') {
            if (ref($old) ne 'Zathras') {
                return "Zathras->$data";
            } else {
                return "${old}->$data";
            }
        } else {
           $old = "" if (!ref($old));
           return "$old->$data"
        }
      };
    sub AUTOLOAD {$AUTOLOAD=~s/.*:://; bless {data=>$AUTOLOAD, args => \@_, old => shift}}
    sub DESTROY {}; # keep it from recursing on destruction
    sub dd_freeze {$_[0]=\($_[0]."")}
    sub can {my ($self, $meth) = @_; return sub{$self->$meth(@_)}}
    };

# Easter eggs
# Just a bad joke from family guy, use this module and it'll just die on you
do {package 
Tony::Robbins; sub import {die "Tony Robbins hungry: https://www.youtube.com/watch?v=GZXp7r_PP-w\n"}; $INC{"Tony/Robbins.pm"}=1};

1;