use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../pvim";
my $b=PVim::Store->load(undef); $b->set_line(0,'my $x=1;'); my $e=PVim::Editor->new($b);
if (eval { require Perl::Tidy; 1 }) {
    $e->key('\\'); $e->key('t'); like($b->line(0),qr/my \$x\s+=\s+1;/,'real tidy formatting');
    $e->ex('undo'); is($b->line(0),'my $x=1;','tidy undo');
    $b->set_line(0,'my $x = "unterminated;');
    my $before=$b->line(0); eval {$e->ex('pt')}; ok($@,'tidy rejects bad Perl'); is($b->line(0),$before,'failed tidy leaves buffer unchanged');
} else {
    eval {$e->ex('pt')}; like($@,qr/Perl::Tidy is unavailable/,'missing optional tidy diagnosed');
    is($b->line(0),'my $x=1;','missing tidy leaves buffer unchanged');
}
done_testing;
