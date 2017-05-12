#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use Test::More tests=>5;
use Cvs::Simple;

{
my($cvs) = Cvs::Simple->new();
isa_ok($cvs,'Cvs::Simple');
{
local($@);
eval{$cvs->commit(qw(1 2 3 4 5))};
like($@,qr/Syntax: /, 'Too many args');
}
{
local($@);
eval{$cvs->commit(1, 'filename')};
like($@,qr/Syntax: /);
}

{
local($@);
eval{$cvs->ci(qw(1 2 3 4 5))};
like($@,qr/Syntax: /, 'Too many args');
}
{
local($@);
eval{$cvs->ci(1, 'filename')};
like($@,qr/Syntax: /);
}
}

exit;
__END__

