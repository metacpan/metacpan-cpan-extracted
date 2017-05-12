package App::MyPerl::Role::Script;

use File::Spec;
use IO::All;
use Moo::Role;

my $ioify = sub {
  (defined($_[0]) and not ref($_[0]))
    ? io->dir($_[0])
    : $_[0]
};

requires 'run';

has env_prefix => (is => 'lazy', builder => sub { 'MYPERL' });

sub _env_value {
  my ($self, $name) = @_;
  $ENV{$self->env_prefix.'_'.$name};
}

has env_home => (is => 'lazy', builder => sub {
  shift->_env_value('HOME')
});

has env_config => (is => 'lazy', builder => sub {
  shift->_env_value('CONFIG')
});

has config_dir_name => (is => 'lazy', builder => sub { '.myperl' });

has global_config_dir => (is => 'lazy', coerce => $ioify, builder => sub {
  my ($self) = @_;
  if (my $env = $self->env_home) {
    io->dir($env)
  } elsif ($env = $ENV{HOME}) {
    io->dir($env)->catdir($self->config_dir_name)
  } else {
    undef
  }
});

has global_default_config_dir => (is => 'lazy', builder => sub {
  shift->global_config_dir->catdir('defaults')
});

has global_always_config_dir => (is => 'lazy', builder => sub {
  shift->global_config_dir->catdir('always')
});

has project_config_dir => (is => 'lazy', coerce => $ioify, builder => sub {
  my ($self) = @_;
  io->dir($self->env_config || $self->config_dir_name)
});

has final_project_config_dir => (is => 'lazy', builder => sub {
  my ($self) = @_;
  (grep defined && $_->is_executable,
    $self->project_config_dir, $self->global_default_config_dir)[0]
});

has config_dirs => (is => 'lazy', builder => sub {
  my ($self) = @_;
  [ grep defined && $_->is_executable,
      $self->global_always_config_dir, $self->final_project_config_dir ]
});

sub use_files { qw(dev-modules modules) }

sub _files_for {
  my ($self, $dir, $prefix) = @_;
  map $dir->catfile($prefix.$_), $self->use_files
}

sub _build_module_list {
  my ($self, $prefix) = @_;
  [ grep !/^#/ && !/^\s*$/,
      map $_->chomp->slurp,
        grep $_->exists,
          map $self->_files_for($_, $prefix),
              @{$self->config_dirs}
  ]
}

has modules => (is => 'lazy', builder => sub {
  $_[0]->_build_module_list('')
});

has script_modules => (is => 'lazy', builder => sub {
  $_[0]->_build_module_list('script-')
});

has preamble => (is => 'lazy', builder => sub {
  $_[0]->_preamble_from_modules(@{$_[0]->modules})
});

sub _preamble_from_modules {
  my ($self, @modules) = @_;
  [ map {
          my ($mod, $arg) = split('=', $_, 2);
          my $use_or_no = "use";
          if ($mod =~ /^-/) {
            $use_or_no = "no";
            $mod =~ s/^-//;
          }
          ($arg
                ? "$use_or_no ${mod} qw(".join(' ', split ',', $arg).");"
                : "$use_or_no ${mod};")
    } @modules
  ]
}

has perl_options => (is => 'lazy', builder => sub {
  my ($self) = @_;
  [
    "-Mlib::with::preamble=${\join(' ', @{$self->preamble})},lib,t/lib",
    (map "-M$_", @{$self->script_modules}, @{$self->modules})
  ];
});

sub run_if_script {
  return 1 if caller(1);
  shift->new->run;
}

1;
