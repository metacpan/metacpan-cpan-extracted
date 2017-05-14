package App::p5stack;
# ABSTRACT: manage your dependencies and perl requirements locally

use strict;
use warnings;

use Cwd;
use File::Which;
use File::Basename;
use File::Spec::Functions;
use File::Path qw/make_path/;
use Path::Tiny;
use Archive::Tar;
use Data::Dumper;
use YAML;

sub new {
  my ($class, @argv) = @_;
  my $self = bless {}, $class;

  $self->{orig_argv} = [@argv];
  $self->{command} = @argv ? lc shift @argv : '';
  $self->{argv} = [@argv];

  # handle config
  $self->_do_config;

  return $self;
}

sub run {
  my ($self) = @_;

  if ($self->{command} eq 'setup') { $self->_do_setup; }
  elsif ($self->{command} eq 'perl') { $self->_do_perl; }
  elsif ($self->{command} eq 'cpanm') { $self->_do_cpanm; }
  elsif ($self->{command} eq 'bin') { $self->_do_bin; }
  elsif ($self->{command} eq 'run') { $self->_do_run; }
  else { $self->_do_help; }
}

sub _do_config {
  my ($self) = @_;

  # set some defaults
  $self->{perl} = 'system';
  $self->{deps} = 'dzil';
  $self->{skip_install} = 1;
  $self->{p5stack_root} = catfile($ENV{HOME},'.p5stack');
  $self->{perls_root} = catfile($ENV{HOME},'.p5stack','perls');
  $self->{perl_version} = '5.20.3';

  # guess stuff from context
  $self->{deps} = 'cpanfile' if -e 'cpanfile';

  # read config from file if available
  my $file;
  -e 'p5stack.yml' and $file = 'p5stack.yml';
  -e "$ENV{HOME}.p5stack/p5stack.yml" and $file = "$ENV{HOME}.p5stack/p5stack.yml";  # FIXME
  $ENV{P5STACKCFG} and $file = $ENV{P5STACKCFG};

  my $config;
  if ($file) {
    my $yaml = path($file)->slurp_utf8;
    $config = Load $yaml;
  }

  # FIXME re-factor after logic is more stable
  if ( file_name_is_absolute($config->{perl}) ) {
    $self->{perl_version} = _get_perl_version($config->{perl});
    $self->{perl} = $config->{perl};
  }
  if ( $self->{perl} eq 'system' ) {
    $self->{perl} = which 'perl';
    $self->{perl_version} = _get_perl_version($self->{perl});
  }
  if ( exists($config->{perl}) and $config->{perl} =~ m/^[\d\.]+$/ ) {
    $self->{perl_version} = $config->{perl};
    my $perl = catfile($self->{perls_root},$config->{perl},'bin','perl');
    $self->{perl} = $perl;

    $self->{skip_install} = 0 unless -e $perl;
  }
  for (qw/deps/) {
    $self->{$_} = $config->{$_} if exists $config->{$_};
  }

  # set more stuff
  $self->{home} = getcwd;
  $self->{local_lib} = catfile($self->{home},'.local',$self->{perl_version});
  $self->{local_bin} = catfile($self->{home},'.local',$self->{perl_version},'bin');
  $self->{Ilib} = catfile($self->{home},'.local',$self->{perl_version},'lib','perl5');
  $self->{log_file} = catfile($self->{p5stack_root},'p5stack-setup.log');
}

sub _do_setup {
  my ($self) = @_;

  make_path($self->{p5stack_root}) unless -e $self->{p5stack_root};

  _log('Hammering setup ...');
  _log("Tail ".catfile('$HOME','.p5stack','p5stack-setup.log')." to follow the process ...");

  $self->_do_install_perl_release;

  system "curl -s -L https://cpanmin.us | $self->{perl} - -l $self->{local_lib} --reinstall --no-sudo App::cpanminus local::lib > $self->{log_file} 2>&1";
  $self->{cpanm_flag} = $? >> 8;

  _log("Getting dependencies info using '$self->{deps}' ...");
  _log('Installing dependencies ...');
  my $cpanm = $self->_get_cpanm;

  if ($self->{deps} eq 'dzil') {

    unless (-e catfile($self->{home},'dist.ini')) {
      _log('Configuration is set to use "dzil" to gather dependencies information, but no "dist.ini" file was found in current directory.. exiting.');
      exit;
    }

    my $dzil = which 'dzil';
    if ($dzil) {
      system "$dzil listdeps | $cpanm --no-sudo -l $self->{local_lib}";
      $self->{cpanm_flag} = $? >> 8;
    }
    else {
      $self->_do_cpanm("Dist::Zilla");
      my $bin = catfile($self->{local_bin}, 'dzil');
      my @env = ("PERL5LIB=$self->{Ilib}", "PATH=$self->{local_bin}:\$PATH");
      system join(' ', @env, "$bin listdeps | $cpanm --no-sudo -l $self->{local_lib}");
      $self->{cpanm_flag} = $? >> 8;
     }
  }
  if ($self->{deps} eq 'cpanfile') {
    unless (-e catfile($self->{home},'cpanfile')) {
      _log('Configuration is set to use "cpanfile" to gather dependencies information, but no "cpanfile" file was found in current directory.. exiting.');
      exit;
    }
    $self->_do_cpanm("--installdeps .");
  }

  if ($self->{cpanm_flag}) {
    print "[p5stack] Warning, cpanm may have failed to install something!\n";
  }
  print "[p5stack] Setup done, use 'p5stack perl' to run your application.\n";
}

sub _get_cpanm {
  my ($self) = @_;

  my $cpanm = catfile($self->{local_lib}, 'bin', 'cpanm');
  $cpanm = which 'cpanm' unless $cpanm;  # FIXME default to system?

  return $cpanm;
}

sub _do_install_perl_release {
  my ($self) = @_;

  if (-e $self->{perl}) {
    _log("Found $self->{perl_version} release using it.");
    return;
  }

  my $curl = which 'curl';  # TODO failsafe to wget ?
  my $file = join '', 'perl-', $self->{perl_version}, '.tar.gz';
  my $dest = catfile($self->{perls_root}, $file);
  my $url = join '', 'http://www.cpan.org/src/5.0/', $file;

  _log("Downloading $self->{perl_version} release ...");
  make_path(dirname($dest)) unless -e dirname($dest);
  system "$curl -s -o $dest $url" unless -e $dest;

  my $curr = getcwd;
  chdir $self->{perls_root};

  _log("Extracting $self->{perl_version} release ...");
  Archive::Tar->extract_archive($file);

  chdir catfile($self->{perls_root}, "perl-$self->{perl_version}");
  
  _log("Configuring $self->{perl_version} release ...");
  my $prefix = catfile($self->{perls_root}, $self->{perl_version});
  system "sh Configure -de -Dprefix=$prefix > $self->{log_file} 2>&1";

  _log("Building $self->{perl_version} release ...");
  system "make >> $self->{log_file} 2>&1";

  _log("Testing $self->{perl_version} release ...");
  system "make test >> $self->{log_file} 2>&1";

  _log("Installing $self->{perl_version} release ...");
  system "make install >> $self->{log_file} 2>&1";

}

sub _do_perl {
  my ($self) = @_;

  my $run = join(' ',$self->{perl}, "-I $self->{Ilib}",
              "-Mlocal::lib", @{$self->{argv}});

  system $run;
}

sub _do_cpanm {
  my ($self, @args) = @_;
  @args = @{$self->{argv}} unless @args;

  my $cpanm = $self->_get_cpanm;
  my $log = "";
  $log = ">> $self->{log_file} 2>&1" if $self->{command} eq 'setup';
  my $run = join ' ', $cpanm, "--no-sudo", "-L $self->{local_lib}", @args, $log;

  system $run;
  $self->{cpanm_flag} = $? >> 8;
}

sub _do_bin {
  my ($self) = @_;

  my @argv = @{ $self->{argv} };
  my $bin = catfile($self->{local_bin}, shift @argv);
  my @env = ("PERL5LIB=$self->{Ilib}", "PATH=$self->{local_bin}:\$PATH");
  my $run = join ' ', @env, $bin, @argv;

  system $run;
}

sub _do_run {
  my ($self) = @_;

  my @argv = @{ $self->{argv} };
  my $comm = shift @argv;
  my @env = ("PERL5LIB=$self->{Ilib}", "PATH=$self->{local_bin}:\$PATH");
  my $run = join ' ', @env, $comm, @argv;

  system $run;
}

sub _get_perl_version {
  my ($perl) = @_;

  my $version = `$perl -e 'print \$^V'`;
  $version =~ s/^v//;

  return $version;
}

sub _log {
  my ($msg) = @_;

  # FIXME smaller timestamp
  my $now = localtime;
  $now =~ s/\s\d+$//;
  $now =~ s/^\w+/-/;

  print "[p5stack $now] $msg\n";
}

sub _do_help {
  print "Usage:\n",
    "  \$ p5stack setup                  # setup env in current directory\n",
    "  \$ p5stack perl <program> [args]  # run a program\n",
    "  \$ p5stack bin <file> [args]      # execute a locally installed bin file\n",
    "  \$ p5stack run <command> [args]   # setup env and run an arbitrary command\n",
    "  \$ p5stack cpanm [args]           # execute local env cpanm\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::p5stack - manage your dependencies and perl requirements locally

=head1 VERSION

version 0.004

=head1 SYNOPSIS

B<Warning>: this tool is still under development and badly tested, use
with care!

Manage your dependencies and perl requirements locally, by projects (directory).

    # set up configuration in your application directory
    $ cat > p5stack.yml
    ---
    perl: 5.20.3
    deps: dzil

    # setup the environment
    $ p5stack setup

    # run your application
    $ p5stack perl <application>

    # execute an installed program for this environment
    $ p5stack bin <program>

=head1 DESCRIPTION

p5stack is a tool that given a small set of configuration directives allows to
quickly (in a single command) setup the required modules inside a local directory
specific to this project. Including a specific perl version if required. This
allows to constrain all the required elements to run your application to live
inside the application directory. And thus not clashing to system wide perl
installations.

Configuration files are written in YAML, an example configuration looks
like:

    ---
    perl: 5.20.3
    deps: dzil

This tells p5stack that you want to use perl version 5.20.3, and to use
dzil to find the required modules for the application. By default all
perl versions are installed inside $HOME/.p5stack, and all the required
modules are install in a .local directory. This way you can share perl
releases installations, but have a local directory with the required
modules for each project.

After setting up the environment with the required perl and modules
using the I<setup> command:

    $ p5stack setup

You can run a command using the environment using:

    $ p5stack perl <program>

Or execute a program installed by a module using:

    $ p5stack bin <program>

You system perl and other possible installations remain unchanged.

The local installation of modules is done using 
L<App-cpanminus|http://search.cpan.org/dist/App-cpanminus/>
and L<local-lib|http://search.cpan.org/dist/local-lib/>.

=head1 EXAMPLES OF USE

=head2 Simple Example

Imagine a very simple project:

    $ ls -A
    dist.ini  ex1

which contains a script:

    $ cat ex1
    #!/usr/bin/perl
    
    use Acme::123;

    Acme::123->new->printnumbers;

that requires the Acme::123 module, as described in this simple dzil file:

    $ cat dist.ini 
    name = ex1

    [Prereqs]
    Acme::123 = 0

To setup the environment to run this using p5stack just run the tool with
the setup command:

    $ p5stack setup
    [p5stack - Sep 28 23:58:19] Hammering setup ...
    (...)

Since there is no configuration file for p5stack, by default the sytem perl
is used. And a directory I<.local> is created to install all the required
modules. The list of required dependencies is gathered using dzil by default
(or a cpanfile if available).

    $ ls -A
    .local  dist.ini  ex1

To run the simple application, just use the I<p5stack perl> command:

    $ p5stack perl ex1 
    one 
    two 
    three 
    (...)

=head2 Dancer Example

L<Dancer|http://perldancer.org> is a popular framework for building
site. Creating a new project using Dancer can be done as:

    $ dancer2 -a webapp
    + webapp
    (...)

This will create a directory called I<webapp> with a bunch of files
inside. One of these files is a I<cpanfile> that stores the required
modules to run the bootstrap application. To setup this new environment
to run the application just I<cd> into the new directory and run:

    $ cd webapp
    webapp$ p5stack setup

By default p5stack will use your system perl, and will use the cpanfile
to install in a I<.local> directory inside your application the required
dependencies to run the application.

You may require other perl version to use an application. You can write a
configuration file, and define what version you require. For example:

    $ cat > p5stack.yml
    ---
    perl = 5.22.0

You need to run the setup again to install the new perl version and
dependencies.
After the setup is done, a perl 5.22.0 has been install in I<$HOME/.p5stack>
and all the require modules have been installed in I<.local> inside your
project.

We can run the application using:

    webapp$ p5stack bin plackup bin/app.psgi 
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

=head1 COMMANDS

p5stack tool is executed using commands like:

    $ p5stack <command> [args]

Available commands for p5stack are:

=over 4

=item

C<setup>: build and setup the environment.

=item

C<perl>: run a perl interpreter.

=item

C<bin>: run a program installed by the setup in the environment.

=item

C<cpanm>: run I<cpanm> in the context of your application environment.

=item

C<help>: show small help info.

=back

=head1 CONFIGURATION

The currently available configuration attributes are:

=over 4

=item

C<perl> defines the required perl version to run the application (eg. 5.20.3,
5.22.0); you can also use an absolute path, or the special keyword I<system>
which will use the system wide perl found (using I<which>).

=item

C<deps> is used to define how to gather dependencies information, current
available options are:

=over 4

=item

C<dzil>: uses I<dzil listdeps> to find out the list of requirements.

=item

C<cpanfile>: I<cpanm> reads this file directly.

=back

=item

C<localperl> if set, the required perl is installed in .local inside your
directory project (not implemented yet).

=back

You can write the configuration in a C<pstack.yml> file in your project
directory, have a C<$HOME/.p5stack/p5stack.yml> configuration file,
or use the environment variable I<P5STACKCFG> to define where the configuration
file is.

=head1 FUTURE WORK

=over 4

=item

Allow other options to set up local lib (eg. carton, DX).

=item

More tests.

=back

=head1 ACKNOWLEDGMENTS

Thank you to the authors and contributors of
L<App-cpanminus|http://search.cpan.org/dist/App-cpanminus/>
and L<local-lib|http://search.cpan.org/dist/local-lib/>.

Inspired by L<The Haskell Tool Stack|https://github.com/commercialhaskell/stack>.

=head1 CONTRIBUTORS

Alberto Simões <ambs@cpan.org>

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
