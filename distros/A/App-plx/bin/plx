#!perl

package App::plx;

our $VERSION = '0.901001'; # 0.901.1

$VERSION = eval $VERSION;

use strict;
use warnings;
use File::Spec;
use File::Basename ();
use Cwd ();
use lib ();
use Config;
use File::Which ();
use List::Util ();

BEGIN { our %orig_env = %ENV }
use local::lib '--deactivate-all';
BEGIN { delete @ENV{grep /^PERL/, keys %ENV} }
no lib @Config{qw(sitearch sitelibexp)};

my $fs = 'File::Spec';

my $self = do {
  package Perl::Layout::Executor::_self;
  sub self { package DB; () = caller(2); $DB::args[0] }
  use overload '%{}' => sub { self }, fallback => 1;
  sub AUTOLOAD {
    my ($meth) = (our $AUTOLOAD =~ /([^:]+)$/);
    self->$meth(@_[1..$#_]);
  }
  sub DESTROY {}
  bless([], __PACKAGE__);
};

sub barf { die "$_[0]\n" }

sub stderr { warn "$_[0]\n" }

sub say { print "$_[0]\n" }

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub layout_base_dir {
  $self->{layout_base_dir} //= $self->_build_layout_base_dir
}
sub layout_perl {
  $self->{layout_perl} //= $self->_build_layout_perl
}

sub _build_layout_base_dir {
  my @parts = $fs->splitdir(Cwd::realpath(Cwd::getcwd()));
  my $cand;
  my $reason = '';
  while (@parts > 1) { # go back to one step before root at most
    $cand = $fs->catdir(@parts);
    return $cand if -d $fs->catdir($cand, '.plx');
    if (-d $fs->catdir($cand, '.git')) { # don't escape current repository
      $reason = ' due to .git directory';
      last;
    }
    pop @parts;
  }
  barf "Couldn't find .plx directory (stopped searching at ${cand}${reason})";
}

sub _build_layout_perl {
  my $perl_bin = $self->read_config_entry('perl');
  unless ($perl_bin) {
    my $perl_spec = $self->read_config_entry('perl.spec');
    barf "No perl and no perl.spec in config" unless $perl_spec;
    $self->run_config_perl_set($perl_spec);
    $perl_bin = $self->read_config_entry('perl');
    barf "Rehydration of perl from perl.spec failed" unless $perl_bin;
  }
  barf "perl binary ${perl_bin} not executable" unless -x $perl_bin;
  return $perl_bin;
}

sub layout_libspec_config {
  [ grep $_->[1],
      map [ $_, $self->read_config_entry([ libspec => $_ ]) ],
        $self->list_config_names('libspec') ];
}

sub layout_lib_specs {
  my $base_dir = $self->layout_base_dir;
  local *_ = sub { Cwd::realpath($fs->rel2abs(shift, $base_dir)) };
  [ map [ ($_->[0] =~ /\.([^.]+)$/), _($_->[1]) ],
      @{$self->layout_libspec_config} ];
}

sub layout_file {
  my ($self, @path) = @_;
  $fs->catfile($self->layout_base_dir, @path);
}

sub layout_dir {
  my ($self, @path) = @_;
  $fs->catdir($self->layout_base_dir, @path);
}

sub ensure_layout_config_dir {
  barf ".plx directory does not exist"
    unless -d $self->layout_dir('.plx');
  my $format = $self->read_config_entry('format');
  barf ".plx directory has no format specifier" unless $format;
  barf ".plx format ${format} unknown" unless $format eq '1';
}

sub layout_config_file { shift->layout_file('.plx', @_) }
sub layout_config_dir { shift->layout_dir('.plx', @_) }

sub write_config_entry {
  my ($self, $path, $value) = @_;
  my $file = $self->layout_config_file(ref($path) ? @$path : $path);
  open my $wfh, '>', $file or die "Couldn't open ${file}: $!";
  print $wfh "${value}\n";
}

sub clear_config_entry {
  my ($self, $path) = @_;
  my $file = $self->layout_config_file(ref($path) ? @$path : $path);
  unlink($file) or barf "Failed to unlink ${file}: $!" if -e $file;
}

sub read_config_entry {
  my ($self, $path) = @_;
  my $file = $self->layout_config_file(ref($path) ? @$path : $path);
  return undef unless -f $file;
  open my $rfh, '<', $file or die "Couldn't open ${file}: $!";
  chomp(my $value = <$rfh>);
  return $value;
}

sub list_config_names {
  my ($self, $path) = @_;
  my $dir = $self->layout_config_dir(ref($path) ? @$path : $path);
  return () unless -d $dir;
  opendir my($dh), $dir or die "Couldn't opendir ${dir}: $!";
  return grep -f $fs->catfile($dir, $_), sort readdir($dh);
}

sub slurp_command {
  my ($self, @cmd) = @_;
  open my $slurp_fh, '-|', @cmd
    or barf "Failed to start command (".join(' ', @cmd)."): $!";
  chomp(my @slurp = <$slurp_fh>);
  return @slurp;
}

sub prepend_env {
  my ($self, $env, @parts) = @_;
  $ENV{$env} = join(':', @parts, $ENV{$env}||());
}

sub setup_env_for_ll {
  my ($self, $path) = @_;
  local::lib->import($path);
}

sub setup_env_for_dir {
  my ($self, $path) = @_;
  $self->prepend_env(PERL5LIB => $path);
}

sub setup_env {
  my ($site_libs) = $self->slurp_command(
    $self->layout_perl, '-MConfig', '-e',
      'print join(",", @Config{qw(sitearch sitelibexp)})'
  );
  $ENV{PERL5OPT} = '-M-lib='.$site_libs;
  $ENV{$_} = $self->read_config_entry([ env => $_ ])
    for $self->list_config_names('env');
  my $perl_dirname = File::Basename::dirname($self->layout_perl);
  our %orig_env;
  unless (grep $_ eq $perl_dirname, split ':', $orig_env{PATH}) {
    $self->prepend_env(PATH => $perl_dirname);
  }
  foreach my $lib_spec (@{$self->layout_lib_specs}) {
    my ($type, $path) = @$lib_spec;
    next unless $path and -d $path;
    $self->${\"setup_env_for_${type}"}($path);
  }
  return;
}

sub cmd_search_path { qw(.plx/cmd dev bin) }

sub run_action_commands {
  my ($self, $filter) = @_;
  $self->ensure_layout_config_dir;
  my @commands;
  my %seen;
  foreach my $dirname ($self->cmd_search_path) {
    next unless -d (my $dir = $self->layout_dir($dirname));
    opendir my ($dh), $dir or barf "Couldn't open ${dir}: $!";
    foreach my $entry (sort readdir($dh)) {
      next if $entry =~ /^\.+$/;
      my $file = $self->layout_file($dirname, $entry);
      next unless -f $file;
      unless ($seen{$entry}++) {
        push @commands, [ $entry, "${dirname}/${entry}" ];
      }
    }
  }
  my $path = do { local $ENV{PATH} = ''; $self->setup_env; $ENV{PATH} };
  foreach my $dir (split ':', $path) {
    opendir my ($dh), $dir;
    foreach my $entry (sort readdir($dh)) {
      next if $entry =~ /^\.+$/;
      my $file = $fs->catfile($dir, $entry);
      next unless -x $file;
      push @commands, [ $entry, $file ] unless $seen{$entry}++;
    }
  }
  if ($filter) {
    my $match = $filter =~ m{^/(.+)/$} ? $1 : qr/^\Q${filter}/;
    @commands = grep { $_->[0] =~ $match } @commands;
  }
  my $max = List::Util::max(map length($_->[0]), @commands);
  my $base = $self->layout_base_dir;
  my $home = $ENV{HOME};
  foreach my $command (@commands) {
    my ($name, $path) = @$command;
    $path =~ s/^\Q${base}\///;
    $path =~ s/^\Q${home}/~/ if $home;
    say sprintf("%-${max}s  %s", $name, $path);
  }
}

sub run_action_bareinit {
  my ($self, $perl) = @_;
  my $dir = $fs->catdir($self->{layout_base_dir}||Cwd::getcwd(), '.plx');
  if (-d $dir) {
    if ($perl) {
      stderr <<END;
.plx already initialised - if you wanted to set the perl to ${perl} run:

  plx --config perl set ${perl}
END
    }
    return;
  }
  mkdir($dir) or barf "Couldn't create ${dir}: $!";
  $self->run_config_perl_set($perl||'perl');
  $self->write_config_entry(format => 1);
}

sub run_action_userinit {
  my ($self, @args) = @_;
  my @perl = (
    (@args and !ref($args[0]) and $args[0] ne '[')
      ? shift(@args)
      : ()
  );
  barf "--userinit requires \$HOME to be set" unless $ENV{HOME};
  $self->run_action_base(
    $ENV{HOME},
    '--multi' =>
      [ '--bareinit', @perl ],
      [ qw(--config libspec add 25.perl5.ll perl5) ],
      (@args ? [ '--multi', @args ] : ()),
  );
}

sub run_action_userstrap {
  my ($self, @args) = @_;
  my @perl = (
    (@args and !ref($args[0]) and $args[0] ne '[')
      ? shift(@args)
      : ()
  );
  $self->run_action_userinit(
    @perl,
    [ '--installself' ],
    [ '--installenv' ],
    @args
  );
}

sub run_action_installself {
  my $last_ll;
  foreach my $lib_spec (@{$self->layout_lib_specs}) {
    my ($type, $path) = @$lib_spec;
    $last_ll = $path if $type eq 'll';
  }
  barf "No local::lib in libspec config" unless $last_ll;
  $self->run_action_cpanm(
    "-l${last_ll}", '-n',
    qw(App::cpanminus App::plx)
  );
}

sub run_action_installenv {
  $self->ensure_layout_config_dir;
  barf "--installenv action currently assumes bash"
    unless $ENV{SHELL} =~ /bash/;
  barf "Couldn't find .bashrc"
    unless -f (my $bashrc = $fs->catfile($ENV{HOME}, ".bashrc"));
  my $plx_bin = do {
    local %ENV = our %orig_env;
    File::Which::which('plx-packed');
  } || do {
    local %ENV = %ENV;
    $self->setup_env;
    File::Which::which('plx-packed');
  };
  barf "Couldn't find plx in PATH" unless $plx_bin;
  {
    open my $fh, '<', $bashrc or die "Couldn't open ${bashrc} to read: $!";
    if (my ($line) = grep /plx --env/, <$fh>) {
      chomp($line);
      stderr("Found line in .bashrc: $line");
    }
  }
  my $base = $self->layout_base_dir;
  stderr("Appending to .bashrc");
  open my $fh, '>>', $bashrc or die "Couldn't open ${bashrc} to append: $!";
  print $fh "\neval \$(${plx_bin} --base ${base} --env)\n";
}

sub run_action_init {
  my ($self, $perl) = @_;
  $self->run_action_bareinit($perl);
  my $libspec_dir = $self->layout_config_dir('libspec');
  mkdir($libspec_dir) or barf "Couldn't create ${libspec_dir}: $!";
  $self->run_config_libspec_add(@$_) for (
    [ '25-local.ll' => 'local' ],
    [ '50-devel.ll' => 'devel' ],
    [ '75-lib.dir' => 'lib' ],
  );
}

sub _which {
  my ($self, $cmd, @args) = @_;
  $self->ensure_layout_config_dir;
  barf "--cmd <cmd> <args>" unless $cmd;

  if ($fs->file_name_is_absolute($cmd)) {
    return (exec => $cmd => @args);
  }

  if ($cmd eq 'perl') {
    return (perl => @args);
  }

  if ($cmd =~ m{/}) {
    return (perl => $cmd, @args);
  }

  if ($cmd =~ /^-/) {
    my @optargs = ($cmd, @args);
    foreach my $optarg (@optargs) {
      next if $optarg =~ /^-/;
      foreach my $dirname ($self->cmd_search_path) {
        if (-f (my $file = $self->layout_file($dirname => $optarg))) {
          $optarg = $file;
          last;
        }
      }
      last;
    }
    return (perl => @optargs);
  }

  foreach my $dirname ($self->cmd_search_path) {
    if (-f (my $file = $self->layout_file($dirname => $cmd))) {
      return (perl => $file, @args);
    }
  }

  return (exec => $cmd, @args);
}

sub run_action_which {
  my ($self, @args) = @_;
  my ($action, @call) = $self->_which(@args);
  say join(' ', 'plx', "--${action}", @call);
}

sub run_action_cmd {
  my ($self, @args) = @_;
  my ($action, @call) = $self->_which(@args);
  $self->${\"run_action_${action}"}(@call);
}

sub run_action_perl {
  my ($self, @call) = @_;
  $self->ensure_layout_config_dir;
  return $self->show_config_perl unless @call;
  $self->run_action_exec($self->layout_perl, @call);
}

sub run_action_exec {
  my ($self, @exec) = @_;
  $self->ensure_layout_config_dir;
  $self->setup_env;
  exec(@exec) or barf "exec of (".join(' ', @exec).") failed: $!";
}

sub find_cpanm {
  local %ENV = our %orig_env;
  barf "Couldn't find cpanm in \$PATH"
    unless my $cpanm = File::Which::which('cpanm');
  $cpanm;
}

sub run_action_cpanm {
  my ($self, @args) = @_;
  $self->ensure_layout_config_dir;
  my @cpanm = $self->find_cpanm;
  unless (@args and $args[0] =~ /^-[lL]/) {
    barf "--cpanm args must start with -l or -L to specify target local::lib";
  }
  $self->setup_env;
  system($self->layout_perl, @cpanm, @args);
}

sub run_action_config {
  my ($self, $config, @args) = @_;
  $self->ensure_layout_config_dir;
  unless ($config) {
    say "# perl";
    $self->show_config_perl;
    say "# libspec";
    $self->show_config_libspec;
    if ($self->list_config_names('env')) {
      say "# env";
      $self->show_config_env;
    }
    return;
  }
  barf "Unknown config key ${config}"
    unless my $show = $self->can("show_config_${config}");
  return $self->$show unless @args;
  if (my $code = $self->can("run_config_${config}")) {
    return $self->$code(@args);
  }
  my ($subcmd, @rest) = @args;
  barf "Invalid subcommand ${subcmd} for config key ${config}"
    unless my $code = $self->can("run_config_${config}_${subcmd}");
  return $self->$code(@rest);
}

sub show_config_perl { say $self->layout_perl }

sub resolve_perl_via_perlbrew {
  my ($self, $perl) = @_;
  stderr "Resolving perl '${perl}' via perlbrew";
  local %ENV = our %orig_env;
  barf "Couldn't find perlbrew in \$PATH"
    unless my $perlbrew = File::Which::which('perlbrew');
  my @list = $self->slurp_command($perlbrew, 'list');
  barf join(
    "\n", "No such perlbrew perl '${perl}', choose from:\n", @list, ''
  ) unless grep $_ eq $perl, map /(\S+)/, @list;
  my ($perl_path) = $self->slurp_command(
    $perlbrew, qw(exec --with), $perl, qw(perl -e), 'print $^X'
  );
  return $perl_path;
}

sub run_config_perl_set {
  my ($self, $new_perl) = @_;
  barf "plx --config perl set <perl>" unless $new_perl;
  my $perl_spec = $new_perl;
  unless ($new_perl =~ m{/}) {
    $new_perl = "perl${new_perl}" if $new_perl =~ /^5/;
    $new_perl =~ s/perl-5/perl5/; # perlbrew name to perl binary
    require File::Which;
    stderr "Resolving perl '${new_perl}' via PATH";
    if (my $resolved = File::Which::which($new_perl)) {
      $new_perl = $resolved;
    } else {
      $new_perl =~ s/^perl5/perl-5/; # perl binary to perlbrew name
      $new_perl = $self->resolve_perl_via_perlbrew($new_perl);
    }
  }
  barf "Not executable: $new_perl" unless -x $new_perl;
  $self->write_config_entry('perl.spec' => $perl_spec);
  $self->write_config_entry(perl => $new_perl);
}

sub show_config_libspec {
  my @ent = @{$self->layout_libspec_config};
  my $max = List::Util::max(map length($_->[0]), @ent);
  say sprintf("%-${max}s  %s", @$_) for @ent;
}

sub run_named_config_add {
  my ($self, $type, $name, $value) = @_;
  barf "plx --config ${type} add <name> <value>" unless $name and $value;
  unless (-d (my $dir = $self->layout_config_dir($type))) {
    mkdir($dir) or die "Couldn't make config dir ${dir}: $!";
  }
  $self->write_config_entry([ $type => $name ], $value);
}

sub run_named_config_del {
  my ($self, $type, $name) = @_;
  barf "plx --config ${type} dev <name>" unless $name;
  $self->clear_config_entry([ $type => $name ]);
}

sub run_config_libspec_add { shift->run_named_config_add(libspec => @_) }
sub run_config_libspec_del { shift->run_named_config_del(libspec => @_) }

sub show_config_env {
  my $max = List::Util::max(
    map length, my @names = $self->list_config_names('env')
  );
  say sprintf("%-${max}s  %s", $_, $self->read_config_entry([ env => $_ ]))
    for @names;
}

sub run_config_env_add { shift->run_named_config_add(env => @_) }
sub run_config_env_del { shift->run_named_config_del(env => @_) }

sub show_env {
  my ($self, $env) = @_;
  $self->ensure_layout_config_dir;
  local $ENV{$env} = '';
  $self->setup_env;
  say $_ for split ':', $ENV{$env};
}

sub run_action_libs { $self->show_env('PERL5LIB') }

sub run_action_paths { $self->show_env('PATH') }

sub run_action_env {
  $self->ensure_layout_config_dir;
  $self->setup_env;
  my @env_change;
  our %orig_env;
  foreach my $key (sort(keys %{{ %orig_env, %ENV }})) {
    my ($oval, $eval) = ($orig_env{$key}, $ENV{$key});
    if (!defined($eval) or ($oval//'') ne $eval) {
      push @env_change, [ $key, $eval ];
    }
  }
  my $shelltype = local::lib->guess_shelltype;
  my $shellbuild = "build_${shelltype}_env_declaration";
  foreach my $change (@env_change) {
    print +local::lib->$shellbuild(@$change);
  }
}

sub run_action_help {
  require Pod::Usage;
  Pod::Usage::pod2usage();
}

sub run_action_version {
  say sprintf "%f", $VERSION;
}

sub run_action_base {
  my ($self, $base, @chain) = @_;
  unless ($base) {
    say $self->layout_base_dir;
    return;
  }
  barf "--base <base> <action> <args>" unless @chain;
  $self->new({ layout_base_dir => $base })->run(@chain);
}

sub _parse_multi {
  my ($self, @args) = @_;
  my @multi;
  MULTI: while (@args) {
    barf "Expected multi arg [, got: $args[0]" unless $args[0] eq '[';
    shift @args;
    my @action;
    while (my $el = shift @args) {
      push @multi, \@action and next MULTI if $el eq ']';
      push @action, $el;
    }
    barf "Missing closing ] for multi";
  }
  return @multi;
}

sub run_action_multi {
  my ($self, @args) = @_;
  return $self->run_multi(@args) if @args and ref($args[0]);
  my @multi = $self->_parse_multi(@args);
  $self->run_multi(@multi);
}

sub run_multi {
  my ($self, @multi) = @_;
  foreach my $multi (@multi) {
    my @debug_multi = map +(ref($_) ? ('[', @$_, ']') : $_), @$multi;
    stderr '# '.join(' ', plx => @debug_multi);
    $self->run(@$multi);
  }
}

sub run_action_showmulti {
  my ($self, @args) = @_;
  my @multi = $self->_parse_multi(@args);
  say join(' ', plx => @$_) for @multi;
}

sub run {
  my ($self, $cmd, @args) = @_;
  $cmd ||= '--help';
  if ($cmd eq '[') {
    return $self->run_action_multi($cmd, @args);
  }
  if ($cmd =~ s/^--//) {
    if ($cmd) {
      my $method = join('_', 'run_action', split '-', $cmd);
      if (my $code = $self->can($method)) {
        return $self->$code(@args);
      }
      barf "No such action --${cmd}, see 'perldoc plx' for the full list";
    }
    $cmd = shift @args;
  }
  $self->ensure_layout_config_dir;
  return $self->run_action_cmd($cmd, @args);
}

caller() ? 1 : __PACKAGE__->new->run(@ARGV);

=head1 NAME

App::plx - Perl Layout Executor

=head1 SYNOPSIS

  plx --help                             # This output

  plx --init <perl>                      # Initialize layout config
  plx --perl                             # Show layout perl binary
  plx --libs                             # Show layout $PERL5LIB entries
  plx --paths                            # Show layout additional $PATH entries
  plx --env                              # Show layout env var changes
  plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH
 
  plx perl <args>                        # Run perl within layout
  plx -E '...'                           # (ditto)
  plx script-in-dev <args>               # Run dev/ script within layout
  plx script-in-bin <args>               # Run bin/ script within layout
  plx ./script <args>                    # Run script within layout
  plx script/in/cwd <args>               # (ditto)
  plx program <args>                     # Run program from layout $PATH

=head1 WHY PLX

While perl has many tools for configuring per-project development
environments, using them can still be a little on the lumpy side. With
L<Carton>, you find yourself running one of

  perl -Ilocal/lib/perl -Ilib bin/myapp
  carton exec perl -Ilib bin/myapp

With L<App::perlbrew>,

  perlbrew switch perl-5.28.0@libname
  perl -Ilib bin/myapp

With L<https://github.com/tokuhirom/plenv>,

  plenv exec perl -Ilib bin/myapp

and if you have more than one distinct layer of dependencies, while
L<local::lib> will happily handle that, integrating it with everything else
becomes a pain in the buttocks.

As a result of this, your not-so-humble author found himself regularly having
a miniature perl executor script at the root of git clones that looked
something like:

  #!/bin/sh
  eval $(perl -Mlocal::lib=--deactivate-all)
  export PERL5LIB=$PWD/local/lib/perl5
  bin=$1
  shift
  ~/perl5/perlbrew/perls/perl-5.28.0/bin/$bin "$@"

and then running:

  ./pl perl -Ilib bin/myapp

However, much like back in 2007 frustration with explaining to other
developers how to set up L<CPAN> to install into C<~/perl5> and how to
set up one's environment variables to then find the modules so installed
led to the exercise in rage driven development that first created
L<local::lib>, walking newbies through the creation and subsequent use of
such a script was not the most enjoyable experience for anybody involved.

Thus, the creation of this module to reduce the setup process to:

  cpanm App::plx
  cd MyProject
  plx --init 5.28.0
  plx --cpanm -llocal --notest --installdeps .

Follwed by being able to immediately (and even more concisely) run:

  plx myapp

which will execute C<perl -Ilib bin/myapp> with the correct C<perl> and the
relevant L<local::lib> already in scope.

If this seems of use to you, the L</QUICKSTART> is next and the L</ACTIONS>
section of this document lists the full capabilities of plx. Onwards!

=head1 QUICKSTART

Let's assume we're going to be working on Foo-Bar, so we start with:

  git clone git@github.com:arthur-nonymous/Foo-Bar.git
  cd Foo-Bar

Assuming the perl we'd get from running just C<perl> suffices, then we
next run:

  plx --init

If we want a different perl - say, we have a C<perl5.30.1> in our path, or
a C<perl-5.30.1> built in perlbrew, we'd instead run:

  plx --init 5.30.1

To quickly get our dependencies available, we then run:

  plx --cpanm -llocal --notest --installdeps .

If the project is designed to use L<Carton> and has a C<cpanfile.snapshot>,
instead we would run:

  plx --cpanm -ldevel --notest Carton
  plx carton install

If the goal is to test this against our current development version of another
library, then we'd also want to run:

  plx --config libspec add 40otherlib.dir ../Other-Lib/lib

If we want our ~/perl L<local::lib> available within the plx environment, we
can add that as the least significant libspec with:

  plx --config libspec add 00tilde.ll $HOME/perl5

At which point, we're ready to go, and can run:

  plx myapp              # to run bin/myapp
  plx t/foo.t            # to run one test file
  plx prove              # to run all t/*.t test files
  plx -E 'say for @INC'  # to run a one liner within the layout

To learn everything else plx is capable of, read on to the L</ACTIONS> section
coming next.

Have fun!

=head1 BOOTSTRAP

Under normal circumstances, one would run something like:

  cpanm App::plx

However, if you want a self-contained plx script without having a cpan
installer available, you can run:

  mkdir bin
  wget https://raw.githubusercontent.com/shadowcat-mst/plx/master/bin/plx-packed -O bin/plx

to get the current latest packed version.

The packed version bundled L<local::lib> and L<File::Which>, and also includes
a modified C<--cpanm> action that uses an inline C<App::cpanminus>.

=head1 ACTIONS

  plx --help                             # Print synopsis
  plx --version                          # Print plx version

  plx --init <perl>                      # Initialize layout config for .
  plx --bareinit <perl>                  # Initialize bare layout config for .
  plx --base                             # Show layout base dir 
  plx --base <base> <action> <args>      # Run action with specified base dir
  
  plx --perl                             # Show layout perl binary
  plx --libs                             # Show layout $PERL5LIB entries
  plx --paths                            # Show layout additional $PATH entries
  plx --env                              # Show layout env var changes
  plx --cpanm -llocal --installdeps .    # Run cpanm from outside $PATH

  plx --config perl                      # Show perl binary
  plx --config perl set /path/to/perl    # Select exact perl binary
  plx --config perl set perl-5.xx.y      # Select perl via $PATH or perlbrew

  plx --config libspec                   # Show lib specifications
  plx --config libspec add <name> <path> # Add lib specification
  plx --config libspec del <name> <path> # Delete lib specification
  
  plx --config env                       # Show additional env vars
  plx --config env add <name> <path>     # Add env var
  plx --config env del <name> <path>     # Delete env var

  plx --exec <cmd> <args>                # exec()s with env vars set
  plx --perl <args>                      # Run perl with args

  plx --cmd <cmd> <args>                 # DWIM command:
  
    cmd = perl           -> --perl <args>
    cmd = -<flag>        -> --perl -<flag> <args>
    cmd = some/file      -> --perl some/file <args>
    cmd = ./file         -> --perl ./file <args>
    cmd = name ->
      exists .plx/cmd/<name> -> --perl .plx/cmd/<name> <args>
      exists dev/<name>      -> --perl dev/<name> <args>
      exists bin/<name>      -> --perl bin/<name> <args>
      else                   -> --exec <name> <args>

  plx --which <cmd>                      # Expands --cmd <cmd> without running
  
  plx <something> <args>                 # Shorthand for plx --cmd
  
  plx --commands <filter>?               # List available commands
  
  plx --multi [ <cmd1> <args1> ] [ ... ] # Run multiple actions
  plx --showmulti [ ... ] [ ... ]        # Show multiple action running
  plx [ ... ] [ ... ]                    # Shorthand for plx --multi
  
  plx --userinit <perl>                  # Init ~/.plx with ~/perl5 ll
  plx --installself                      # Installs plx and cpanm into layout
  plx --installenv                       # Appends plx --env call to .bashrc
  plx --userstrap <perl>                 # userinit+installself+installenv

=head2 --help

Prints out the usage information (i.e. the L</SYNOPSIS>) for plx.

=head2 --init

  plx --init                     # resolve 'perl' in $PATH
  plx --init perl                # (ditto)
  plx --init 5.28.0              # looks for perl5.28.0 in $PATH
                                 # or perl-5.28.0 in perlbrew
  plx --init /path/to/some/perl  # uses the absolute path directly

Initializes the layout.

If a perl name is passed, attempts to resolve it via C<$PATH> and C<perlbrew>
and sets the result as the layout perl; if not looks for just C<perl>.

Creates the following libspec config:

  25-local.ll  local
  50-devel.ll  devel
  75-lib.dir   lib

=head2 --bareinit

Identical to C<--init> but creates no default configs except for C<perl>.

=head2 --base

  plx --base
  plx --base <base> <action> <args>

Without arguments, shows the selected base dir - C<plx> finds this by
checking for a C<.plx> directory in the current directory, and if not tries
the parent directory, recursively. The search stops either when C<plx> finds
a C<.git> directory, to avoid accidentally escaping a project repository, or
at the last directory before the root - i.e. C<plx> will test C</home> but
not C</>.

With arguments, specifies a base dir to use, and then invokes the rest of the
arguments with that base dir selected - so for example one can make a default
configuration in C<$HOME> available as C<plh> by running:

  plx --init $HOME
  alias plh='plx --base $HOME'

=head2 --libs

Prints the directories that will be added to C<PERL5LIB>, one per line.

These will include the C<lib/perl5> subdirectory for each C<ll> entry in the
libspecs, and the directory for each C<dir> entry.

=head2 --paths

Prints the directories that will be added to C<PATH>, one per line.

These will include the containing directory of the environment's perl binary
if not already in C<PATH>, followed by the C<bin> directories of any C<ll>
entries in the libspecs.

=head2 --env

Prints the changes that will be made to your environment variables, in a
syntax that is (hopefully) correct for your current shell.

=head2 --cpanm

  plx --cpanm -Llocal --installdeps .
  plx --cpanm -ldevel App::Ack

Finds the C<cpanm> binary in the C<PATH> that C<plx> was executed I<from>,
and executes it using the layout's perl binary and environment variables.

Requires the user to specify a L<local::lib> to install into via C<-l> or
C<-L> in order to avoid installing modules into unexpected places.

Note that this action exists primarily for bootstrapping, and if you want
to use a different installer such as L<App::cpm>, you'd install it with:

  plx --cpanm -ldevel App::cpm

and then subsequently run e.g.

  plx cpm install App::Ack

to install modules.

=head2 --exec

  plx --exec <command> <args>

Sets up the layout's environment variables and C<exec>s the command.

=head2 --perl

  plx --perl
  plx --perl <options> <script> <args>

Without arguments, sugar for C<--config perl>.

Otherwise, sets up the layout's environment variables and C<exec>s the
layout's perl with the given options and arguments.

=head2 --cmd

  plx --cmd <cmd> <args>
  
    cmd = perl           -> --perl <args>
    cmd = -<flag>        -> --perl -<flag> <args>
    cmd = some/file      -> --perl some/file <args>
    cmd = ./file         -> --perl ./file <args>
    cmd = name ->
      exists .plx/cmd/<name> -> --perl .plx/cmd/<name> <args>
      exists dev/<name>      -> --perl dev/<name> <args>
      exists bin/<name>      -> --perl bin/<name> <args>
      else                   -> --exec <name> <args>

B<Note>: Much like the C<devel> L<local::lib> is created to allow for the
installation of out-of-band dependencies that aren't going to be needed in
production, the C<dev> directory is supported to allow for the easy addition
of development time only sugar commands. Note that since C<perl> will re-exec
anything with a non-perl shebang, one can add wrappers here ala:

  $ cat dev/prove
  #!/bin/sh
  exec prove -j8 "$@"

=head2 --which

  plx --which <cmd>

Outputs the expanded form of a C<--cmd> invocation without running it.

=head2 --config

  plx --config                     # Show current config
  plx --config <name>              # Show current <name> config
  plx --config <name> <operation>  # Invoke config operation

=head3 perl

  plx --config perl
  plx --config perl set <spec>

If the spec passed to C<set> contains a C</> character, plx assumes that it's
an absolute bath and records it as-is.

If not, we go a-hunting.

First, if the spec begins with a C<5>, we replace it with C<perl5>.

Second, we search C<$PATH> for a binary of that name, and record it if so.

Third, if the (current) spec begins C<perl5>, we replace it with C<perl-5>.

Fourth, we search C<$PATH> for a C<perlbrew> binary, and ask it if it has a
perl named after the spec, and record that if so.

Fifth, we shrug and hope the user can come up with an absolute path next time.

B<Note:> The original spec passed to C<set> is recorded in C<.plx/perl.spec>,
so if you intend to share the C<.plx> directory across multiple machines via
version control or otherwise, remove/exclude the C<.plx/perl> file and plx
will automatically attempt to re-locate the perl on first invocation.

=head3 libspec

  plx --config libspec
  plx --config libspec add <name> <spec>
  plx --config libspec del <name> <spec>

A libspec config entry consists of a name and a spec, and the show output
prints them space separated one per line, with enough spaces to make the
specs align:

  25-local.ll  local
  50-devel.ll  devel
  75-lib.dir   lib

The part of the name before the last C<.> is not semantically significant to
plx, but is used for asciibetical sorting of the libspec entries to determine
in which order to apply them.

The part after must be either C<ll> for a L<local::lib>, or C<dir> for a bare
L<lib> directory.

When loaded, the spec is (if relative) resolved to an absolute path relative
to the layout root, then all C<..> entries and symlinks resolved to give a
final path used to set up the layout environment.

=head3 env

  plx --config env
  plx --config env add <name> <value>
  plx --config env del <name> <value>

Manages additional environment variables, which are set immediately before
any environment changes required for the current L</libspec> and L</perl>
settings are processed.

=head2 --commands

  plx --commands         # all commands
  plx --commands c       # all commands starting with c
  plx --commands /json/  # all commands matching /json/

Lists available commands, name first, then full path.

If a filter argument is given, treats it as a fixed prefix to filter the
command list, unless the filter is C</re/> in which case the slashes are
stripped and the filter is treated as a regexp.

=head2 --multi

  plx --multi [ --init ] [ --config perl set 5.28.0 ]

Runs multiple plx commands from a single invocation delimited by C<[ ... ]>.

=head2 --showmulti

  plx --showmulti [ --init ] [ --config perl set 5.28.0 ]

Outputs approximate plx invocations that would be run by C<--multi>.

=head2 --userinit

Same as C<--init> but assumes C<$HOME> as base and sets up only a single
libspec pointing at C<$HOME/perl5>.

=head2 --installself

Installs L<App::plx> and L<App::cpanminus> into the highest-numbered
L<local::lib> within the layout.

=head2 --installenv

(bash only currently)

Appends an eval line to set up the layout environment to the user's bashrc.

=head2 --userstrap

Convenience command for C<--userinit> plus C<--installself> plus
C<--installenv>.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the App::plx L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
