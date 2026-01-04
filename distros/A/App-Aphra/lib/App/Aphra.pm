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
use Path::Tiny;
use Getopt::Long;
use Carp;
use Clone 'clone';
use YAML::XS 'LoadFile';
use Sys::Hostname;
use URI;

use App::Aphra::File;

our $VERSION = '0.2.7';

has commands => (
  isa => 'HashRef',
  is => 'ro',
  default => sub { {
    build => \&build,
    serve => \&serve,
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
      tt => 'template',
      md => 'markdown',
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

has site_vars => (
  isa => 'HashRef',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_site_vars {
  my $self = shift;

  my $site_vars = {};

  if (-f 'site.yml') {
    $site_vars = LoadFile('site.yml');
  }

  return $site_vars;
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
  delete $exts->{tt};

  return Template->new(
    LOAD_TEMPLATES => [
      Template::Provider::Pandoc->new(
        INCLUDE_PATH       => $self->include_path,
        EXTENSIONS         => $exts,
        OUTPUT_FORMAT      => $self->config->{output},
        STRIP_FRONT_MATTER => 1,
      ),
    ],
    VARIABLES    => {
      site  => $self->site_vars,
      aphra => $self,
    },
    INCLUDE_PATH => $self->include_path,
    OUTPUT_PATH  => $self->config->{target},
    WRAPPER      => $self->config->{wrapper},
  );
}

has uri => (
  isa => 'URI',
  is  => 'ro',
  lazy_build => 1,
);

sub _build_uri {
  my $self = shift;

  return URI->new($self->site_vars->{uri}) if $self->site_vars->{uri};

  my $host = $self->site_vars->{host} || hostname;
  my $protocol = $self->site_vars->{protocol} || 'https';

  my $uri = "$protocol://$host";
  $uri .= ':' . $self->site_vars->{port} if $self->site_vars->{port};
  $uri .= '/';

  return URI->new($uri);
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

  if ($self->site_vars->{redirects}) {
    $self->make_redirects;
  }

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

sub make_redirects {
  my $self = shift;
  my $redirects = $self->site_vars->{redirects};

  return if !$redirects;
  return if !@$redirects;

  my $target = $self->config->{target};

  for (@$redirects) {
    my $from = $_->{from};
    $from .= 'index.html' if $from =~ m|/$|;

    my $to = $_->{to};

    my $outdir = path("$target$from")->dirname;
    path($outdir)->mkdir;

    open my $out_fh, '>', "$target$from"
      or die "Cannot open '$target$from' for writing: $!\n";

    print $out_fh <<EOF;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=$to">
  </head>
</html>
EOF

    close $out_fh;
  }
}

sub serve {
  my $self = shift;

  require App::HTTPThis;
  if ($@) {
    croak "App::HTTPThis must be installed for 'serve' command";
  }

  local @ARGV = $self->config->{target};
  App::HTTPThis->new->run;
}

has ver => (
  is => 'ro',
  default => $VERSION,
);

sub version {
  my $me = path($0)->basename;
  say "\n$me version: $VERSION\n";
}

sub help {
  my $self = shift;
  my $me = path($0)->basename;
  $self->version;

  say <<ENDOFHELP;
$me is a simple static sitebuilder which uses the Template Toolkit to
process input templates and turn them into a web site.
ENDOFHELP
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017-2024, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
