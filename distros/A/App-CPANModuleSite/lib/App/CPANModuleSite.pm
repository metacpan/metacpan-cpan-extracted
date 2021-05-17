=head1 NAME

App::CPANModuleSite - Automatically create a web site for a CPAN module.

=head1 SYNOPSIS

    # From a command line
    $ mksite My::Lovely::Module

It's probably not particularly useful to use the class directly.

=cut

package App::CPANModuleSite;

our $VERSION = '0.0.9';

use v5.14;

use MetaCPAN::Client;
use Template;
use Path::Iterator::Rule;
use File::Copy;
use Moose;
use Moose::Util::TypeConstraints;
use File::ShareDir 'dist_dir';

subtype 'App::CPANModuleSite::Str',
  as 'Str';

coerce 'MetaCPAN::Client::Distribution',
  from 'App::CPANModuleSite::Str',
  via {
    MetaCPAN::Client->new->distribution($_);
  };

has distribution => (
  is => 'ro',
  isa => 'MetaCPAN::Client::Distribution',
  required => 1,
  coerce => 1,
);

has metacpan => (
  is => 'ro',
  isa => 'MetaCPAN::Client',
  lazy_build => 1,
);

sub _build_metacpan {
  return MetaCPAN::Client->new;
}

has release => (
  is => 'ro',
  isa => 'MetaCPAN::Client::Release',
  lazy_build => 1,
);

sub _build_release {
  my $self = shift;

  return $self->metacpan->release($self->distribution->name);
}

has modules => (
  is => 'ro',
  isa => 'ArrayRef[MetaCPAN::Client::Module]',
  lazy_build => 1,
);

sub _build_modules {
  my $self = shift;

  return [ map { $self->metacpan->module($_) } @{ $self->release->provides } ];
}

has tt => (
  is => 'ro',
  isa => 'Template',
  lazy_build => 1,
);

sub _build_tt {
  my $self = shift;

  return Template->new($self->tt_config);
}

has tt_config => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

sub _build_tt_config {
  my $self = shift;

  return {
    INCLUDE_PATH => $self->include_path,
    OUTPUT_PATH => $self->output_path,
    ( $self->wrapper ? ( WRAPPER => $self->wrapper ) : () ),
    RELATIVE => 1,
    VARIABLES => {
      distribution => $self->distribution,
      release => $self->release,
      modules => $self->modules,
      base => $self->base,
    },
  }
}

has [ qw[site_src local_site_src tt_lib local_tt_lib] ] => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_site_src {
  return dist_dir('App-CPANModuleSite') . '/site_src';
}

sub _build_local_site_src {
  return './site_src';
}

sub _build_tt_lib {
  return dist_dir('App-CPANModuleSite') . '/tt_lib';
}

sub _build_local_tt_lib {
  return './tt_lib';
}

has include_path => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy_build => 1,
);

sub _build_include_path {
  my $self = shift;

  return [
    $self->local_tt_lib,
    $self->local_site_src,
    $self->tt_lib,
    $self->site_src,
  ];
}

has output_path => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_output_path {
  return './docs';
}

has wrapper => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_wrapper {
  return 'page.tt';
}

has base => (
  is => 'ro',
  isa => 'Str',
  default => '',
);

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig( distribution => $_[0] );
  } else {
    return $class->$orig(@_);
  }
};

=head1 METHODS

=head2 run

The main driver method for the class. Does the following steps:

=over 4

=item * Creates a list of input files

=item * Uses Template Toolkit to process the templates

=item * Copies any non-template files into the output tree

=item * Creates a HTML version of the Pod from all the modules

=back

=cut

sub run {
  my $self = shift;

  my $finder = Path::Iterator::Rule->new->file;

  my @src_dirs = ($self->local_site_src, $self->site_src);
  my %src_files = map { $_ => 1 }
    $finder->all($self->site_src, { relative => 1 });

  for ( keys %src_files ) {
    if (/\.tt$/) {
      $self->process_template($_);
    } else {
      $self->copy_file($_);
    }
  }

  foreach (@{ $self->modules }) {
    my $outpath = $_->path =~ s/\.pm$/.html/r;
    my $pod = $_->pod('html');
    $self->tt->process(\$pod, undef, $outpath);
  }
}

sub process_template {
  my $self = shift;
  my ($template) = @_;

  my $output = $template =~ s/\.tt$//r;

  $self->tt->process($template, undef, $output)
    or die $self->tt->error;
}

sub copy_file {
  my $self = shift;
  my ($file) = @_;

  copy($file, $self->output_path . "/$file");
}

1;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

L<mksite>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
