use strict;
use warnings;

# because tests use open to open a string-ref, and I am not interested in ever
# supporting this module on ancient perls -- rjbs, 2007-12-17
use 5.008;

package App::Addex;
# ABSTRACT: generate mail tool configuration from an address book
$App::Addex::VERSION = '0.026';
use Carp ();

#pod =head1 DESCRIPTION
#pod
#pod B<Achtung!>  The API to this code may very well change.  It is almost certain
#pod to be broken into smaller pieces, to support alternate sources of entries, and
#pod it might just get plugins.
#pod
#pod This module iterates through all the entries in an address book and produces
#pod configuration file based on the entries in the address book, using configured
#pod output plugins.
#pod
#pod It is meant to be run with the F<addex> command, which is bundled as part of
#pod this software distribution.
#pod
#pod =method new
#pod
#pod   my $addex = App::Addex->new(\%arg);
#pod
#pod This method returns a new Addex.
#pod
#pod Valid parameters are:
#pod
#pod   classes    - a hashref of plugin/class pairs, described below
#pod
#pod Valid keys for the F<classes> parameter are:
#pod
#pod   addressbook - the App::Addex::AddressBook subclass to use (required)
#pod   output      - an array of output producers (required)
#pod
#pod For each class given, an entry in C<%arg> may be given, which will be used to
#pod initialize the plugin before use.
#pod
#pod =cut

# sub starting_section_name { 'classes' }
sub mvp_multivalue_args  { qw(output plugin) }

sub new {
  my ($class, $arg) = @_;

  my $self = bless {} => $class;

  # XXX: keep track of seen/unseen classes; carp if some go unused?
  # -- rjbs, 2007-04-06

  for my $core (qw(addressbook)) {
    my $class = $arg->{classes}{$core}
      or Carp::confess "no $core class provided";

    $self->{$core} = $self->_initialize_plugin($class, $arg->{$class});
  }

  my @output_classes = @{ $arg->{classes}{output} || [] }
    or Carp::confess "no output classes provided";

  my @output_plugins;
  for my $class (@output_classes) {
    push @output_plugins, $self->_initialize_plugin($class, $arg->{$class});
  }
  $self->{output} = \@output_plugins;

  my @plugin_classes = @{ $arg->{classes}{plugin} || [] };
  for my $class (@plugin_classes) {
    eval "require $class" or die;
    $class->import(%{ $arg->{$class} || {} });
  }

  return $self;
}

sub from_sequence {
  my ($class, $seq) = @_;

  my %arg;
  for my $section ($seq->sections) {
    $arg{ $section->name } = $section->payload;
  }

  $class->new(\%arg);
}

sub _initialize_plugin {
  my ($self, $class, $arg) = @_;
  $arg ||= {};
  $arg->{addex} = $self;

  # in most cases, this won't be needed, since the App::Addex::Config will have
  # loaded plugins as a side effect, but let's be cautious -- rjbs, 2007-05-10
  eval "require $class" or die;

  return $class->new($arg);
}

#pod =method addressbook
#pod
#pod   my $abook = $addex->addressbook;
#pod
#pod This method returns the App::Addex::AddressBook object.
#pod
#pod =cut

sub addressbook { $_[0]->{addressbook} }

#pod =method output_plugins
#pod
#pod This method returns all of the output plugin objects.
#pod
#pod =cut

sub output_plugins {
  my ($self) = @_;
  return @{ $self->{output} };
}

#pod =method entries
#pod
#pod This method returns all the entries to be processed.  By default it is
#pod delegated to the address book object.  This method may change a good bit in the
#pod future, as we really want an iterator, not just a list.
#pod
#pod =cut

sub entries {
  my ($self) = @_;
  return sort { $a->name cmp $b->name } $self->addressbook->entries;
}

#pod =method run
#pod
#pod   App::Addex->new({ ... })->run;
#pod
#pod This method performs all the work expected of an Addex: it iterates through the
#pod entries, invoking the output plugins for each one.
#pod
#pod =cut

sub run {
  my ($self) = @_;

  for my $entry ($self->entries) {
    for my $plugin ($self->output_plugins) {
      $plugin->process_entry($self, $entry);
    }
  }

  for my $plugin ($self->output_plugins) {
    $plugin->finalize;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex - generate mail tool configuration from an address book

=head1 VERSION

version 0.026

=head1 DESCRIPTION

B<Achtung!>  The API to this code may very well change.  It is almost certain
to be broken into smaller pieces, to support alternate sources of entries, and
it might just get plugins.

This module iterates through all the entries in an address book and produces
configuration file based on the entries in the address book, using configured
output plugins.

It is meant to be run with the F<addex> command, which is bundled as part of
this software distribution.

=head1 METHODS

=head2 new

  my $addex = App::Addex->new(\%arg);

This method returns a new Addex.

Valid parameters are:

  classes    - a hashref of plugin/class pairs, described below

Valid keys for the F<classes> parameter are:

  addressbook - the App::Addex::AddressBook subclass to use (required)
  output      - an array of output producers (required)

For each class given, an entry in C<%arg> may be given, which will be used to
initialize the plugin before use.

=head2 addressbook

  my $abook = $addex->addressbook;

This method returns the App::Addex::AddressBook object.

=head2 output_plugins

This method returns all of the output plugin objects.

=head2 entries

This method returns all the entries to be processed.  By default it is
delegated to the address book object.  This method may change a good bit in the
future, as we really want an iterator, not just a list.

=head2 run

  App::Addex->new({ ... })->run;

This method performs all the work expected of an Addex: it iterates through the
entries, invoking the output plugins for each one.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
