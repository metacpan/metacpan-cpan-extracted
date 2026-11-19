use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/../pvim";
sub editor {
    my (@lines)=@_; my $b=PVim::Store->load(undef);
    $b->splice_lines(0,1,map {$b->append($_)} @lines);
    return PVim::Editor->new($b);
}
sub sendkeys { my ($e,$keys)=@_; $e->key($_) for split //,$keys }
sub lines { my ($e)=@_; return [map {$e->{b}->line($_)} 0..$e->{b}{count}-1] }
my $e=editor('alpha beta','  gamma','delta');
sendkeys($e,'2j'); is($e->{row},2,'counted down');
sendkeys($e,'gg'); is($e->{row},0,'gg'); sendkeys($e,'2G^'); is($e->{col},2,'first nonblank');
sendkeys($e,'0'); is($e->{col},0,'absolute start'); sendkeys($e,'$'); is($e->{col},6,'line end');
sendkeys($e,'ggw'); is($e->{col},6,'word forward'); sendkeys($e,'b'); is($e->{col},0,'word backward'); sendkeys($e,'e'); is($e->{col},4,'word end');
sendkeys($e,"ggiX\e"); is($e->{b}->line(0),'Xalpha beta','insert'); sendkeys($e,'u'); is($e->{b}->line(0),'alpha beta','undo insert session'); sendkeys($e,"\x12"); is($e->{b}->line(0),'Xalpha beta','redo');
sendkeys($e,"A!\e"); is($e->{b}->line(0),'Xalpha beta!','append end');
sendkeys($e,"gg0Rzz\e"); is($e->{b}->line(0),'zzlpha beta!','replace mode');
sendkeys($e,'02rY'); is($e->{b}->line(0),'YYlpha beta!','counted replace');
sendkeys($e,'2x'); is($e->{b}->line(0),'lpha beta!','counted delete');
sendkeys($e,'yyGp'); is($e->{b}->line(3),'lpha beta!','line yank put');
sendkeys($e,'P'); is($e->{b}{count},5,'put above'); sendkeys($e,'2dd'); is($e->{b}{count},3,'counted line delete');
$e=editor('one two','three'); sendkeys($e,'dw'); is_deeply(lines($e),['two','three'],'delete word');
sendkeys($e,'p'); is($e->{b}->line(0),'tone wo','characterwise put');
$e=editor('hello world'); sendkeys($e,"cwnew\e"); is($e->{b}->line(0),'new world','change word preserves whitespace');
$e=editor('one','two'); sendkeys($e,"ohello\e"); is_deeply(lines($e),['one','hello','two'],'open below');
sendkeys($e,'u'); is_deeply(lines($e),['one','two'],'open and insert atomic undo');
sendkeys($e,"Ozero\e"); is_deeply(lines($e),['zero','one','two'],'open above');
$e=editor('abcd'); sendkeys($e,"liX\rY\b\b\e"); is_deeply(lines($e),['aXbcd'],'insert split/backspace join');
$e=editor('one','  two'); sendkeys($e,'J'); is_deeply(lines($e),['one two'],'join strips indent'); sendkeys($e,'u'); is_deeply(lines($e),['one','  two'],'undo join');
$e=editor('first','second','third'); sendkeys($e,"ccnew\e"); is_deeply(lines($e),['new','second','third'],'change line');
sendkeys($e,'u'); is_deeply(lines($e),['first','second','third'],'undo change line');
$e=editor('single'); sendkeys($e,"ccnew\e"); is_deeply(lines($e),['new'],'change sole line');
$e=editor('a','b','c'); sendkeys($e,"3ccnew\e"); is_deeply(lines($e),['new'],'change all lines');
$e=editor('last'); sendkeys($e,'dw'); is_deeply(lines($e),[''],'dw at EOF');
$e=editor('aaa bbb aaa','last aaa'); $e->search('aaa',1); is($e->{col},8,'search skips current match');
sendkeys($e,'n'); is($e->{row},1,'search next line'); sendkeys($e,'n'); is_deeply([@{$e}{qw(row col)}],[0,0],'search wrap');
sendkeys($e,'N'); is($e->{row},1,'reverse repeat'); sendkeys($e,'n'); is_deeply([@{$e}{qw(row col)}],[0,0],'n retains original search direction after N');
$e->search('^',-1); ok(1,'zero-width backwards search terminates');
eval {$e->search('[',1)}; like($@,qr/Invalid regex/,'invalid regex');
eval {$e->search('not-found',1)}; like($@,qr/not found/,'missing search');
$e=editor('foo FOO foo','foo'); $e->ex('%s/foo/bar/gi'); is_deeply(lines($e),['bar bar bar','bar'],'global insensitive substitution');
$e->ex('undo'); is_deeply(lines($e),['foo FOO foo','foo'],'whole-file substitution single undo');
$e->ex('1s/(foo)/[\1-&]/'); is($e->{b}->line(0),'[foo-foo] FOO foo','capture and whole match');
$e->ex('2s#foo#a\#b#'); is($e->{b}->line(1),'a#b','alternate escaped delimiter');
$e->ex('2s/a#b/\&\t/'); is($e->{b}->line(1),"&\t",'literal ampersand and tab');
$e=editor('ab'); $e->ex('s/^/X/g'); is($e->{b}->line(0),'Xab','zero-width global');
for my $cmd ('%s/a/b/e','9s/a/b/','2,1s/a/b/','s/a/b','bogus') { eval {$e->ex($cmd)}; ok($@,"reject $cmd") }
$e=editor('a','b'); sendkeys($e,"i!\e"); eval {$e->ex('q')}; like($@,qr/Unsaved/,'quit guard');
eval {$e->ex('e absent')}; like($@,qr/Unsaved/,'edit guard'); $e->ex('q!'); ok($e->{quit},'force quit');
$e=editor('a'); ok(!$e->{number},'numbers are off by default'); $e->ex('set nonumber'); ok(!$e->{number},'hide numbers'); $e->ex('set number'); ok($e->{number},'show numbers');
$e=editor('a'); sendkeys($e,"d\ex"); is_deeply(lines($e),[''],'Escape cancels operator');
$e=editor('one','two','three','four','five','six','seven'); sendkeys($e,'2d3d'); is_deeply(lines($e),['seven'],'operator counts multiply');
$e=editor('a'); sendkeys($e,":s/a/b/\r"); is_deeply(lines($e),['b'],'prompt dispatch'); sendkeys($e,":junk\e"); is($e->{mode},'normal','prompt cancel');
# Render helpers cannot inject file-provided terminal escapes.
is(PVim::Terminal::safe("\e[31m\xff"),'<1B>[31m<FF>','escape bytes sanitized');
my ($cells,$positions)=PVim::Terminal::cells("a\tb",8); is($cells,'a       b','tab rendering'); is_deeply($positions,[0,1,8,9],'byte-to-screen mapping');
$e=editor('a.b','axb'); $e->ex('%s.a\\.b.X.'); is_deeply(lines($e),['X','axb'],'regex metacharacter delimiter stays literal');
$e=editor('foo'); $e->ex('s&foo&\\&&'); is($e->{b}->line(0),'&','escaped ampersand delimiter literal');
$e=editor('copied'); sendkeys($e,'yy'); $e->ex('enew!'); sendkeys($e,'p'); is_deeply(lines($e),[''],'new buffer cannot reference old register storage');
$e=editor(map { 'foo foo' } 1..5000); $e->ex('%s/foo/bar/g'); is($e->{b}->line(4999),'bar bar','bulk substitution final line');
is(scalar @{$e->{b}{pieces}},1,'bulk substitute coalesces contiguous edit run'); $e->ex('undo'); is($e->{b}->line(4999),'foo foo','bulk substitution undo');
for my $bytes ("a\tb", "\e\0\xff",'x'x200, "\t"x100) {
    my ($expected)=PVim::Terminal::cells($bytes,8);
    is(PVim::Terminal::display($bytes,8,undef),$expected,'fast display equals reference renderer');
    is(PVim::Terminal::display($bytes,8,17),substr($expected,0,17),'bounded display equals clipped reference');
}
$e=editor('abc','def'); $e->search('$',1); is_deeply([@{$e}{qw(row col)}],[0,2],'line-end search cursor');
sendkeys($e,'n'); is_deeply([@{$e}{qw(row col)}],[1,2],'repeat line-end search advances');
sendkeys($e,'n'); is_deeply([@{$e}{qw(row col)}],[0,2],'line-end search wraps');
sendkeys($e,'N'); is_deeply([@{$e}{qw(row col)}],[1,2],'line-end reverse repeat');
done_testing;
