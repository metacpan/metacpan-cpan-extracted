package TestAppBuild;

use strict;
use base qw(Exporter);

use File::Path qw();
use Fatal qw(chdir open);
use Test::Differences;
use File::Find;
use ExtUtils::Command qw();
use File::Spec;
use Module::Build::ConfigData;
use Config;

our @EXPORT = qw(run_build_pl run_build clean_install check_tree
                 set_module_dir touch_file if_has_html if_has_man %Config);

my $module_dir = 'Call set_module_dir()';
my $support_executable_bit = 0;
my $support_html =    Module::Build::ConfigData->feature( 'HTML_support' )
                   && $Config{installhtmldir};
my $support_man = Module::Build::ConfigData->feature( 'manpage_support' )
                  && $Config{man3ext};

sub if_has_html { $support_html ? @_ : () }
sub if_has_man  { $support_man  ? @_ : () }

sub set_module_dir {
    $module_dir = $_[0];
}

sub clean_install {
    File::Path::rmtree( 't/test_install' );
    File::Path::rmtree( 't/Foo/blib' );
    File::Path::rmtree( 'archive' );
    File::Path::rmtree( 'unpack' );
    File::Path::mkpath( 't/test_install' );

    open my $fh, '>', 't/test_install/is_x';
    return if -x 't/test_install/is_x';
    chmod 0777, 't/test_install/is_x';
    return unless -x 't/test_install/is_x';
    $support_executable_bit = 1;
}

sub _run {
    my( $cmd, @args ) = @_;
    my $sw = $ENV{HARNESS_PERL_SWITCHES} || '';
    if( $sw ) {
        $sw =~ s{-MDevel::Cover}{-MDevel::Cover=-silent,1,-db,../../cover_db};
    }
    # warn "$^X -Mblib=../../blib $sw $cmd @args";
    qx"$^X -Mblib=../../blib $sw $cmd @args";
}

sub run_build_pl {
    my( @args ) = @_;
    local $ENV{PERL_MB_OPT};
    chdir $module_dir;
    _run( 'Build.PL', @args );
    chdir '../..';
}

sub run_build {
    my( @args ) = @_;
    local $ENV{PERL_MB_OPT};
    chdir $module_dir;
    _run( 'Build', @args );
    chdir '../..';
}

sub check_tree {
    my( $directory, $tree ) = @_;
    my $found = {};
    my $wanted = sub {
        return unless -f $_;
        my $canon_name = File::Spec->canonpath( $File::Find::name );
        $found->{$canon_name} =
          { executable => -x $_ ? 1 : 0 };
    };
    find( $wanted, $directory );

    my $fixed_tree =
        { map { File::Spec->catdir( $directory, $_ ) => $tree->{$_} }
              keys %$tree };
    if( !$support_executable_bit ) {
        $fixed_tree->{$_}{executable} = undef foreach keys %$fixed_tree;
        $found->{$_}{executable} = undef foreach keys %$found;
    } else {
        $fixed_tree->{$_}{executable} ||= 0 foreach keys %$fixed_tree;
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    eq_or_diff( $found, $fixed_tree );
}

sub touch_file {
    local @ARGV = $_[0];
    ExtUtils::Command::touch();
}

1;
