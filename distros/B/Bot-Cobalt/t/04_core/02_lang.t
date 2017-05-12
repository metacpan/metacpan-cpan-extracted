use Test::More tests => 15;
use strict; use warnings;

use Test::File::ShareDir
  -share => +{
    -dist => +{ 'Bot-Cobalt' => 'share' },
  };

my %sets = (
  ## Last updated for SPEC: 7
  CORE => [ qw/  
    RPL_NO_ACCESS
    RPL_DB_ERR
    RPL_PLUGIN_LOAD
    RPL_PLUGIN_UNLOAD
    RPL_PLUGIN_ERR
    RPL_PLUGIN_UNLOAD_ERR
    RPL_TIMER_ERR
  / ],
  
  IRC => [ qw/
    RPL_CHAN_SYNC
  / ],

  VERSION => [ qw/
    RPL_VERSION RPL_INFO RPL_OS
  / ],
  
  ALARMCLOCK => [ qw/
    ALARMCLOCK_SET
    ALARMCLOCK_NOSUCH
    ALARMCLOCK_NOTYOURS
    ALARMCLOCK_DELETED
  / ],
  
  AUTH => [ qw/
    AUTH_BADSYN_LOGIN
    AUTH_BADSYN_CHPASS
    AUTH_SUCCESS
    AUTH_FAIL_BADHOST
    AUTH_FAIL_BADPASS
    AUTH_FAIL_NO_SUCH
    AUTH_FAIL_NO_CHANS
    AUTH_CHPASS_BADPASS
    AUTH_CHPASS_SUCCESS
    AUTH_STATUS
    AUTH_USER_ADDED
    AUTH_MASK_ADDED
    AUTH_MASK_EXISTS
    AUTH_MASK_DELETED
    AUTH_USER_DELETED
    AUTH_USER_NOSUCH
    AUTH_USER_EXISTS
    AUTH_NOT_ENOUGH_ACCESS
  / ],
  
  INFO => [ qw/
    INFO_DONTKNOW
    INFO_WHAT
    INFO_TELL_WHO
    INFO_TELL_WHAT
    INFO_ADD
    INFO_DEL
    INFO_ABOUT
    INFO_REPLACE
    INFO_ERR_NOSUCH
    INFO_ERR_EXISTS
    INFO_BADSYNTAX_ADD
    INFO_BADSYNTAX_DEL
    INFO_BADSYNTAX_REPL
  / ],
  
  RDB => [ qw/
    RDB_ERR_NO_SUCH_RDB
    RDB_ERR_INVALID_NAME
    RDB_ERR_NO_SUCH_ITEM
    RDB_ERR_NO_STRING
    RDB_ERR_RDB_EXISTS
    RDB_ERR_NOTPERMITTED
    RDB_CREATED
    RDB_DELETED
    RDB_ITEM_ADDED
    RDB_ITEM_DELETED
    RDB_ITEM_INFO
    RDB_UNLINK_FAILED
  / ],
  
);

BEGIN {
  use_ok( 'Bot::Cobalt::Lang' );
}

use Try::Tiny;
use File::Spec;

my $langdir = File::Spec->catdir( 'share', 'etc', 'langs' );

## Should die:
try {
  Bot::Cobalt::Lang->new(
    lang => 'somelang',
  );
} catch {
  pass("Died as expected in new()");
  0
} and fail("Should've died for insufficient args in new()");


## absolute_path :
my $absolute = new_ok( 'Bot::Cobalt::Lang' => [
    lang => 'english',
    absolute_path => File::Spec->catfile( $langdir, 'english.yml' ),
  ],
);

ok(keys %{ $absolute->rpls }, 'absolute_path set has RPLs' );

undef $absolute;


## use_core + english :
my $coreset = new_ok( 'Bot::Cobalt::Lang' => [
    use_core => 1,
    
    lang => 'english',
    lang_dir => $langdir,
  ],
);

ok_lang_has_all($coreset);

undef $coreset;


## use_core_only (also tests that the builtin set can be loaded twice):
my $coreset_only = new_ok( 'Bot::Cobalt::Lang' => [
    lang => 'english',
    use_core_only => 1,
  ],
);

ok_lang_has_all($coreset_only);

undef $coreset_only;


## english (no use_core):
my $english = new_ok( 'Bot::Cobalt::Lang' => [
    lang => 'english',
    lang_dir => $langdir,
  ],
);

ok(keys %{ $english->rpls }, 'english set has RPLs' );

cmp_ok( $english->spec, '>=', 7 );

ok_lang_has_all($english);


## ebonics (no use_core):
my $ebonics = new_ok( 'Bot::Cobalt::Lang' => [
    lang => 'ebonics',
    lang_dir => $langdir,
  ],
);

ok( keys %{ $ebonics->rpls }, 'ebonics set has RPLs' );

ok_lang_has_all($ebonics);



sub ok_lang_has_all {
  my ($lang_obj) = @_;

  my $lang_name = $lang_obj->lang;

  my @failed;
  
  SET: for my $set (keys %sets) {
    RPL: for my $rpl ( @{$sets{$set}} ) {
      push(@failed, $rpl)
        unless $lang_obj->rpls->{$rpl};
    }
  }

  if (@failed) {
    diag(
      "Missing RPLs in $lang_name ; ",
      join(', ', @failed)
    );
    fail("Language set completion");
  } else {
    pass("Language set completion");
  }
}
