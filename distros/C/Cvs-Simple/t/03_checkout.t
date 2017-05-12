#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests=>5;
use Cvs::Simple;

my($cvs) = Cvs::Simple->new();
isa_ok($cvs,'Cvs::Simple');

{
local($@);
eval{$cvs->checkout()};
like($@,qr/Syntax: /);
}
{
local($@);
eval{$cvs->checkout(qw(1 2 3))};
like($@,qr/Syntax: /);
}

{
local($@);
eval{$cvs->co()};
like($@,qr/Syntax: /);
}

{
local($@);
eval{$cvs->co(qw(1 2 3))};
like($@,qr/Syntax: /);
}

exit;
__END__

