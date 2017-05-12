#!./perl

use Test::More tests => 12;
use warnings;
no warnings <deprecated syntax>;

BEGIN{$SIG{__WARN__}=sub{warn$_[0];++$w}}

no warnings < void >;
split //, "plin";
@old = @_;
use warnings < void >;

use Classic'Perl;
split //, "plin";
is "@_", "p l i n", 'split in void context';
@_ = ();
scalar split //, "drelp";
is "@_", "d r e l p", 'split in scalar context';
@_ = ();
is "@{[ split //, 'swow' ]}", "s w o w", 'split in list context';
is "@_", "", 'split in list context has no side effects';
is $w, undef, 'void split warneth not';

no warnings 'void';
no Classic'Perl;
@_ = ();
split //, "plin";
is "@_", "@old", 'the old void behaviour is restored with no CP';

{
 use Classic'Perl
}
@_ = ();
split //, "plin";
is "@_", "@old", 'CP lasts only till the end of the block';

use Classic::Perl '$*';
@_ = ();
split //, "plin";
is "@_", "@old", 'other CP pragmata do not turn on split';

{
 use Classic::::Perl 5.011;
 @_ = ();
 split //, "plin";
 is "@_", "@old", 'Classic::::Perl 5.011 leaves split off';
 use Classic::::Perl 5.010;
 split //, "plin";
 is "@_", "p l i n", 'Classic::::Perl 5.010 turns split on';
}

use warnings 'void';

# Cases that should still warn
use Classic'Perl;
$SIG{__WARN__}=sub{$w.=$_[0]};
$w = '';
eval 'split //, (my $foo = 3) . (my $foo = 4); 1';
like $w, qr/mask/, 'sub ops of a void split still warn';
$w = '';
eval 'split //, (3, 4).do{3;4}; 1';
like $w, qr/useless.*useless/is,
 'sub ops of a void split still emit void warnings';
