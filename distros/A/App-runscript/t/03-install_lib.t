use strict;
use warnings;

use Test::More import => [ qw( is is_deeply like pass plan subtest ) ], tests => 7;
use Test::Fatal qw( exception );

use File::Basename qw( basename dirname );
use File::Spec     ();
use Sub::Override  ();

use App::runscript ();

like exception {
  App::runscript::_prepend_install_lib( File::Spec->catfile( $ENV{ PWD }, qw( bin runscript ) ) )
},
  qr/has no execute permission/,
  'runscript has no execute permission';

like exception { App::runscript::_prepend_install_lib( 'baz.pl' ) }, qr/\ACannot find application/,
  'application is not in PATH';

{
  my $application = File::Spec->catfile( File::Spec->rootdir, qw( foo bar baz.pl ) );
  my $override    = Sub::Override->new(
    'App::runscript::_which' => sub ( $;$ ) { pass( 'mocked _which() called once' ); return $application } );
  like exception { App::runscript::_prepend_install_lib( 'baz.pl' ) },
    "/\\ABasename of '" . dirname( $application ) . "' is not 'bin'/",
    'application is not in bin directory';
}

{
  # mock is needed because some perl installations have a lib/perl5 library path
  my $override =
    Sub::Override->new( 'App::runscript::_is_dir' => sub ( $ ) { pass( 'mocked _is_dir() called once' ); return 0 } );
  like exception { App::runscript::_prepend_install_lib( App::runscript::_which( 'perl', 1 ) ) }, qr/\ALibrary path/,
    'library path does not exist';
}

subtest 'successfull execution' => sub {
  plan tests => 5;

  my $expected_application = File::Spec->catfile( File::Spec->rootdir, qw( foo bin baz.pl ) );
  my $expected_args        = [ qw( arg1 arg2 ) ];
  my $override             = Sub::Override->new->override(
    'App::runscript::_which' => sub ( $;$ ) { pass( 'mocked _which() called once' ); return $expected_application } )
    ->override( 'App::runscript::_is_dir' => sub ( $ ) { pass( 'mocked _is_dir() called once' ); return 1 } );

  my @got = App::runscript::_prepend_install_lib( basename( $expected_application ), @$expected_args );
  is $got[ 0 ], '-I' . File::Spec->catfile( File::Spec->rootdir, qw( foo lib perl5 ) ),
    'check library path passed to -I option';
  is $got[ 1 ], $expected_application, 'check absolute path of application';
  is_deeply [ @got[ 2 .. 3 ] ], $expected_args, 'check arguments passed to application';
};
