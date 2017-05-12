BEGIN{@::ARGV = ( 'test' , '--pass' )};
use Test::More ();
# BEGIN { Test::More::use_ok ( 'App::Rad::Plugin::ReadLine'); };

use warnings;
use strict;


#use App::Rad::Plugin::ReadLine::Demo qw[ demo getopt ];
use App::Rad
 qw[ ReadLine ]
;

App::Rad->run();

sub setup { 
    Test::More::ok (1,'setup ran');
    my $c = shift;

    Test::More::isa_ok ($c,'App::Rad');
    # plugin must be loaded if 
    Test::More::can_ok ($c,'shell','shell_options');

    $c->register_commands();

    Test::More::ok (1,'returning');
    
} 
sub default {
    Test::More::fail ('default');
    my $c=shift;
    Test::More::diag (
        Data::Dumper->Dump(
            [ $c->options, $c->argv, \@ARGV ],
            [qw( $c->options $c->argv @ARGV)]
        )
    );
} 

sub test :Help('critters'){
    Test::More::ok (1,'test called');
    my $c= shift;
    Test::More::ok( $c->options->{pass} , 'told to pass') ;
}

sub shell { shift->shell }

Test::More::done_testing;
