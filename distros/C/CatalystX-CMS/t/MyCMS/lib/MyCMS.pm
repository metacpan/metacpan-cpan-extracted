package MyCMS;

use strict;
use warnings;
use lib qw( ../../lib ../lib lib  );

use Catalyst::Runtime '5.70';
use Catalyst qw(
    ConfigLoader
    Static::Simple::ByClass
);

our $VERSION = '0.01';

use IPC::Cmd;
use File::Spec;

# setup test env **outside** our app dir,
# so we can use svn without conflict.
# we don't use File::Temp because we want a consistent path.
my $tmpdir     = $ENV{CXCMS_TMPDIR} || File::Spec->tmpdir();
my $tmpbasedir = Path::Class::dir( $tmpdir, 'cxcms' );
my $repos      = Path::Class::dir( $tmpbasedir, 'repos' );
my $cmsroot    = Path::Class::dir( $tmpbasedir, 'work' );

# check if setup already exists
unless ( -d $repos && -s "$repos/format" ) {
    $repos->mkpath;
    $cmsroot->mkpath;
    IPC::Cmd::run( command => "svnadmin create $repos" );
    IPC::Cmd::run( command => "svn mkdir file://$repos/cmstest -m init" );
    IPC::Cmd::run(
        command => "cd $cmsroot && svn co file://$repos/cmstest . " );
}

END {
    unless ( $ENV{CXCMS_TMPDIR} ) {
        $tmpbasedir->rmtree;
    }
}

__PACKAGE__->config(
    name   => 'MyCMS',
    static => {
        classes => ['CatalystX::CMS::tt'],
    },
    cms => {
        use_editor => 1,
        use_layout => 1,
        root => { r => [ __PACKAGE__->path_to('root') ], rw => [$cmsroot] },

        #default_type    => 'html',
        #default_flavour => 'default',
    },
);
__PACKAGE__->setup;

1;
