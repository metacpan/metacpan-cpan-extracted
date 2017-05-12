# -*-cperl-*-

use strict;
use lib qw(../../inc ../inc);
use blib;

use Test::More;

BEGIN {
    use AFS::FS;
    if (AFS::FS::isafs('./')) { plan tests => 48; }
    else { plan skip_all => 'Working directory is not in AFS file system ...'; }

    use_ok('AFS::PTS');
}

use AFS::Cell 'localcell';
my $cell = localcell;

my $pts = AFS::PTS->new(2, $cell);
is(ref($pts), 'AFS::PTS', 'pts->new(2,cell)');

$pts = AFS::PTS->new(1);
is(ref($pts), 'AFS::PTS', 'pts->new(1)');

$pts = AFS::PTS->new;
is(ref($pts), 'AFS::PTS', 'pts->new()');
undef $pts;

is(leak_test($cell), 1210, 'pts leak_test');

$pts = AFS::PTS->new;
can_ok('AFS::PTS', qw(ascii2ptsaccess));

can_ok('AFS::PTS', qw(ptsaccess2ascii));

can_ok('AFS::PTS', qw(convert_numeric_names));

can_ok('AFS::PTS', qw(adduser));

can_ok('AFS::PTS', qw(chid));

can_ok('AFS::PTS', qw(chown));

can_ok('AFS::PTS', qw(creategroup));

can_ok('AFS::PTS', qw(createuser));

can_ok('AFS::PTS', qw(delete));

can_ok('AFS::PTS', qw(dumpentry));

can_ok('AFS::PTS', qw(getcps));

can_ok('AFS::PTS', qw(id));

can_ok('AFS::PTS', qw(ismember));

can_ok('AFS::PTS', qw(listentry));

can_ok('AFS::PTS', qw(listmax));

can_ok('AFS::PTS', qw(members));

can_ok('AFS::PTS', qw(name));

can_ok('AFS::PTS', qw(owned));

can_ok('AFS::PTS', qw(rename));

can_ok('AFS::PTS', qw(removeuser));

can_ok('AFS::PTS', qw(setaccess));

can_ok('AFS::PTS', qw(setgroupquota));

can_ok('AFS::PTS', qw(setmax));

can_ok('AFS::PTS', qw(whereisit));

can_ok('AFS::PTS', qw(PR_AddToGroup));

can_ok('AFS::PTS', qw(PR_ChangeEntry));

can_ok('AFS::PTS', qw(PR_Delete));

can_ok('AFS::PTS', qw(PR_DumpEntry));

can_ok('AFS::PTS', qw(PR_GetCPS));

can_ok('AFS::PTS', qw(PR_IDToName));

can_ok('AFS::PTS', qw(PR_INewEntry));

can_ok('AFS::PTS', qw(PR_IsAMemberOf));

can_ok('AFS::PTS', qw(PR_ListElements));

can_ok('AFS::PTS', qw(PR_ListEntry));

can_ok('AFS::PTS', qw(PR_ListMax));

can_ok('AFS::PTS', qw(PR_ListOwned));

can_ok('AFS::PTS', qw(PR_NameToID));

can_ok('AFS::PTS', qw(PR_NewEntry));

can_ok('AFS::PTS', qw(PR_RemoveFromGroup));

can_ok('AFS::PTS', qw(PR_SetFieldsEntry));

can_ok('AFS::PTS', qw(PR_SetMax));

can_ok('AFS::PTS', qw(PR_WhereIsIt));

$pts->DESTROY;
ok(! defined $pts, 'pts->DESTROY');

sub leak_test {
    my $cell  = shift;

    my $count = 0;
    my $sec   = 1;
    while(1) {
        $count++;
        my $pts = AFS::PTS->new($sec, $cell);
        $pts->DESTROY();
        if ($count == 1210) { last; }
    }
    return $count;
}
