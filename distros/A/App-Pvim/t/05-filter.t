use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
require "$FindBin::Bin/../pvim";
my $dir=tempdir('pvim filter XXXXX',TMPDIR=>1,CLEANUP=>1);
my $helper=File::Spec->catfile($dir,'helper script.pl');
open my $fh,'>',$helper or die $!;
print {$fh} <<'HELPER';
use strict;
use warnings;
binmode STDIN; binmode STDOUT; binmode STDERR;
my $mode=shift;
if ($mode eq 'upper') { while (<STDIN>) { print uc $_ } }
elsif ($mode eq 'expand') { while (<STDIN>) { print $_,$_; } }
elsif ($mode eq 'drop') { while (<STDIN>) {} }
elsif ($mode eq 'nonl') { local $/; my $s=<STDIN>; $s =~ s/\r?\n\z//; print $s }
elsif ($mode eq 'prefix') { while (<STDIN>) { print 'x',$_ } }
elsif ($mode eq 'fail') { print 'must not replace'; print STDERR 'expected diagnostic'; exit 7 }
elsif ($mode eq 'stderr') { print STDERR 'z' x 200000; while (<STDIN>) { print uc $_ } }
elsif ($mode eq 'unterminated') { print 'tail' }
else { die 'bad mode' }
HELPER
close $fh or die $!;
my ($exe,$script)=($^X,$helper); s{\\}{/}g for $exe,$script;
sub cmd { return qq{"$exe" "$script" $_[0]} }
sub editor {
    my $b=PVim::Store->load(undef);
    $b->splice_lines(0,1,map {$b->append($_)} @_);
    return PVim::Editor->new($b);
}
sub lines { my ($e)=@_; [map {$e->{b}->line($_)} 0..$e->{b}{count}-1] }
my $e=editor('one','two','three','four');
$e->ex('2'); $e->ex('.! '.cmd('upper'));
is_deeply(lines($e),['one','TWO','three','four'],'dot range filters current line');
$e->ex('undo'); is_deeply(lines($e),['one','two','three','four'],'filter is one undo unit');
$e->ex('redo'); is($e->{b}->line(1),'TWO','filter redo');
$e->ex('1,3! '.cmd('expand')); is_deeply(lines($e),['one','one','TWO','TWO','three','three','four'],'range may expand line count');
$e->ex('undo'); $e->ex('%! '.cmd('upper')); is_deeply(lines($e),['ONE','TWO','THREE','FOUR'],'percent applies to full buffer');
$e->ex('2'); $e->ex('.,$! '.cmd('prefix')); is_deeply(lines($e),['ONE','xTWO','xTHREE','xFOUR'],'dot and dollar ranges');
my $before=lines($e); my $state=$e->{b}{state};
eval {$e->ex('%! '.cmd('fail'))}; like($@,qr/Filter failed.*expected diagnostic/s,'nonzero filter diagnoses failure');
is_deeply(lines($e),$before,'failed filter preserves all buffer lines'); is($e->{b}{state},$state,'failed filter adds no undo change');
$e->ex('%! '.cmd('stderr')); like($e->{message},qr/^Filtered /,'large stderr cannot deadlock');
ok(length($e->{message})<5000,'stderr diagnostic bounded');
$e=editor('a','b','c'); $e->ex('2! '.cmd('drop')); is_deeply(lines($e),['a','c'],'empty output deletes selected line');
$e->ex('%! '.cmd('drop')); is_deeply(lines($e),[''],'empty output can empty entire buffer'); ok(!$e->{b}{final},'empty output has no final newline');
$e->ex('undo'); is_deeply(lines($e),['a','c'],'undo restores fully deleted buffer');
$e=editor('a','b'); $e->ex('2! '.cmd('nonl')); ok(!$e->{b}{final},'EOF output controls final-newline state');
$e->ex('undo'); ok($e->{b}{final},'undo restores final-newline state');
$e->ex('1! '.cmd('unterminated')); is_deeply(lines($e),['tail','b'],'unterminated middle result remains separate line');
$e=editor('a','b'); $e->ex('%! '.cmd('upper').' | '.cmd('prefix')); is_deeply(lines($e),['xA','xB'],'explicit shell pipelines work');
for my $bad ('!','5! '.cmd('upper'),'2,1! '.cmd('upper')) { eval {$e->ex($bad)}; ok($@,"invalid filter rejected: $bad") }
# Hooks run around external execution and are restored even for a failed filter.
my @hooks; $e->{before_filter}=sub {push @hooks,'before'}; $e->{after_filter}=sub {push @hooks,'after'};
eval {$e->ex('.! '.cmd('fail'))}; is_deeply(\@hooks,['before','after'],'terminal hooks bracket failed command');
$e=editor('original');
my $shellout=File::Spec->catfile($dir,'shell output'); $shellout =~ s{\\}{/}g;
$e->ex('! '.cmd('unterminated').qq{ > "$shellout"});
is_deeply(lines($e),['original'],'unranged shell command does not alter buffer');
open my $check,'<',$shellout or die $!; local $/; my $text=<$check>; close $check;
is($text,'tail','unranged shell command executed');
$e->ex('r !'.cmd('unterminated')); is_deeply(lines($e),['original','tail'],'read inserts output below current line');
$e->ex('undo'); is_deeply(lines($e),['original'],'read undo');
$e->ex('0r !'.cmd('unterminated')); is_deeply(lines($e),['tail','original'],'zero read address inserts at top');
$e->ex('undo'); $e->ex('1r !'.cmd('unterminated')); is_deeply(lines($e),['original','tail'],'explicit read address');
$e->ex('r !'.cmd('drop')); is_deeply(lines($e),['original','tail'],'empty read output leaves text intact');
$e=editor('a','b','c'); $e->key('!'); $e->key('!'); is($e->{prompt},':.!','double bang prepares current-line filter');
$e=editor('a','b','c'); $e->key('2'); $e->key('!'); $e->key('!'); is($e->{prompt},':1,2!','counted bang prepares line range');
done_testing;
