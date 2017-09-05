=head1 NAME

App::Aphra - A simple static sitebuilder in Perl.

=head1 SYNOPSIS

    use App::Aphra;

    @ARGV = qw[build];

    my $app = App::Aphra->new;
    $app->run;

=head1 DESCRIPTION

For now, you probably want to look at the command-line program L<aphra>
which does all you want and is far better documented.

I'll improve this documentation in the future.

=cut

package App::Aphra;

use 5.014;

use Moose;
use Template;
use Template::Provider::Pandoc;
use FindBin '$Bin';
use File::Find;
use File::Basename;
use Getopt::Long;
use Carp;
use Clone 'clone';

use App::Aphra::File;

our $VERSION = '0.0.3';

has commands => (
  isa => 'HashRef',
  is => 'ro',
  default => sub { {
    build => \&build,
  } },
);

has config_defaults => (
  isa => 'HashRef',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_config_defaults {
  return {
    source     => 'in',
    fragments  => 'fragments',
    layouts    => 'layouts',
    wrapper    => 'page',
    target     => 'docs',
    extensions => {
      template => 'tt',
      markdown => 'md',
    },
    output     => 'html',
  };
}

has config => (
  isa => 'HashRef',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_config {
  my $self = shift;

  my %opts;
  GetOptions(\%opts,
             'source=s', 'fragments=s', 'layouts=s', 'wrapper=s',
             'target=s', 'extensions=s%', 'output=s',
             'version', 'help');

  for (qw[version help]) {
    $self->$_ and exit if $opts{$_};
  }

  my %defaults = %{ $self->config_defaults };

  my %config;
  for (keys %defaults) {
    $config{$_} = $opts{$_} // $defaults{$_};
  }
  return \%config;
}

has include_path => (
  isa => 'ArrayRef',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_include_path {
  my $self = shift;

  my $include_path;
  foreach (qw[source fragments layouts]) {
    push @$include_path, $self->config->{$_}
      if exists $self->config->{$_};
  }

  return $include_path;
}

has template => (
  isa => 'Template',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_template {
  my $self = shift;

  my $exts = clone $self->config->{extensions};
  delete $exts->{template};

  return Template->new(
    LOAD_TEMPLATES => [
      Template::Provider::Pandoc->new(
        INCLUDE_PATH  => $self->include_path,
        EXTENSIONS    => $exts,
        OUTPUT_FORMAT => $self->config->{output},
      ),
    ],
    INCLUDE_PATH => $self->include_path,
    OUTPUT_PATH  => $self->config->{target},
    WRAPPER      => $self->config->{wrapper},
  );
}

sub run {
  my $self = shift;

  $self->config;

  @ARGV or die "Must give a command\n";

  my $cmd = shift @ARGV;

  if (my $method = $self->commands->{$cmd}) {
    $self->$method;
  } else {
    die "$cmd is not a valid command\n";
  }
}

sub build {
  my $self = shift;

  my $src = $self->config->{source};

  -e $src or die "Cannot find $src\n";
  -d $src or die "$src is not a directory\n";

  find({ wanted => $self->_make_do_this, no_chdir => 1 },
       $self->config->{source});
}

sub _make_do_this {
  my $self = shift;

  return sub {
    return unless -f;

    my $f = App::Aphra::File->new({
      app => $self, filename => $_,
    });

    $f->process;
  };
}

sub version {
  my $me = basename $0;
  say "\n$me version: $VERSION\n";
}

sub help {
  my $self = shift;
  my $me = basename $0;
  $self->version;

  say <<ENDOFHELP;
$me is a simple static sitebuilder which uses the Template Toolkit to
process input templates and turn them into a web site.
ENDOFHELP
}


1;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
