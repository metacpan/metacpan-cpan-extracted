package App::Aphra::File;

use Moose;
use Carp;
use File::Basename;
use File::Path 'make_path';
use File::Copy;

has [qw[path name extension ]] => (
  isa => 'Str',
  is  => 'ro',
);

has app => (
  isa => 'App::Aphra',
  is  => 'ro',
);

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if (@_ == 1 and not ref $_[0]) {
    croak;
  }

  my %args = ref $_[0] ? %{$_[0]} : @_;

  croak "No app attribute\n" unless $args{app};
  if ($args{filename}) {
    debug("Got $args{filename}");
    my @exts = values %{ $args{app}->config->{extensions}};
    my ($name, $path, $ext) = fileparse($args{filename}, @exts);
    chop($path) if $name;
    chop($name) if $ext;
    @args{qw[path name extension]} = ($path, $name, $ext);
  }

  return $class->$orig(\%args);
};

sub is_template {
  my $self = shift;

  return scalar grep { $_ eq $self->extension }
    values %{$self->app->config->{extensions}};
}

sub destination_dir {
  my $self = shift;

  my $dir = $self->path;

  my $src = $self->app->config->{source};
  my $tgt = $self->app->config->{target};

  $dir =~ s/^$src/$tgt/;

  return $dir;
}

sub template_name {
  my $self = shift;

  my $src = $self->app->config->{source};
  my $template_name = $self->full_name;
  $template_name =~ s|^$src/||;

  return $template_name;
}

sub output_name {
  my $self = shift;

  my $output = $self->template_name;
  my $ext    = '\.' . $self->extension;
  $output =~ s/$ext$//;

  return $output;
}

sub full_name {
  my $self = shift;

  my $full_name = $self->path . '/' . $self->name;
  $full_name .= '.' . $self->extension if $self->extension;
  return $full_name;
}

sub process {
  my $self = shift;

  debug('File is: ', $self->full_name);

  my $dest = $self->destination_dir;
  debug("Dest: $dest");

  make_path $dest;

  if ($self->is_template) {
    debug("It's a template");

    my $template = $self->template_name;
    my $out      = $self->output_name;

    debug("tt: $template -> $out");
    $self->app->template->process($template, {}, $out)
      or croak $self->app->template->error;
  } else {
    my $file = $self->full_name;
    debug("Copy: $file -> ", $self->destination_dir);
    copy $file, $self->destination_dir;
  }
}

sub debug {
  carp @_ if $ENV{APHRA_DEBUG};
}

1;
