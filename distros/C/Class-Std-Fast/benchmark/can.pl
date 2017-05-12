use lib '../lib';
use Class::Std::Fast;
use Benchmark qw(cmpthese);

cmpthese 1000000 , {
    can => sub { return 1 if (Class::Std::Fast->can('DESTROY')) },
    symbol => sub { return 1 if (*{Class::Std::Fast::DESTROY}{CODE}) },
    exist => sub { return 1 if exists &{Class::Std::Fast::DESTROY} },
};
