package DBIO::Extension::List;
# ABSTRACT: The declared list of database extensions of a schema, resolved to classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Storable ();
use DBIO::Exception;
use DBIO::Util ();
use DBIO::Extension;

sub _frozen { local $Storable::canonical = 1; return Storable::nfreeze(\$_[0]) }


sub new {
  my ($class, %args) = @_;
  my $declaration = $args{declaration} || [];
  my $table       = $args{class_table};
  my $plain       = $args{plain_class};

  DBIO::Exception->throw('DBIO::Extension::List: declaration must be an array reference')
    unless ref $declaration eq 'ARRAY';

  my %entry;
  my @decl = @$declaration;
  while (@decl) {
    my $name = shift @decl;
    DBIO::Exception->throw(
      'Extension declaration: expected an extension name, got '
      . (ref $name ? 'a ' . ref($name) . ' reference' : defined $name ? "'$name'" : 'undef')
      . ' (options follow the name they belong to)'
    ) if !defined $name || ref $name;
    DBIO::Util::assert_identifier_text('Extension declaration: an extension name', $name);

    my %options;
    if (@decl && ref $decl[0]) {
      my $options = shift @decl;
      DBIO::Exception->throw("Extension '$name': the options must be a hash reference")
        unless ref $options eq 'HASH';
      %options = %$options;
    }

    DBIO::Util::assert_identifier_text("Extension '$name': option 'schema'", $options{schema})
      if exists $options{schema};

    my $explicit = delete $options{class};
    my ($resolved, $distribution) = defined $explicit ? ($explicit)
      : $table ? $table->($name) : ();
    $resolved //= $plain;
    DBIO::Exception->throw(
      "Extension '$name' is not known to the driver and no class is named for it "
      . "(declare it as $name => { class => 'My::Extension::Class' })"
    ) unless defined $resolved;

    if (my $have = $entry{$name}) {
      DBIO::Exception->throw(
        "Extension '$name' is declared with two classes: $have->{class} and $resolved"
      ) if $have->{class} ne $resolved;
      for my $key (sort keys %options) {
        next unless exists $have->{options}{$key};
        DBIO::Exception->throw(
          "Extension '$name' is declared with two values for option '$key'"
        ) if _frozen($have->{options}{$key}) ne _frozen($options{$key});
      }
      %{ $have->{options} } = (%{ $have->{options} }, %options);
      next;
    }

    $entry{$name} = {
      name    => $name,
      class   => $resolved,
      options => \%options,
      (defined $distribution ? (_distribution => $distribution) : ()),
    };
  }

  for my $name (sort keys %entry) {
    my $entry = $entry{$name};
    _load_class($name, $entry->{class}, delete $entry->{_distribution});
    DBIO::Extension->check_interface($entry->{class});
    my $states = $entry->{class}->name;
    DBIO::Exception->throw(
      "Extension '$name' is declared with class $entry->{class}, which is the extension '$states'"
    ) if defined $states && $states ne $name;
  }

  return bless { entries => \%entry }, $class;
}

sub _load_class {
  my ($name, $class, $distribution) = @_;
  DBIO::Util::assert_class_name($class);
  return if $class->can('extension_interface');

  (my $file = "$class.pm") =~ s{::}{/}g;
  return if $INC{$file};
  return if eval { require $file; 1 };

  my $error = $@;
  if ($error =~ /^Can't locate \Q$file\E in \@INC/) {
    DBIO::Exception->throw(
      "Extension '$name': class $class is not installed"
      . (defined $distribution ? " -- install the distribution $distribution" : '')
    );
  }
  DBIO::Exception->throw("Extension '$name': class $class does not load: $error");
}


sub entries {
  my ($self) = @_;
  return map { { %$_, options => { %{ $_->{options} } } } }
    map { $self->{entries}{$_} } sort keys %{ $self->{entries} };
}


sub names { sort keys %{ $_[0]{entries} } }


sub set_installed {
  my ($self, $state) = @_;
  for my $name (sort keys %$state) {
    my $entry = $self->{entries}{$name}
      or DBIO::Exception->throw("Extension '$name' is not in the declared list; its installed state is not attached");
    for my $key (qw(installed version schema)) {
      $entry->{$key} = $state->{$name}{$key} if exists $state->{$name}{$key};
    }
  }
  return $self;
}


sub check_driver {
  my ($self, $resolved) = @_;
  for my $name (sort keys %{ $self->{entries} }) {
    my $class    = $self->{entries}{$name}{class};
    my $asserted = $class->driver;
    next unless defined $asserted;
    next if $asserted eq $resolved;
    next if $resolved->can('isa') && $resolved->isa($asserted);
    DBIO::Exception->throw(
      "Extension '$name' ($class) belongs to the driver $asserted, "
      . "but the schema's driver is $resolved"
    );
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Extension::List - The declared list of database extensions of a schema, resolved to classes

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $list = DBIO::Extension::List->new(
    declaration => [ 'age', postgis => { schema => 'gis' }, 'citext' ],
    class_table => sub {
      my ($name) = @_;
      return ('DBIO::PostgreSQL::Age::Extension',     'DBIO-PostgreSQL-Age')     if $name eq 'age';
      return ('DBIO::PostgreSQL::PostGIS::Extension', 'DBIO-PostgreSQL-PostGIS') if $name eq 'postgis';
      return;
    },
    plain_class => 'DBIO::PostgreSQL::Extension',
  );

  my @entries = $list->entries;     # sorted by name
  $list->check_driver('DBIO::PostgreSQL');   # later, once the driver is resolved

=head1 DESCRIPTION

The list of ADR 0066 section 1: one entry per database extension the schema
declares, keyed by the engine's own name. The B<driver> builds it from the
declaration it spells (PostgreSQL: C<pg_extensions>) and hands core its
table of the family's extension classes; core knows no driver class.

The list is B<declared> state. It never determines the driver (ADR 0032
section 7), changes no C<@ISA> and registers nothing: it is data plus the
checks of ADR 0066 section 5.3. An entry is a hash reference

  { name => 'postgis', class => 'DBIO::PostgreSQL::PostGIS::Extension',
    options => { schema => 'gis' },
    # attached later, by set_installed:
    installed => 1, version => '3.4.2', schema => 'gis' }

=head1 METHODS

=head2 new

  my $list = DBIO::Extension::List->new(
    declaration => \@declaration,
    class_table => \&lookup,
    plain_class => $class,
  );

=over 4

=item C<declaration>

An array reference in the spelling of C<pg_extensions>: a name, optionally
followed by a hash reference of options. C<< class => $class >> among the
options names the extension class and wins over the table; it is not kept in
C<options>. A name declared twice merges its options; an option with two
different values, or two different classes, refuse.

=item C<class_table>

A code reference, called with the name. It returns the extension class of a
name the driver knows, optionally followed by the name of the distribution
that ships it (C<< ($class, $distribution) >>), or the empty list for a name
it does not know.

=item C<plain_class>

The driver's extension class without rules, used for a name neither the
declaration (C<class>) nor the table knows. Without it such a name refuses.

=back

Every class is loaded and its interface version checked
(L<DBIO::Extension/check_interface>) here, when the list is resolved. A class
that is not installed throws a L<DBIO::Exception> naming the distribution (when
the table gave one) or the class. A class whose C<name> differs from its
entry's name throws too.

=head2 entries

  my @entries = $list->entries;

The entries, sorted by C<name>, as copies. This is the order the rules of
every phase run in and the activation is composed in.

=head2 names

The names of the entries, sorted.

=head2 set_installed

  $list->set_installed({
    postgis => { installed => 1, version => '3.4.2', schema => 'gis' },
    age     => { installed => 0 },
  });

Attaches the installed state the driver read to the entries of the declared
names. The keys C<installed>, C<version> and C<schema> are kept. A name that is
not in the list throws: an extension that is installed but not declared is not
part of the list (ADR 0066 section 1.3). Returns the list.

=head2 check_driver

  $list->check_driver($resolved_driver);

The driver assertion of ADR 0066 section 1.3, called by the driver once the DSN
has decided the driver -- at the first use after driver resolution, never at
C<connect>. For every entry whose class states a C<driver> that is neither
C<$resolved_driver> nor a base class of it, throws a L<DBIO::Exception> naming
the extension, the asserted driver and the resolved one. A class that states no
driver asserts nothing. Returns true.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
