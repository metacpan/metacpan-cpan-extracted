#!/usr/bin/perl

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('Proc::Reliable');
    use_ok('Devel::TakeHashArgs');
    use_ok('Class::Data::Accessor');
	use_ok( 'App::PNGCrush' );
}

diag( "Testing App::PNGCrush $App::PNGCrush::VERSION, Perl $], $^X" );
my $o = App::PNGCrush->new;

isa_ok($o,'App::PNGCrush');

my %Valid_Options = qw(
    already_size            -already
    bit_depth               -bit_depth
    background              -bkgd
    brute_force             -brute
    color_type              -c
    color_counting          -cc
    output_dir              -d
    double_image_gamma      -dou
    output_extension        -e
    filter                  -f
    fix_fatal               -fix
    output_force            -force
    gamma                   -g
    itxt                    -itxt
    level                   -l 
    method                  -m
    maximum_idat            -max
    no_output               -n
    no_color_counting       -no_cc
    plte_length             -plte_len
    remove                  -rem
    replace_gamma           -replace_gamma
    resolution              -res
    save_unknown            -save
    srgb                    -srgb
    text                    -text
    transparency            -trns
    window_size             -w
    strategy                -z
    insert_ztxt             -zitxt
    ztxt                    -ztxt
    verbose                 -v
);

can_ok($o, qw(
    new
    run
    reset_options
    set_options
    _make_options
    _set_error
), keys %Valid_Options);