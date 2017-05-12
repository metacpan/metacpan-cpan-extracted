#!perl

use Test::More tests => 13 * 4;
use CGI::Compile;

my $exit_return_val = sub {
    return CGI::Compile->new(return_exit_val => 1)->compile(shift)->();
};

my $exit_return_val_global = sub {
    no warnings 'once';
    local $CGI::Compile::RETURN_EXIT_VAL = 1;
    return CGI::Compile->compile(shift)->();
};

my $throw_exit_val = sub {
    my $rv = eval { CGI::Compile->compile(shift)->() };
    ok( (defined($rv) && $rv =~ /^\d+\Z/ && $@ eq '') || (!defined($rv) && $@ =~ /^exited nonzero: (\d+) /) );
    $rv = $1 if !defined($rv);
    return $rv;
};

foreach my $method ($exit_return_val, $exit_return_val_global, $throw_exit_val) {
    is ($method->(\'0;'), 0, 'fall-through exit 0');
    is ($method->(\'exit 0;'), 0, 'function exit 0');
    is ($method->(\'1;'), 1, 'fall-through exit 1');
    is ($method->(\'2.6;'), 3, 'fall-through float rounded up to int');
    is ($method->(\'4.4;'), 4, 'fall-through float rounded down to int');
    is ($method->(\'exit 1;'), 1, 'function exit 1');
    is ($method->(\'"blah";'), 0, 'fall-through exit string');
    is ($method->(\'exit "blah";'), 0, 'function exit string');
    is ($method->(\'"";'), 0, 'fall-through exit empty string');
    is ($method->(\'exit "";'), 0, 'function exit empty string');
    is ($method->(\';'), 0, 'fall-through exit undef');
    is ($method->(\'exit;'), 0, 'function exit implicit undef');
    is ($method->(\'exit undef;'), 0, 'function exit explicit undef');
}
