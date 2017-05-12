#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 1;

BEGIN {
    use_ok ('App::combinesheets');
}
## no critic
no strict;    # because the $VERSION will be added only when
no warnings;  # the distribution is fully built up
diag( "Loading App::combinesheets $App::combinesheets::VERSION, Perl $], $^X" );
