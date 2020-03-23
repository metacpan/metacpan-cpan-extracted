package App::git::ship::perl;
use Mojo::Base 'App::git::ship';

use Module::CPANfile;
use Mojo::File qw(path tempfile);
use Mojo::Util 'decode';
use POSIX qw(setlocale strftime LC_TIME);
use Pod::Markdown;

use constant DEBUG => $ENV{GIT_SHIP_DEBUG} || 0;

my $CONTRIB_END_RE        = qr{^=head1};
my $CONTRIB_NAME_EMAIL_RE = qr{^(\w[\w\s]*\w) - C<(.+)>$};
my $CONTRIB_NAME_RE       = qr{^(\w[\w\s]*\w)$};
my $CONTRIB_START_RE      = qr{^=head1 AUTHOR};
my $VERSION_RE            = qr{\W*\b(\d+\.[\d_]+)\b};

sub build {
  my $self = shift;

  $self->clean(0);
  $self->system(prove => split /\s/, $self->config('build_test_options'))
    if $self->config('build_test_options');
  $self->clean(0);
  $self->run_hook('before_build');
  $self->_render_makefile_pl if -e 'cpanfile';
  $self->_timestamp_to_changes;
  $self->_update_version_info;
  $self->_render_readme;
  $self->_make('manifest');
  $self->_make('dist', '-e');
  $self->run_hook('after_build');
  $self;
}

sub can_handle_project {
  my ($class, $file) = @_;
  return $file =~ /\.pm$/ ? 1 : 0 if $file;
  return path('lib')->list_tree->grep(sub {/\.pm$/})->size;
}

sub clean {
  my $self  = shift;
  my $all   = shift // 1;
  my @files = qw(Makefile Makefile.old MANIFEST MYMETA.json MYMETA.yml);

  unlink 'Makefile' and $self->_make('clean') if -e 'Makefile';

  push @files, qw(Changes.bak META.json META.yml) if $all;
  push @files, $self->_dist_files->each;

  for my $file (@files) {
    next unless -e $file;
    unlink $file or warn "!! rm $file: $!" and next;
    say "\$ rm $file" unless $self->SILENT;
  }

  return $self;
}

sub ship {
  my $self      = shift;
  my $dist_file = $self->_dist_files->[0];
  my $changelog = $self->config('changelog_filename');
  my $uploader;

  require CPAN::Uploader;
  $uploader = CPAN::Uploader->new(CPAN::Uploader->read_config_file);

  unless ($dist_file) {
    $self->build;
    $self->abort(
      "Project built. Run 'git ship' again to post dist to CPAN and remote repostitory.");
  }
  unless ($self->config('next_version')) {
    close ARGV;
    local @ARGV = $changelog;
    while (<>) {
      /^$VERSION_RE\s*/ or next;
      $self->config(next_version => $1);
      last;
    }
  }

  $self->run_hook('before_ship');
  $self->system(qw(git add Makefile.PL), $changelog);
  $self->system(qw(git add README.md)) if -e 'README.md';
  $self->system(qw(git commit -a -m), $self->_changes_to_commit_message);
  $self->SUPER::ship(@_);    # after all the changes
  $uploader->upload_file($dist_file);
  $self->run_hook('after_ship');
}

sub start {
  my $self      = shift;
  my $changelog = $self->config('changelog_filename');

  if (my $file = $_[0]) {
    $file = $file =~ m!^.?lib! ? path($file) : path(lib => $file);
    $self->config(main_module_path => $file);
    unless (-e $file) {
      my $work_dir = lc($self->config('project_name')) =~ s!::!-!gr;
      mkdir $work_dir;
      chdir $work_dir or $self->abort("Could not chdir to $work_dir");
      $self->config('main_module_path')->dirname->make_path;
      open my $MAINMODULE, '>>', $self->config('main_module_path')
        or $self->abort("Could not create %s", $self->config('main_module_path'));
    }
  }

  $self->SUPER::start(@_);
  $self->render_template('.travis.yml');
  $self->render_template('.perltidyrc', {template_from_home => 1});
  $self->render_template('cpanfile');
  $self->render_template('Changes') if $changelog eq 'Changes';
  $self->render_template('MANIFEST.SKIP');
  $self->render_template('t/00-basic.t');
  $self->system(qw(git add .perltidyrc .travis.yml cpanfile MANIFEST.SKIP t), $changelog);
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

  local $ENV{DEVEL_COVER_OPTIONS}   = $ENV{DEVEL_COVER_OPTIONS} || '+ignore,^t\b';
  local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
  $self->system(qw(cover -delete));
  $self->system(qw(prove -l));
  $self->system(qw(cover));
}

sub update {
  my $self = shift;

  $self->_render_makefile_pl if -e 'cpanfile';
  $self->_update_changes if $self->config('changelog_filename') eq 'Changes';
  $self->_render_readme;
  $self->render_template('t/00-basic.t', {force => 1});
  $self;
}

sub _build_config_param_changelog_filename {
  (grep {-w} qw(CHANGELOG.md Changes))[0] || 'Changes';
}

sub _build_config_param_contributors {
  my $self = shift;
  return decode 'UTF-8', $ENV{GIT_SHIP_CONTRIBUTORS} if $ENV{GIT_SHIP_CONTRIBUTORS};

  my @contributors;
  my $module = decode 'UTF-8', path($self->config('main_module_path'))->slurp;
  my $contrib_block;
  for my $line (split /\n/, $module) {
    if ($line =~ $CONTRIB_START_RE) {
      $contrib_block = 1;
      next;
    }
    $contrib_block = 0 if $line =~ $CONTRIB_END_RE;
    next unless $contrib_block;

    if ($line =~ $CONTRIB_NAME_EMAIL_RE) {
      push @contributors, "$1 <$2>";
    }
    elsif ($line =~ $CONTRIB_NAME_RE) {
      push @contributors, $1;
    }
  }

  return join ',', @contributors;
}

sub _build_config_param_new_version_format {
  return $ENV{GIT_SHIP_NEW_VERSION_FORMAT} || '%v %Y-%m-%dT%H:%M:%S%z';
}

sub _build_config_param_main_module_path {
  my $self = shift;
  return path($ENV{GIT_SHIP_MAIN_MODULE_PATH}) if $ENV{GIT_SHIP_MAIN_MODULE_PATH};

  my @project_name = split /-/, path->basename;
  my $path         = path 'lib';

PATH_PART:
  for my $p (@project_name) {
    opendir my $DH, $path or $self->abort("Cannot find project name from $path: $!");

    for (sort { length $b <=> length $a } readdir $DH) {
      my $f = "$_";
      s!\.pm$!!;
      next unless lc eq lc $p;
      $path = path $path, $f;
      last PATH_PART unless -d $path;
      next PATH_PART;
    }
  }

  return $path;
}

sub _build_config_param_project_name {
  my $self = shift;
  my @name = @{path($self->config('main_module_path'))};
  shift @name if $name[0] eq 'lib';
  $name[-1] =~ s!\.pm$!!;
  return join '::', @name;
}

sub _changes_to_commit_message {
  my $self      = shift;
  my $changelog = $self->config('changelog_filename');
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

sub _c_objects {
  my $self = shift;
  my @files;

  for my $d (qw(.)) {
    push @files,
      path($d)->list->grep(sub {/\.c|\.xs/})->map(sub { $_->basename('.c', '.xs') . '.o' })->each;
  }

  return @files;
}

sub _dist_files {
  my $self = shift;
  my $name = $self->config('project_name') =~ s!::!-!gr;

  return path->list->grep(sub {m!\b$name.*\.tar!i});
}

sub _exe_files {
  my $self = shift;
  my @files;

  for my $d (qw(bin script)) {
    push @files, path($d)->list->grep(sub {-x})->each;
  }

  return @files;
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
  my $prereqs = Module::CPANfile->load->prereqs;
  my $args    = {force => 1};
  my $r;

  $args->{PREREQ_PM}      = $prereqs->requirements_for(qw(runtime requires))->as_string_hash;
  $r                      = $prereqs->requirements_for(qw(build requires))->as_string_hash;
  $args->{BUILD_REQUIRES} = $r;
  $r                      = $prereqs->requirements_for(qw(test requires))->as_string_hash;
  $args->{TEST_REQUIRES}  = $r;
  $args->{CONTRIBUTORS}   = [split /,\s*/, $self->config('contributors')];

  $self->render_template('Makefile.PL', $args);
  $self->system(qw(perl -c Makefile.PL));    # test Makefile.PL
}

sub _render_readme {
  my $self = shift;
  my $skip;

  if (-e 'README.md') {
    my $re = "# NAME[\\n\\r\\s]+@{[$self->config('project_name')]}\\s-\\s";
    $skip = path('README.md')->slurp =~ m!$re! ? undef : 'Custom README.md is in place';
  }
  elsif (my @alternative = path->list->grep(sub {/^README/i})->each) {
    $skip = "@alternative exists.";
  }

  if ($skip) {
    say "# Will not generate README.md: $skip" unless $self->SILENT;
    return;
  }

  open my $README, '>:encoding(UTF-8)', 'README.md' or die "Write README.md: $!";
  my $parser = Pod::Markdown->new;
  $parser->output_fh($README);
  $parser->parse_string_document(path($self->config('main_module_path'))->slurp);
  say '# Generated README.md' unless $self->SILENT;
}

sub _timestamp_to_changes {
  my $self      = shift;
  my $changelog = $self->config('changelog_filename');
  my $loc       = setlocale(LC_TIME);
  my $release_line;

  $release_line = sub {
    my $v   = shift;
    my $str = $self->config('new_version_format');
    $str =~ s!(%-?\d*)v!{ sprintf "${1}s", $v }!e;
    setlocale LC_TIME, 'C';
    $str = strftime $str, localtime;
    setlocale LC_TIME, $loc;
    return $str;
  };

  local @ARGV = $changelog;
  local $^I   = '';
  while (<>) {
    $self->config(next_version => $1)
      if s/^$VERSION_RE\x20*(?:Not Released)?\x20*([\r\n]+)/{ $release_line->($1) . $2 }/e;
    print;    # print back to same file
  }

  say '# Building version ', $self->config('next_version') unless $self->SILENT;
  $self->abort('Unable to add timestamp to ./%s', $changelog) unless $self->config('next_version');
}

sub _update_changes {
  my $self = shift;

  unless (eval "require CPAN::Changes; 1") {
    say "# Cannot update './Changes' without CPAN::Changes. Install using 'cpanm CPAN::Changes'."
      unless $self->SILENT;
    return;
  }

  my $changes = CPAN::Changes->load('Changes');
  $changes->preamble(
    'Revision history for perl distribution ' . ($self->config('project_name') =~ s!::!-!gr));
  path('Changes')->spurt($changes->serialize);
  say "# Generated Changes" unless $self->SILENT;
}

sub _update_version_info {
  my $self    = shift;
  my $version = $self->config('next_version')
    or $self->abort('Internal error: Are you sure Changes has a timestamp?');

  local @ARGV = ($self->config('main_module_path'));
  local $^I   = '';
  my %r;
  while (<>) {
    $r{pod} ||= s/$VERSION_RE/$version/ if /^=head1 VERSION/ .. $r{pod} && /^=(cut|head1)/ || eof;
    $r{var} ||= s/((?:our)?\s*\$VERSION)\s*=.*/$1 = '$version';/;
    print;    # print back to same file
  }

  $self->abort('Could not update VERSION in %s', $self->config('main_module_path')) unless $r{var};
}

1;

=encoding utf8

=head1 NAME

App::git::ship::perl - Ship your Perl module

=head1 SYNOPSIS

  # Set up basic files for a Perl repo
  # (Not needed if you already have an existing repo)
  $ git ship start lib/My/Project.pm
  $ git ship start

  # Make changes
  $ $EDITOR lib/My/Project.pm

  # Build first if you want to investigate the changes
  $ git ship build

  # Ship the project to git (and CPAN)
  $ git ship ship

=head1 DESCRIPTION

L<App::git::ship::perl> is a module that can ship your Perl module. This tool
differs from other tools like dzil by *NOT* requiring any configuration, except
for a file containing the credentials for uploading to CPAN.

See also L<App::git::ship/DESCRIPTION>.

Example structure and how L<App::git::ship> works on your files:

=over 4

=item * my-app/cpanfile and my-app/Makefile.PL

The C<cpanfile> is used to build the "PREREQ_PM" and "BUILD_REQUIRES"
structures in the L<ExtUtils::MakeMaker> based C<Makefile.PL> build file.
The reason for this is that C<cpanfile> is a more powerful format that can
be used by L<Carton> and other tools, so generating C<cpanfile> from
Makefile.PL would simply not be possible. Other data used to generate
Makefile.PL are:

Note that the C<cpanfile> is optional and C<Makefile.PL> will be kept untouched
unless C<cpanfile> exists.

"NAME" and "LICENSE" will have values from L</GIT_SHIP_PROJECT_NAME> and
L<App::git::ship/GIT_SHIP_LICENSE>.  "AUTHOR" will have the name and email from
L<App::git::ship/GIT_SHIP_AUTHOR> or the last git committer.  "ABSTRACT_FROM" and
"VERSION_FROM" are fetched from the L<App::git::ship::perl/main_module_path>.
"EXE_FILES" will be the files in C<bin/> and C<script/> which are executable.
"META_MERGE" will use data from L<App::git::ship/GIT_SHIP_BUGTRACKER>, L<App::git::ship/GIT_SHIP_HOMEPAGE>,
and L</repository>.

=item * my-app/Changes or my-app/CHANGELOG.md

The Changes file will be updated with the correct
L</GIT_SHIP_NEW_VERSION_FORMAT>, from when you ran the L</build> action. The
Changes file will also be the source for L</GIT_SHIP_NEXT_VERSION>. Both
C<CHANGELOG.md> and C<Changes> are valid sources.  L<App::git::ship> looks for
a version-timestamp line with the case-sensitive text "Not Released" as the the
timestamp.

=item * my-app/lib/My/App.pm

This L<file|App::git::ship::perl/main_module_path> will be updated with the
version number from the Changes file.

=item * .gitignore and MANIFEST.SKIP

Unless these files exist, they will be generated from a template which skips
the most common files. The default content of these two files might change over
time if new temp files are created by new editors or some other formats come
along.

=item * t/00-basic.t

Unless this file exists, it will be created with a test for checking
that your modules can compile and that the POD is correct. The file can be
customized afterwards and will not be overwritten.

=item * .git

It is important to commit any uncommitted code to your git repository beforing
building and that you have a remote setup in your git repository before
shipping.

=item * .pause

You have to have a C<$HOME/.pause> file before shipping. It should look like this:

  user yourcpanusername
  password somethingsupersecret

=back

=head1 ENVIRONMENT VARIABLES

See L<App::git::ship/ENVIRONMENT VARIABLES> for more variables.

=head2 GIT_SHIP_BUILD_TEST_OPTIONS

This holds the arguments for the test program to use when building the
project. The default is to not automatically run the tests. Example value:

  GIT_SHIP_BUILD_TEST_OPTIONS="-l -j4"

=head2 GIT_SHIP_CHANGELOG_FILENAME

Defaults to either "CHANGELOG.md" or "Changes".

=head2 GIT_SHIP_MAIN_MODULE_PATH

Path to the main module in your project.

=head2 GIT_SHIP_NEXT_VERSION

Defaults to the version number in L</GIT_SHIP_MAIN_MODULE_PATH> + "0.01".

=head2 GIT_SHIP_NEW_VERSION_FORMAT

Use this to specify the version format in your "Changes" file.
The example below will result in "## 0.42 (2014-01-28)".

  GIT_SHIP_NEW_VERSION_FORMAT="\#\# %v (%F)"

"%v" will be replaced by the version, while the format arguments are passed
on to L<POSIX/strftime>.

The default is "%v %Y-%m-%dT%H:%M:%S%z".

=head1 METHODS

=head2 build

  $ git ship build

Used to build a Perl distribution by running through these steps:

=over 4

=item 1.

Call L</clean> to make sure the repository does not contain old build files.

=item 2.

Run L<prove|App::Prove> if L</GIT_SHIP_BUILD_TEST_OPTIONS> is set in L</config>.

=item 3.

Run "before_build" L<hook|App::git::ship/Hooks>.

=item 4.

Render Makefile.PL

=item 5.

Add timestamp to changes file.

=item 6.

Update version in main module file.

=item 7.

Make MANIFEST

=item 8.

Make dist file (Your-App-0.42.tar.gz)

=item 9.

Run "after_build" L<hook|App::git::ship/Hooks>.

=back

=head2 can_handle_project

See L<App::git::ship/can_handle_project>.

=head2 clean

  $ git ship clean

Used to clean out build files:

Makefile, Makefile.old, MANIFEST, MYMETA.json, MYMETA.yml, Changes.bak, META.json
and META.yml.

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

Used to create main module file template and generate C<.travis.yml>
C<cpanfile>, C<Changes>, C<MANIFEST.SKIP> and C<t/00-basic.t>.

=head2 test_coverage

  $ git ship test-coverage

Use L<Devel::Cover> to check test coverage for the distribution.

Set L<DEVEL_COVER_OPTIONS|https://metacpan.org/pod/Devel::Cover#OPTIONS> to
pass on options to L<Devel::Cover>. The default value will be set to:

  DEVEL_COVER_OPTIONS=+ignore,t

=head2 update

  $ git ship update

Action for updating the basic repo files.

=head1 SEE ALSO

L<App::git::ship>

=cut

__DATA__
@@ .gitignore
~$
*.bak
*.o
*.old
*.swp
/*.tar.gz
/blib/
/cover_db
/inc/
/local
/Makefile
/Makefile.old
/MANIFEST
/MANIFEST.bak
/META*
/MYMETA*
/pm_to_blib
@@ .perltidyrc
-pbp     # Start with Perl Best Practices
-w       # Show all warnings
-iob     # Ignore old breakpoints
-l=80    # 80 characters per line
-mbl=2   # No more than 2 blank lines
-i=2     # Indentation is 2 columns
-ci=2    # Continuation indentation is 2 columns
-vt=0    # Less vertical tightness
-pt=2    # High parenthesis tightness
-bt=2    # High brace tightness
-sbt=2   # High square bracket tightness
-wn      # Weld nested containers
-isbc    # Don't indent comments without leading space
@@ .travis.yml
# Enable Travis Continuous Integration at https://travis-ci.org
# Learn more https://docs.travis-ci.com
language: perl
sudo: false
perl:
  - "5.28"
  - "5.24"
  - "5.16"
  - "5.14"
  - "5.10"
install:
  - "cpanm -n Devel::Cover Test::Pod Test::Pod::Coverage"
  - "cpanm -n --installdeps --with-develop ."
after_success: "cover -test -report coveralls"
notifications:
  email: false
@@ cpanfile
# You can install this project with curl -L http://cpanmin.us | perl - <%= $ship->config('repository') =~ s!\.git$!!r %>/archive/master.tar.gz
requires "perl" => "5.10.0";
test_requires "Test::More" => "0.88";
@@ Changes
Revision history for perl distribution <%= $ship->config('project_name') =~ s!::!-!gr %>

0.01 Not Released
 - Started project
@@ Makefile.PL
# Generated by git-ship. See 'git-ship --man' for help or https://github.com/jhthorsen/app-git-ship
use utf8;
use ExtUtils::MakeMaker;
my %WriteMakefileArgs = (
  NAME           => '<%= $ship->config('project_name') %>',
  AUTHOR         => '<%= $ship->config('author') %>',
  LICENSE        => '<%= $ship->config('license') %>',
  ABSTRACT_FROM  => '<%= $ship->config('main_module_path') %>',
  VERSION_FROM   => '<%= $ship->config('main_module_path') %>',
  EXE_FILES      => [qw(<%= join ' ', $ship->_exe_files %>)],
  OBJECT         => '<%= join ' ', $ship->_c_objects %>',
  BUILD_REQUIRES => <%= $ship->dump($BUILD_REQUIRES) %>,
  TEST_REQUIRES  => <%= $ship->dump($TEST_REQUIRES) %>,
  PREREQ_PM      => <%= $ship->dump($PREREQ_PM) %>,
  META_MERGE     => {
    'dynamic_config' => 0,
    'meta-spec'      => {version => 2},
    'resources'      => {
      bugtracker => {web => '<%= $ship->config('bugtracker') %>'},
      homepage   => '<%= $ship->config('homepage') %>',
      repository => {
        type => 'git',
        url  => '<%= $ship->config('repository') %>',
        web  => '<%= $ship->config('homepage') %>',
      },
    },
    'x_contributors' => <%= $ship->dump($CONTRIBUTORS) %>,
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
@@ MANIFEST.SKIP
<%= $ship->_include_mskip_file %>
\.swp$
^local/
^MANIFEST\.SKIP
^README\.md
^README\.pod
^\.perltidyrc
^\.travis.yml
@@ t/00-basic.t
use strict;
use warnings;
use utf8;
## no critic (StringyEval)

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

my @files;
find(
  {
    wanted => sub { /\.pm$/ and push @files, $File::Find::name },
    no_chdir => 1
  },
  -e 'blib' ? 'blib' : 'lib',
);

plan tests => @files * 3 + <%= $ship->config('changelog_filename') eq 'Changes' ? 4 : 0 %>;

for my $file (@files) {
  my $module = $file; $module =~ s,\.pm$,,; $module =~ s,.*/?lib/,,; $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
  Test::Pod::Coverage::pod_coverage_ok($module, { also_private => [ qr/^[A-Z_]+$/ ], });
}

<%= $ship->config('changelog_filename') eq 'Changes' ? 'Test::CPAN::Changes::changes_file_ok();' : '' %>
