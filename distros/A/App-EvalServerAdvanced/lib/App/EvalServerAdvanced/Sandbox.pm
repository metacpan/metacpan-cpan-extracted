package App::EvalServerAdvanced::Sandbox;
our $VERSION = '0.022';

use strict;
use warnings;

use Config;
use Sys::Linux::Namespace;
use Sys::Linux::Mount qw/:all/;
use Path::Tiny qw/path/;
use BSD::Resource;
use Unix::Mknod qw/makedev mknod/;
use Fcntl qw/:mode/;

use App::EvalServerAdvanced::Log;
use App::EvalServerAdvanced::Config;
use App::EvalServerAdvanced::Sandbox::Internal;
use App::EvalServerAdvanced::Seccomp;
use POSIX qw/_exit/;
use Data::Dumper;
use Sys::Linux::Syscall::Execve qw/execve_byref/;

my %sig_map;
do {
  my @sig_names = split ' ', $Config{sig_name};
  my @sig_nums = split ' ', $Config{sig_num};
  @sig_map{@sig_nums} = map {'SIG' . $_} @sig_names;
  $sig_map{31} = "SIGSYS (Illegal Syscall)";
};

my $namespace = Sys::Linux::Namespace->new(private_pid => 1, no_proc => 1, private_mount => 1, private_uts => 1,  private_ipc => 0, private_sysvsem => 1);

sub _rel2abs {
  my $base = config->sandbox->mount_base;
  die "sandbox.mount_base must be set" unless defined $base;
  my $p = shift;
  if ($p !~ m|^/|) {
    $p = path("$base/$p")->realpath;
  }
  return "".$p
}

my $seccomp;

sub run_eval {
  my $code = shift; # TODO this should be more than just code
  my $language = shift;
  my $files = shift;
  my $work_path = Path::Tiny->tempdir("eval-XXXXXXXX");

  chmod(0555, $work_path); # have to fix permissions on the new / or nobody can do anything!

  unless ($seccomp) {
    App::EvalServerAdvanced::Sandbox::Internal->load_plugins();
    $seccomp = App::EvalServerAdvanced::Seccomp->new();
    $seccomp->load_yaml(config->sandbox->seccomp->yaml); # TODO allow multiple yamls
    $seccomp->build_seccomp;
  }

  my @binds = config->sandbox->bind_mounts->@*;

  # Setup SECCOMP for us
  my $lang_config = config->language->$language;
  die "Language $language not configured." unless $lang_config;

  my $profile = $lang_config->seccomp_profile // "default";

	# Get the nobody uid before we chroot, namespace and do other funky stuff.
	my $nobody_uid = getpwnam("nobody");
	die "Error, can't find a uid for 'nobody'. Replace with someone who exists" unless $nobody_uid;

  my $exitcode = $namespace->run(code => sub {
    delete $SIG{CHLD};
    select(STDERR);
    $|++;
    select(STDOUT);
    $|++;
    binmode STDOUT, ":encoding(utf8)"; # Enable utf8 output.
    binmode STDERR, ":encoding(utf8)"; # Enable utf8 output.

    # This should end up actually reading from the IO::Async::Process stdin filehandle eventually
    # but I'm not ready to setup the protocol for that yet.
    # redirect STDIN to /dev/null, to avoid warnings in convoluted cases.
    close(STDIN);
    open STDIN, '<', '/dev/null' or die "Can't open /dev/null: $!";

    my $tmpfs_size = config->sandbox->tmpfs_size // "16m"; # / # fix syntax in kate

    my $jail_path = $work_path . "/jail";

    my $jail_home = $jail_path . (config->sandbox->home_dir // "/home"); # " # ditto
    my $jail_tmp  = "$jail_path/tmp";

    mount("tmpfs", $work_path, "tmpfs", 0, {size => $tmpfs_size});
    mount("tmpfs", $work_path, "tmpfs", MS_PRIVATE, {size => $tmpfs_size});

    path($jail_path)->mkpath();
    # put this all in a tmpfs, so that we don't pollute anywhere if possible.  TODO this should be overlayfs!
    path("$work_path/tmp/.overlayfs")->mkpath();
    # setup /tmp
    path($jail_tmp)->mkpath;

    umask(0);
    for my $bind (@binds) {
      my $src = _rel2abs($bind->{src});
      my $target = $bind->{target};

      if ($target eq config->sandbox->home_dir) {
        # We need to use overlayfs to bring the homedir in, so it's writable inside
        # without being writable to the outside

        $target = $work_path . "/home";
      } else {
        $target = $jail_path . $target;
      }

      path($target)->mkpath;

      eval {
        mount($src, $target, undef, MS_BIND|MS_PRIVATE|MS_RDONLY, undef)
      };
      if ($@) {
        die "Failed to mount ", $src, " to ", $target, ": $@\n";
      }
    }

    my $overlay_opts = {upperdir => $jail_tmp, lowerdir => "$work_path/home", workdir => "$work_path/tmp/.overlayfs"};
    path("$work_path/home")->mkpath; # Make sure it's made, even if it's not being mounted
    path($jail_home)->mkpath;
    mount("overlay", $jail_home, "overlay", 0, $overlay_opts);

    # Setup /dev
    path("$jail_path/dev")->mkpath;
    for my $dev_name (keys config->sandbox->devices->%*) {
      my ($type, $major, $minor) = config->sandbox->devices->$dev_name->@*;

      _exit(213) unless $type eq 'c';
      mknod("$jail_path/dev/$dev_name", S_IFCHR|0666, makedev($major, $minor));
    }

    path("$jail_path/tmp")->chmod(0777);
    path($jail_home)->chmod(0777);

    # Do these before the chroot.  Just to avoid weird autoloading issues
    set_resource_limits();

    chdir($jail_path) or die "Jail was not made"; # ensure it exists before we chroot. unnecessary?
    chroot($jail_path) or die $!;
    chdir(config->sandbox->home_dir // "/home") or die "Couldn't chdir to the home"; #'

    # TODO Also look at making calls about dropping capabilities(2).  I don't think it's needed but it might be a good idea
    # Here's where we actually drop our root privilege
    $)="$nobody_uid $nobody_uid";
    $(=$nobody_uid;
    $<=$>=$nobody_uid;
    POSIX::setgid($nobody_uid); #We just assume the uid is the same as the gid. Hot.

    die "Failed to drop to nobody"
        if $> != $nobody_uid
        or $< != $nobody_uid;

    %ENV = config->sandbox->environment->%*; # set the environment up

    my $main_file;
    # Create the other files.
    for my $file (@$files) {
      my $filename = $file->filename;
      my $contents = $file->contents;

      if ($filename eq '__code') {
        $main_file = $file;
        next; # don't write it here
      }
      my $path = path($filename);
      $path->parent()->mkpath(); # try to create the directory needed.  If it fails, the eval fails

      open(my $fh, ">", $filename) or die "Can't write to $filename: $!";
      print $fh $contents; # simple output, don't worry about encodings?
      close($fh);
    }

    # Enable seccomp
    $seccomp->apply_seccomp($profile); # TODO Make this optional, somehow for testing

    # TODO make this accept a filename, that's already written instead of code
    run_code($language, $code, $main_file);
  });

  rmdir($work_path) or warn "Couldn't remove tempdir";

  my ($exit, $signal) = (($exitcode&0xFF00)>>8, $exitcode&0xFF);

  if ($exit) {
    print "[Exited $exit]";
  } elsif ($signal) {
    my $signame = $sig_map{$signal} // $signal;
    print "[Died $signame]";
  }
}

sub set_resource_limits {
  my %sizes = (
    "t" => 1024 ** 4, # what the hell are you doing needing this?
    "g" => 1024 ** 3,
    "m" => 1024 ** 2,
    "k" => 1024 ** 1,
  );

  my $conv = sub { my ($v, $t)=($_[0] =~ /(\d+)(\w)/); $v * (exists $sizes{lc $t} ? $sizes{lc $t} : 1) };
  my $srl = sub { setrlimit($_[0], $_[1], $_[1]) };

  my $cfg_rlimits = config->sandbox->rlimits;

  $srl->(RLIMIT_VMEM, $conv->($cfg_rlimits->VMEM)) and
  $srl->(RLIMIT_AS, $conv->($cfg_rlimits->AS)) and
  $srl->(RLIMIT_DATA, $conv->($cfg_rlimits->DATA)) and
  $srl->(RLIMIT_STACK, $conv->($cfg_rlimits->STACK)) and
  $srl->(RLIMIT_NPROC, $cfg_rlimits->NPROC) and
  $srl->(RLIMIT_NOFILE, $cfg_rlimits->NOFILE) and
  $srl->(RLIMIT_OFILE, $cfg_rlimits->OFILE) and
  $srl->(RLIMIT_OPEN_MAX, $cfg_rlimits->OPEN_MAX) and
  $srl->(RLIMIT_LOCKS, $cfg_rlimits->LOCKS) and
  $srl->(RLIMIT_MEMLOCK, $cfg_rlimits->MEMLOCK) and
  $srl->(RLIMIT_CPU, $cfg_rlimits->CPU)
		or die "Failed to set rlimit: $!";
}

sub run_code {
  my ($lang, $code, $code_file) = @_;

  my $lang_config = config->language->$lang;

  if (my $wrapper = $lang_config->wrap_code) {
    $code = App::EvalServerAdvanced::Sandbox::Internal->$wrapper($lang, $code);
  }

  if (my $sub_name = $lang_config->sub()) {
    App::EvalServerAdvanced::Sandbox::Internal->$sub_name($lang, $code);
    return;
  } elsif (my $bin = $lang_config->bin()) {
    my $arg_list = $lang_config->args // ["%FILE%"];
    my ($file) = Path::Tiny->tempfile;

    open(my $tfh, ">", "$file");
    print $tfh $code_file->contents;
    close($tfh);

    # bin must be at the start of the arguments
    $arg_list = [$bin, map {
      if ($_ eq '%FILE%') {
        "$file";
      } elsif ($_ eq '%CODE%') {
        $code;
      } else {
        $_;
      }
    } @$arg_list];

    execve_byref(\$bin, $arg_list, \%ENV) or die "Couldn't exec $bin: $!";
  } else {
    die "No configured way to run $lang\n";
  }
}

1;
