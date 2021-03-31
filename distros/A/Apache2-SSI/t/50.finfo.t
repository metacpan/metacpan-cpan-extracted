#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use lib './lib';
    use_ok( 'Apache2::SSI::Finfo', ':all' ) || BAIL_OUT( "Unable to load Apache2::SSI::Finfo" );
    use constant FINFO_DEV => 0;
    use constant FINFO_INODE => 1;
    use constant FINFO_MODE => 2;
    use constant FINFO_NLINK => 3;
    use constant FINFO_UID => 4;
    use constant FINFO_GID => 5;
    use constant FINFO_RDEV => 6;
    use constant FINFO_SIZE => 7;
    use constant FINFO_ATIME => 8;
    use constant FINFO_MTIME => 9;
    use constant FINFO_CTIME => 10;
#     use constant FINFO_BLOCK_SIZE => 11;
#     use constant FINFO_BLOCKS => 12;
    our $DEBUG = 0;
    our $IS_WINDOWS_OS = ( $^O =~ /^(dos|mswin32|NetWare|symbian|win32)$/i );
};

my $file;
if( $IS_WINDOWS_OS )
{
    $file = '.\t\htdocs\ssi\include.bat';
}
else
{
    $file = './t/htdocs/ssi/include.cgi';
}
my $f = Apache2::SSI::Finfo->new( $file );
isa_ok( $f, 'Apache2::SSI::Finfo' );

{
    no warnings 'Apache2::SSI::Finfo';
    my $failed = Apache2::SSI::Finfo->new( './not-existing.txt' );
    ok( defined( $failed ), 'Non-existing file' );
    ok( $failed->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE, 'Non-existing file type' );
};

ok( FILETYPE_REG == Apache2::SSI::Finfo::FILETYPE_REG && FILETYPE_SOCK == Apache2::SSI::Finfo::FILETYPE_SOCK, 'import of constants' );

my @finfo = stat( $file );
is( $f->size, $finfo[ FINFO_SIZE ], 'size' );
is( $f->csize, $finfo[ FINFO_SIZE ], 'csize' );

is( $f->device, $finfo[ FINFO_DEV ], 'device' );

is( $f->filetype, Apache2::SSI::Finfo::FILETYPE_REG, 'file type' );

is( $f->fname, $file, 'file name' );

ok( $f->gid == $finfo[ FINFO_GID ], 'gid' );

ok( $f->group == $finfo[ FINFO_GID ], 'group' );

ok( $f->inode == $finfo[ FINFO_INODE ], 'inode' );

ok( $f->mode == ( $finfo[ FINFO_MODE ] & 07777 ), 'mode' );

if( $IS_WINDOWS_OS )
{
    is( $f->name, 'include.bat', 'file base name' );
}
else
{
    is( $f->name, 'include.cgi', 'file base name' );
}

is( $f->nlink, $finfo[ FINFO_NLINK ], 'nlink' );

is( $f->protection, hex( sprintf( '%04o', ( $finfo[ FINFO_MODE ] & 07777 ) ) ), 'File mode in hexadecimal' );

my $new = $f->stat( './t/htdocs/index.html' );
isa_ok( $new, 'Apache2::SSI::Finfo', 'stat' );

ok( $f->uid == $finfo[ FINFO_UID ], 'uid' );

ok( $f->user == $finfo[ FINFO_UID ], 'user' );

diag( "Checking finfo atime (", $f->atime, ") against file atime (", $finfo[ FINFO_ATIME ], ")." ) if( $DEBUG );
ok( $f->atime == $finfo[ FINFO_ATIME ], 'atime' );

ok( $f->mtime == $finfo[ FINFO_MTIME ], 'mtime' );

ok( $f->ctime == $finfo[ FINFO_CTIME ], 'ctime' );

ok( $f->is_file, 'is_file' );

ok( !$f->is_block, 'is_block' );

ok( !$f->is_char, 'is_char' );

ok( !$f->is_dir, 'is_dir' );

my $dir = Apache2::SSI::Finfo->new( './' );
ok( $dir->is_dir, 'is_dir2' );

ok( !$f->is_link, 'is_link' );

ok( !$f->is_pipe, 'is_pipe' );

ok( !$f->is_socket, 'is_socket' );

ok( $f->can_read, 'can_read' );

if( $f->uid == $> || $> == 0 )
{
    ok( $f->can_write, 'can_write' );
}
else
{
    ok( !$f->can_write, 'can_write' );
}

ok( $f->can_execute, 'can_execute' );

