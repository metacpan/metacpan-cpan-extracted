use strict; use warnings; use Test::More; use File::Temp 'tempdir';
use Data::PerfectHash::Shared;
my $dir=tempdir(CLEANUP=>1); my $p="$dir/v.phs";
Data::PerfectHash::Shared->build_int($p,[1,2,3]);
# truncate
{ open my $fh,'<',$p; binmode $fh; my $img=do{local $/;<$fh>}; close $fh;
  my $t="$dir/trunc.phs"; open my $w,'>',$t; binmode $w; print $w substr($img,0,10); close $w;
  eval { Data::PerfectHash::Shared->load($t) }; like $@, qr/truncated|corrupt|magic/, 'truncated refused'; }
# corrupt magic
{ open my $fh,'<',$p; binmode $fh; my $img=do{local $/;<$fh>}; close $fh; substr($img,0,4)='XXXX';
  my $c="$dir/bad.phs"; open my $w,'>',$c; binmode $w; print $w $img; close $w;
  eval { Data::PerfectHash::Shared->load($c) }; like $@, qr/magic/, 'bad magic refused'; }
# missing file
eval { Data::PerfectHash::Shared->load("$dir/nope.phs") }; like $@, qr/open/, 'missing file refused';
# foreign architecture (corrupt endian marker at byte offset 16)
{ open my $fh,'<',$p; binmode $fh; my $img=do{local $/;<$fh>}; close $fh;
  substr($img,16,8) = "\x00" x 8;
  my $f="$dir/foreign.phs"; open my $w,'>',$f; binmode $w; print $w $img; close $w;
  eval { Data::PerfectHash::Shared->load($f) }; like $@, qr/architecture|different arch|endian|foreign/i, 'foreign-arch image refused'; }
# symlink at the final path component (O_NOFOLLOW)
SKIP: {
    skip 'symlink not supported', 1 unless eval { symlink('', ''); 1 };
    my $link = "$dir/link.phs";
    symlink($p, $link) or skip "symlink: $!", 1;
    eval { Data::PerfectHash::Shared->load($link) };
    like $@, qr/open|loop|ELOOP/i, 'symlink refused (O_NOFOLLOW)';
}
done_testing;
