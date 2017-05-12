# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Config-MVP-BundleInspector
#
# This software is copyright (c) 2013 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Config::MVP::BundleInspector;
{
  $Config::MVP::BundleInspector::VERSION = '0.001';
}
# git description: 5002d73

BEGIN {
  $Config::MVP::BundleInspector::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Determine prereqs and INI string from PluginBundles

use Class::Load ();

use Moose;
use MooseX::AttributeShortcuts;
use MooseX::Types::Moose qw( Str ArrayRef HashRef );
use MooseX::Types::Perl qw( PackageName Identifier );
use namespace::autoclean;

# lots of lazy builders for subclasses


has bundle_class => (
  is         => 'ro',
  isa        => PackageName,
  required   => 1,
);


has bundle_method => (
  is         => 'lazy',
  isa        => Identifier,
);

sub _build_bundle_method {
  'mvp_bundle_config'
}


has bundle_name => (
  is         => 'lazy',
  isa        => Str,
);

sub _build_bundle_name {
  return $_[0]->bundle_class;
}


has plugin_specs => (
  is         => 'lazy',
  isa        => ArrayRef,
);

sub _build_plugin_specs {
  my ($self) = @_;
  my $class = $self->bundle_class;
  my $method = $self->bundle_method;

  Class::Load::load_class($class);

  return $self->_plugin_specs_from_bundle_method($class, $method);
}

sub _plugin_specs_from_bundle_method {
  my ($self, $class, $method) = @_;
  return [
    $class->$method({
      name    => $self->bundle_name,
      payload => {},
    })
  ];
}


has prereqs => (
  is         => 'lazy',
  isa        => 'CPAN::Meta::Requirements',
);

sub _build_prereqs {
  my ($self) = @_;

  require CPAN::Meta::Requirements;
  my $prereqs = CPAN::Meta::Requirements->new;
  foreach my $spec ( @{ $self->plugin_specs } ){
    my (undef, $class, $payload) = @$spec;
    $payload ||= {};
    $prereqs->add_minimum($class => $payload->{':version'} || 0)
  }

  return $prereqs;
}


has ini_string => (
  is         => 'lazy',
  isa        => Str,
);


has ini_opts => (
  is         => 'lazy',
  isa        => HashRef,
);

sub _build_ini_opts {
  return {};
}

sub _build_ini_string {
  my ($self) = @_;

  require Config::MVP::Writer::INI;
  my $string = Config::MVP::Writer::INI->new($self->ini_opts)
    ->ini_string($self->plugin_specs);

  return $string;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS INI PluginBundles cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

Config::MVP::BundleInspector - Determine prereqs and INI string from PluginBundles

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $inspector = Config::MVP::BundleInspector->new(
    bundle_class => 'SomeApp::PluginBundle::Stuff',
  );

  $inspector->prereqs;

=head1 DESCRIPTION

This module gathers info about the plugin specs from a L<Config::MVP> C<PluginBundle>.

=head1 ATTRIBUTES

=head2 bundle_class

The class to inspect.

=head2 bundle_method

The class method to call that returns the list of plugin specs.
Defaults to C<mvp_bundle_config>

=head2 bundle_name

Passed to the class method in a hashref as the C<name> value.
Defaults to L</bundle_class>.

=head2 plugin_specs

An arrayref of plugin specs returned from the L</bundle_class>.
A plugin spec is an array ref of:

  [ $name, $package, \%payload ]

=head2 prereqs

A L<CPAN::Meta::Requirements> object representing the prerequisites
as determined from the plugin specs.

=head2 ini_string

A string representing the bundle's contents in INI format.
Generated from the plugin specs by L<Config::MVP::Writer::INI>.

=head2 ini_opts

Options to pass to L<Config::MVP::Writer::INI>.
Defaults to an empty hashref.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Config::MVP::BundleInspector

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Config-MVP-BundleInspector>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-MVP-BundleInspector>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Config-MVP-BundleInspector>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Config-MVP-BundleInspector>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Config-MVP-BundleInspector>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Config::MVP::BundleInspector>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-config-mvp-bundleinspector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-MVP-BundleInspector>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Config-MVP-BundleInspector>

  git clone https://github.com/rwstauner/Config-MVP-BundleInspector.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
