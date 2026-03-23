use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Cmd::Init;
use App::karr::Cmd::Skill;

subtest 'init and skill commands read bundled skill content from File::ShareDir' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $file = path($dir)->child('claude-skill.md');
    $file->spew_utf8("# mocked skill\n");

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return $dir };

    my $init = App::karr::Cmd::Init->new;
    is( $init->_find_skill_source, "# mocked skill\n", 'init reads skill content from share dir' );

    my $skill = App::karr::Cmd::Skill->new;
    is( $skill->_skill_content, "# mocked skill\n", 'skill command reads skill content from share dir' );
};

done_testing;
