#!/usr/bin/env perl
use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

my @last_ran_params;
my $last_ran_self_install;

BEGIN
{
  *CORE::GLOBAL::exec = sub
  {
    @last_ran_params = @_;
  };
}
use App::MechaCPAN;

require q[./t/helper.pm];

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );

sub run_restart
{
  @last_ran_params = ();
  undef $last_ran_self_install;
  local *App::MechaCPAN::self_install = sub { $last_ran_self_install = 1 };

  App::MechaCPAN::restart_script;
}

# --directory
{
  # Override some vars it uses to insulate from the prove process
  local *File::Temp::cleanup = sub { };
  local $ENV{PERL5LIB};
  local $ENV{PERL_LOCAL_LIB_ROOT};
  local @ARGV;
  local $App::MechaCPAN::PROJ_DIR = $tmpdir;

  my $exe_path  = "$tmpdir/local/perl/bin";
  my $lib_path  = "$tmpdir/local/lib/perl5";
  my $exe_bin   = "$exe_path/perl";
  my $fake0_bin = "$tmpdir/fake0";
  my $pm        = 'App/MechaCPAN.pm';

  run_restart;
  is( scalar @last_ran_params, 0, 'restart_script without enough structure does nothing' );

  # Build a fake structure
  {
    use File::Path qw/make_path/;

    make_path $exe_path;
    make_path $lib_path;

    open my $exe, '>', $exe_bin;
    print $exe "#!/usr/bin/env perl\nexit 0\n";
    close $exe;
    chmod 0700, $exe_bin;

    open my $fake0, '>', $fake0_bin;
    print $fake0 "#!/usr/bin/env perl\nexit 0\n";
    close $fake0;
  }

  run_restart;
  isnt( scalar @last_ran_params, 0, 'restart_script with enough structure does something' );

  local $0 = $fake0_bin;
  run_restart;
  is( $last_ran_params[1], $0, '$0 can be manipulated' );

  # Test relative and absolute paths for $0

  {
    local $INC{$pm} = $fake0_bin;
    run_restart;
    isnt( scalar @last_ran_params, 0, 'Fully-contained; we can reasonably restart' );
    is( $last_ran_params[0],    $exe_bin,   'Fully-contained; reran with the new perl' );
    is( $last_ran_params[1],    $fake0_bin, 'Fully-contained; reran with the script' );
    is( $last_ran_self_install, undef,      'Fully-contained; does not attempt to install itself' );
  }

  {
    local $0 = "$fake0_bin-noit";
    run_restart;
    is( scalar @last_ran_params, 0, 'Unfindable; we do not restart' );
    isnt( $last_ran_self_install, 1, 'Unfindable; does not attempt to install itself' );
  }

  {
    run_restart;
    isnt( scalar @last_ran_params, 0, 'Installed; we can reasonably restart' );
    is( $last_ran_params[0],    $exe_bin,   'Installed; reran with the new perl' );
    is( $last_ran_params[1],    $fake0_bin, 'Installed; reran with the script' );
    is( $last_ran_self_install, 1,          'Installed; does attempt to install itself' );
  }

  # Test self_install
  my $ran_install;
  local *App::MechaCPAN::Install::go = sub { $ran_install = 1 };

  {
    is( -e "$lib_path/$pm", undef, "$pm doesn't exist before running" );

    undef $ran_install;
    App::MechaCPAN::self_install();
    is( $ran_install,       1,     'Self install with no $real0 attempts to install via cpan' );
    is( -e "$lib_path/$pm", undef, "$pm still doesn't exist" );

    undef $ran_install;
    App::MechaCPAN::self_install("$fake0_bin-noit");
    is( $ran_install,       1,     'Self install with non-existant $real0 attempts to install via cpan' );
    is( -e "$lib_path/$pm", undef, "$pm still doesn't exist" );

    {
      local @INC = ("/tmp/notthere--$$");
      BAIL_OUT(q{Cannot set @INC to a file that doesn't exist when it exists.})
        if -e $INC[0];
      undef $ran_install;
      App::MechaCPAN::self_install($fake0_bin);
      is( $ran_install,       1,     'Self install with a bad INC path attempts to install via cpan' );
      is( -e "$lib_path/$pm", undef, "$pm still doesn't exist" );
    }

    {
      local $INC{'App/MechaCPAN/notit'} = "/tmp/notthere--$$";
      BAIL_OUT(q{Cannot set @INC to a file that doesn't exist when it exists.})
        if -e $INC{'App/MechaCPAN/notit'};
      undef $ran_install;
      App::MechaCPAN::self_install($fake0_bin);
      is( $ran_install,       1,     'Self install with a bad %INC entry will skip copy' );
      is( -e "$lib_path/$pm", undef, "$pm still doesn't exist" );
    }

    undef $ran_install;
    App::MechaCPAN::self_install($fake0_bin);
    is( $ran_install, undef, 'Self install with existant $real0 attempts to install via copy' );

    # Check more than just $pm to make sure it reasonably got them all
    note("$lib_path/$pm");
    is( -e "$lib_path/$pm", 1, "$pm finally does exist" );
    is( -e "$lib_path/$pm", 1, "App/MechaCPAN/Install.pm finally does exist" );
    is( -e "$lib_path/$pm", 1, "App/MechaCPAN/Deploy.pm finally does exist" );
    is( -e "$lib_path/$pm", 1, "App/MechaCPAN/Perl.pm finally does exist" );
  }
}

chdir $pwd;
done_testing;
