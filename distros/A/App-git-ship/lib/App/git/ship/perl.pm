package App::git::ship::perl;
use App::git::ship -base;
use Cwd ();
use File::Basename qw( dirname basename );
use File::Path 'make_path';
use File::Spec;
use Module::CPANfile;
use POSIX qw( setlocale strftime LC_TIME );

my $VERSION_RE = qr{\W*\b(\d+\.[\d_]+)\b};

my %FILENAMES = (changelog => [qw( CHANGELOG.md Changes )], readme => [qw( README.md README )],);

has main_module_path => sub {
  my $self = shift;
  return $self->config->{main_module_path} if $self->config->{main_module_path};

  my @path = split /-/, basename(Cwd::getcwd);
  my $path = 'lib';
  my @name;

PATH_PART:
  for my $p (@path) {
    opendir my $DH, $path or $self->abort("Cannot find project name from $path: $!");

    for my $f (readdir $DH) {
      $f =~ s/\.pm$//;
      next unless lc $f eq lc $p;
      push @name, $f;
      $path = File::Spec->catdir($path, $f);
      next PATH_PART;
    }
  }

  return "$path.pm";
};

has project_name => sub {
  my $self = shift;

  return $self->config->{project_name} if $self->config->{project_name};

  my @name = File::Spec->splitdir($self->main_module_path);
  shift @name if $name[0] eq 'lib';
  $name[-1] =~ s!\.pm$!!;
  join '::', @name;
};

has _cpanfile => sub { Module::CPANfile->load; };

sub build {
  my $self   = shift;
  my $readme = $self->_filename('readme');

  $self->clean(0);
  $self->system(prove => split /\s/, $self->config->{build_test_options})
    if $self->config->{build_test_options};
  $self->clean(0);
  $self->run_hook('before_build');
  $self->_render_makefile_pl;
  $self->_timestamp_to_changes;
  $self->_update_version_info;
  $self->system(sprintf '%s %s > %s', 'perldoc -tT', $self->main_module_path, $readme)
    if $readme eq 'README';
  $self->_make('manifest');
  $self->_make('dist');
  $self->run_hook('after_build');
  $self;
}

sub can_handle_project {
  my ($class, $file) = @_;
  my $can_handle_project = 0;

  if ($file) {
    return $file =~ /\.pm$/ ? 1 : 0;
  }
  if (-d 'lib') {
    File::Find::find(sub { $can_handle_project = 1 if /\.pm$/; }, 'lib');
  }

  return $can_handle_project;
}

sub clean {
  my $self  = shift;
  my $all   = shift // 1;
  my @files = qw( Makefile Makefile.old MANIFEST MYMETA.json MYMETA.yml );

  push @files, qw( Changes.bak META.json META.yml ) if $all;
  $self->_dist_files(sub { push @files, $_; });

  for my $file (@files) {
    next unless -e $file;
    unlink $file or warn "!! rm $file: $!" and next;
    say "\$ rm $file" unless $self->silent;
  }

  return $self;
}

sub exe_files {
  my $self = shift;
  my @files;

  for my $d (qw( bin script )) {
    opendir(my $BIN, $d) or next;
    push @files, map {"$d/$_"} grep { /^\w/ and -x File::Spec->catfile($d, $_) } readdir $BIN;
  }

  return @files;
}

sub ship {
  my $self      = shift;
  my $dist_file = $self->_dist_files(sub {1});
  my $changelog = $self->_filename('changelog');
  my $uploader;

  require CPAN::Uploader;
  $uploader = CPAN::Uploader->new(CPAN::Uploader->read_config_file);

  unless ($dist_file) {
    $self->build;
    $self->abort(
      "Project built. Run 'git ship' again to post dist to CPAN and remote repostitory.");
  }
  unless ($self->next_version) {
    close ARGV;
    local @ARGV = $changelog;
    while (<>) {
      /^$VERSION_RE\s*/ or next;
      $self->next_version($1);
      last;
    }
  }

  $self->run_hook('before_ship');
  $self->system(qw( git add Makefile.PL ), $changelog, $self->_filename('readme'));
  $self->system(qw( git commit -a -m ), $self->_changes_to_commit_message);
  $self->SUPER::ship(@_);    # after all the changes
  $uploader->upload_file($dist_file);
  $self->run_hook('after_ship');
  $self->clean;
}

sub start {
  my $self      = shift;
  my $changelog = $self->_filename('changelog');

  if (my $file = $_[0]) {
    $file = File::Spec->catfile(lib => $file) unless $file =~ m!^.?lib!;
    $self->config({})->main_module_path($file);
    unless (-e $file) {
      my $work_dir = lc($self->project_name) =~ s!::!-!gr;
      mkdir $work_dir;
      chdir $work_dir or $self->abort("Could not chdir to $work_dir");
      make_path dirname $self->main_module_path;
      open my $MAINMODULE, '>>', $self->main_module_path
        or $self->abort("Could not create %s", $self->main_module_path);
    }
  }

  symlink $self->main_module_path, 'README.pod' unless -e 'README.pod';

  $self->SUPER::start(@_);
  $self->render('cpanfile');
  $self->render('Changes') if $changelog eq 'Changes';
  $self->render('MANIFEST.SKIP');
  $self->render('t/00-basic.t');
  $self->system(qw(git add cpanfile MANIFEST.SKIP t), $changelog);
  $self->system(qw(git commit --amend -C HEAD --allow-empty)) if @_;
  $self;
}

sub test_coverage {
  my $self = shift;

  unless (eval 'require Devel::Cover; 1') {
    $self->abort(
      'Devel::Cover is not installed. Install it with curl -L http://cpanmin.us | perl - Devel::Cover'
    );
  }

  local $ENV{DEVEL_COVER_OPTIONS} = $ENV{DEVEL_COVER_OPTIONS} || '+ignore,^t\b';
  local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
  $self->system(qw( cover -delete ));
  $self->system(qw( prove -l ));
  $self->system(qw( cover ));
}

sub update {
  my $self    = shift;
  my $changes = $self->_filename('changelog');
  my $readme  = $self->_filename('readme');

  $self->abort("Cannot update with .git directory. Forgot to run 'git ship start'?")
    unless -d '.git';

  symlink $self->main_module_path, 'README.pod' unless -e 'README.pod';
  $self->_render_makefile_pl;
  $self->_update_changes if $changes eq 'Changes';
  $self->render('t/00-basic.t', {force => 1});
  $self->system(sprintf '%s %s > %s', 'perldoc -tT', $self->main_module_path, $readme)
    if $readme eq 'README';
  $self;
}

sub _author {
  my ($self, $format) = @_;

  open my $GIT, '-|', qw( git log ), "--format=$format"
    or $self->abort("git log --format=$format: $!");
  my $author = readline $GIT;
  $self->abort("Could not find any author in git log") unless $author;
  chomp $author;
  warn "[ship::author] $format = $author\n" if DEBUG;
  return $author;
}

sub _changes_to_commit_message {
  my $self      = shift;
  my $changelog = $self->_filename('changelog');
  my ($version, @message);

  close ARGV;    # reset <> iterator
  local @ARGV = $changelog;
  while (<>) {
    last if @message and /^$VERSION_RE\s+/;
    push @message, $_ if @message;
    push @message, $_ and $version = $1 if /^$VERSION_RE\s+/;
  }

  $self->abort("Could not find any changes in $changelog") unless @message;
  $message[0] =~ s!.*?\n!Released version $version\n\n!s;
  local $" = '';
  return "@message";
}

sub _dist_files {
  my ($self, $cb) = @_;
  my $name = lc($self->project_name) =~ s!::!-!gr;

  opendir(my $DH, Cwd::getcwd);
  while (readdir $DH) {
    next unless /^$name.*\.tar/i;
    return $_ if $self->$cb;
  }

  return undef;
}

sub _filename {
  opendir(my $DH, '');
  return (grep {-w} @{$FILENAMES{$_[1]}})[0] || $FILENAMES{$_[1]}->[-1];
}

sub _include_mskip_file {
  my ($self, $file) = @_;
  my @lines;

  $file ||= do { require ExtUtils::Manifest; $ExtUtils::Manifest::DEFAULT_MSKIP; };

  unless (-r $file) {
    warn "MANIFEST.SKIP included file '$file' not found - skipping\n";
    return '';
  }

  @lines = ("#!start included $file\n");
  local @ARGV = ($file);
  push @lines, $_ while <>;
  return join "", @lines, "#!end included $file\n";
}

sub _make {
  my ($self, @args) = @_;

  $self->_render_makefile_pl unless -e 'Makefile.PL';
  $self->system(perl => 'Makefile.PL') unless -e 'Makefile';
  $self->system(make => @args);
}

sub _render_makefile_pl {
  my $self    = shift;
  my $prereqs = $self->_cpanfile->prereqs;
  my $args    = {force => 1};

  $args->{PREREQ_PM} = $prereqs->requirements_for(qw( runtime requires ))->as_string_hash;

  for my $k (qw( build test )) {
    my $r = $prereqs->requirements_for($k, 'requires')->as_string_hash;
    $args->{BUILD_REQUIRES}{$_} = $r->{$_} for keys %$r;
  }

  $self->render('Makefile.PL', $args);
  $self->system(qw( perl -c Makefile.PL ));    # test Makefile.PL
}

sub _timestamp_to_changes {
  my $self      = shift;
  my $changelog = $self->_filename('changelog');
  my $loc       = setlocale(LC_TIME);
  my $release_line;

  $release_line = sub {
    my $v = shift;
    my $str = $self->config->{new_version_format} || '%v %Y-%m-%dT%H:%M:%S%z';
    $str =~ s!(%-?\d*)v!{ sprintf "${1}s", $v }!e;
    setlocale LC_TIME, 'C';
    $str = strftime $str, localtime;
    setlocale LC_TIME, $loc;
    return $str;
  };

  local @ARGV = $changelog;
  local $^I   = '';
  while (<>) {
    $self->next_version($1)
      if s/^$VERSION_RE\x20*(?:Not Released)?\x20*([\r\n]+)/{ $release_line->($1) . $2 }/e;
    print;    # print back to same file
  }

  say '# Building version ', $self->next_version unless $self->silent;
  $self->abort('Unable to add timestamp to ./%s', $changelog) unless $self->next_version;
}

sub _update_changes {
  my $self = shift;
  my $changes;

  unless (eval "require CPAN::Changes; 1") {
    say "# Cannot update './Changes' without CPAN::Changes. Install using cpanm CPAN::Changes"
      unless $self->silent;
    return;
  }

  $changes = CPAN::Changes->load('Changes');
  $changes->preamble(
    'Revision history for perl distribution ' . ($self->project_name =~ s!::!-!gr));
  open my $FH, '>', 'Changes' or $self->abort("Could not write CPAN::Changes to Changes: $!");
  print $FH $changes->serialize;
  say "# Generated Changes" unless $self->silent;
}

sub _update_version_info {
  my $self    = shift;
  my $version = $self->next_version
    or $self->abort('Internal error: Are you sure Changes has a timestamp?');
  my %r;

  local @ARGV = ($self->main_module_path);
  local $^I   = '';
  while (<>) {
    $r{pod} ||= s/$VERSION_RE/$version/ if /^=head1 VERSION/ .. $r{pod} && /^=(cut|head1)/ || eof;
    $r{var} ||= s/((?:our)?\s*\$VERSION)\s*=.*/$1 = '$version';/;
    print;    # print back to same file
  }

  $self->abort('Could not update VERSION in %s', $self->main_module_path) unless $r{var};
}

1;

=encoding utf8

=head1 NAME

App::git::ship::perl - Ship your Perl module

=head1 DESCRIPTION

L<App::git::ship::perl> is a module that can ship your Perl module.

See L<App::git::ship/SYNOPSIS>

=head1 ATTRIBUTES

=head2 main_module_path

  $str = $self->main_module_path;

Tries to guess the path to the main module in the repository. This is done by
looking at the repo name and try to find a file by that name. Example:

  ./my-cool-project/.git
  ./my-cool-project/lib/My/Cool/Project.pm

This guessing is case-insensitive.

Instead of guessing, you can put "main_module_path" in the config file.

=head2 project_name

  $str = $self->project_name;

Tries to figure out the project name from L</main_module_path> unless the
L</project_name> is specified in config file.

Example result: "My::Perl::Project".

=head1 METHODS

  $ git ship build

=head2 build

Used to build a Perl distribution by running through these steps:

=over 4

=item 1.

Call L</clean> to make sure the repository does not contain old build files.

=item 2.

Run L<prove|App::Prove> if C<build_test_options> is set in C<.ship.conf>.

=item 3.

Run "before_build" L<hook|App::git::ship/Hooks>.

=item 4.

Render Makefile.PL

=item 5.

Add timestamp to changes file.

=item 6.

Update version in main module file.

=item 7.

Update README with perldoc, unless another readfile file exists.

=item 8.

Make MANIFEST

=item 9.

Make dist file (Your-App-0.42.tar.gz)

=item 10.

Run "after_build" L<hook|App::git::ship/Hooks>.

=back

=head2 can_handle_project

See L<App::git::ship/can_handle_project>.

=head2 clean

  $ git ship clean

Used to clean out build files:

Makefile, Makefile.old, MANIFEST, MYMETA.json, MYMETA.yml, Changes.bak, META.json
and META.yml.

=head2 exe_files

  @files = $self->exe_files;

Returns a list of files in the "bin/" and "script/" directory that has the
executable flag set.

This method is used to build the C<EXE_FILES> list in C<Makefile.PL>.

=head2 ship

  $ git ship

Used to ship a Perl distribution by running through these steps:

=over 4

=item 1.

Find the dist file created by L</build> or abort if it could not be found.

=item 2.

Run "before_ship" L<hook|App::git::ship/Hooks>.

=item 3.

Add and commit the files changed in the L</build> step.

=item 4.

Use L<App::git::ship/next_version> to make a new tag and push all the changes
to the "origin" git repository.

=item 5.

Upload the dist file to CPAN.

=item 6.

Run "after_ship" L<hook|App::git::ship/Hooks>.

=back

=head2 start

  $ git ship start

Used to create main module file template and generate C<cpanfile>, C<Changes>,
C<MANIFEST.SKIP> and C<t/00-basic.t>.

=head2 test_coverage

Use L<Devel::Cover> to check test coverage for the distribution.

Set L<DEVEL_COVER_OPTIONS|https://metacpan.org/pod/Devel::Cover#OPTIONS> to
pass on options to L<Devel::Cover>. The default value will be set to:

  DEVEL_COVER_OPTIONS=+ignore,t

=head2 update

  $ git ship update

Action for updating the basic repo files.

=head1 SEE ALSO

L<App::git::ship>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

__DATA__
@@ .gitignore
~$
*.bak
*.old
*.swp
/blib/
/cover_db
/inc/
/local
/Makefile
/Makefile.old
/MANIFEST$
/MANIFEST.bak
/META*
/MYMETA*
/pm_to_blib
@@ cpanfile
# You can install this projct with curl -L http://cpanmin.us | perl - <%= $_[0]->repository =~ s!\.git$!!r %>/archive/master.tar.gz
requires "perl" => "5.10.0";
test_requires "Test::More" => "0.88";
@@ Changes
Revision history for perl distribution <%= $self->project_name =~ s!::!-!gr %>

0.01 Not Released
 - Started project
@@ Makefile.PL
# Generated by git-ship. See 'git-ship --man' for help or https://github.com/jhthorsen/app-git-ship
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => '<%= $_[0]->project_name %>',
  AUTHOR => '<%= $_[0]->_author('%an <%ae>') %>',
  LICENSE => '<%= $_[0]->config->{license} %>',
  ABSTRACT_FROM => '<%= $_[0]->main_module_path %>',
  VERSION_FROM => '<%= $_[0]->main_module_path %>',
  EXE_FILES => [qw( <%= join ' ', $_[0]->exe_files %> )],
  META_MERGE => {
    resources => {
      bugtracker => '<%= $_[0]->config->{bugtracker} %>',
      homepage => '<%= $_[0]->config->{homepage} %>',
      repository => '<%= $_[0]->repository %>',
    },
  },
  BUILD_REQUIRES => <%= $_[1]->{BUILD_REQUIRES} %>,
  PREREQ_PM => <%= $_[1]->{PREREQ_PM} %>,
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);
@@ MANIFEST.SKIP
<%= $_[0]->_include_mskip_file %>
\.swp$
^local/
^MANIFEST\.SKIP
^README\.pod
@@ t/00-basic.t
use Test::More;
use File::Find;

if(($ENV{HARNESS_PERL_SWITCHES} || '') =~ /Devel::Cover/) {
  plan skip_all => 'HARNESS_PERL_SWITCHES =~ /Devel::Cover/';
}
if(!eval 'use Test::Pod; 1') {
  *Test::Pod::pod_file_ok = sub { SKIP: { skip "pod_file_ok(@_) (Test::Pod is required)", 1 } };
}
if(!eval 'use Test::Pod::Coverage; 1') {
  *Test::Pod::Coverage::pod_coverage_ok = sub { SKIP: { skip "pod_coverage_ok(@_) (Test::Pod::Coverage is required)", 1 } };
}
if(!eval 'use Test::CPAN::Changes; 1') {
  *Test::CPAN::Changes::changes_file_ok = sub { SKIP: { skip "changes_ok(@_) (Test::CPAN::Changes is required)", 4 } };
}

find(
  {
    wanted => sub { /\.pm$/ and push @files, $File::Find::name },
    no_chdir => 1
  },
  -e 'blib' ? 'blib' : 'lib',
);

plan tests => @files * 3 + <%= $_[0]->_filename('changelog') eq 'Changes' ? 4 : 0 %>;

for my $file (@files) {
  my $module = $file; $module =~ s,\.pm$,,; $module =~ s,.*/?lib/,,; $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
  Test::Pod::Coverage::pod_coverage_ok($module, { also_private => [ qr/^[A-Z_]+$/ ], });
}

<%= $_[0]->_filename('changelog') eq 'Changes' ? 'Test::CPAN::Changes::changes_file_ok();' : '' %>
