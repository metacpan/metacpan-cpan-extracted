use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Config;
require "$FindBin::Bin/../pvim";
my $dir = tempdir(CLEANUP=>1);
sub file { File::Spec->catfile($dir,$_[0]) }
sub put { my ($p,$v)=@_; open my $f,'>',$p or die $!; binmode $f; print {$f} $v; close $f or die $! }
sub get { open my $f,'<',$_[0] or die $!; binmode $f; local $/; return <$f> }
for my $text ('',"one", "one\n", "a\nb\n", "a\r\nb\r\n", "a\r\nb\nc", "\n\n", "\0\e\xff\t\n", ('x' x 65535)."\r\nlast") {
    put(file('in'),$text);
    my $b = PVim::Store->load(file('in'));
    $b->save(file('out'),1);
    is(get(file('out')),$text,'byte-for-byte load/write, length '.length($text));
    is($b->{pieces}[0][1],$b->{count},'initial storage is one piece');
    ok(!$b->dirty,'clean after write');
}
my $b = PVim::Store->load(undef);
is($b->{count},1,'empty buffer has a line');
$b->begin; $b->set_line(0,'hello'); $b->commit;
ok($b->dirty,'edit marks dirty');
$b->save(file('new')); ok(!$b->dirty,'saved state tracked');
$b->begin; $b->splice_lines(1,0,$b->append('world')); $b->commit;
is($b->line(1),'world','append line');
ok($b->undo,'undo'); is($b->{count},1,'undo structure'); ok(!$b->dirty,'undo to saved state clean');
ok($b->undo(1),'redo'); is($b->{count},2,'redo structure');
$b->begin; $b->set_line(1,'changed'); $b->rollback; is($b->line(1),'world','transaction rollback');
put(file('new'),'external'); eval { $b->save(file('new')) }; like($@,qr/changed/,'external overwrite guarded');
$b->save(file('new'),1); is(get(file('new')), "hello\nworld\n",'forced write');
put(file('existing'),'keep'); eval { $b->save(file('existing')) }; like($@,qr/exists/,'save-as refuses existing');
SKIP: {
    skip 'POSIX link semantics',4 if $^O eq 'MSWin32';
    symlink(file('existing'),file('sym')) or die $!;
    eval { $b->save(file('sym'),1) }; like($@,qr/symlink/,'symlink refused');
    link(file('existing'),file('hard')) or die $!;
    eval { $b->save(file('hard'),1) }; like($@,qr/hard links/,'hardlink refused');
    chmod 0444,file('new'); eval { $b->save(file('new'),1) }; like($@,qr/read-only/,'read-only refused even as root');
    chmod 0750,file('new'); $b->save(file('new'),1); is((stat(file('new')))[2]&0777,0750,'mode preserved');
}
# A failed write must leave both the destination and dirty state intact.
put(file('failure'),'original');
{
    no warnings qw(redefine once);
    local *PVim::Store::write_to = sub { die "simulated write failure\n" };
    eval { $b->save(file('failure'),1) }; like($@,qr/simulated write failure/,'write failure reported');
}
is(get(file('failure')),'original','failed save preserves original bytes');
my @leftovers=glob(File::Spec->catfile($dir,'.pvim-save-*')); is(scalar @leftovers,0,'failed save removes temporary output');
SKIP: {
    skip 'Perl without large file seek',2 unless ($Config{lseeksize} || 0) >= 8;
    my $large=PVim::Store->new; my $offset=3*1024*1024*1024;
    seek($large->{data},$offset,0) or die $!; print {$large->{data}} "tail\n" or die $!;
    $large->_record($offset,4,1); $large->{pieces}=[[0,1]]; $large->reindex;
    is($large->line(0),'tail','disk-backed line beyond 2 GiB offset');
    my $result=''; open my $out,'>',\$result or die $!; $large->write_to($out); close $out;
    is($result,"tail\n",'stream write beyond 2 GiB offset');
}
# Model-based splicing: thousands of random edits against a simple array oracle.
srand 731;
$b = PVim::Store->load(undef); my @oracle = ('');
for my $step (1..1200) {
    my $at = int(rand(@oracle+1)); my $del = int(rand(@oracle-$at+1));
    my @new = map { "row-$step-$_" } 1..int(rand(5));
    $b->begin; $b->splice_lines($at,$del,map { $b->append($_) } @new); $b->commit;
    splice @oracle,$at,$del,@new; @oracle=('') unless @oracle;
    is_deeply([map { $b->line($_) } 0..$b->{count}-1],\@oracle,"splice oracle $step");
    my $serialized=''; open my $out,'>',\$serialized or die $!; binmode $out; $b->write_to($out); close $out;
    is($serialized,join("\n",@oracle)."\n","serialized oracle $step");
    if ($step%11==0) { my @after=@oracle; $b->undo; $b->undo(1); is_deeply([map { $b->line($_) } 0..$b->{count}-1],\@after,'undo/redo oracle') }
}
done_testing;
