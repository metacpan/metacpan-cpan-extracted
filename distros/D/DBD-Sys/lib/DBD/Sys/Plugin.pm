package DBD::Sys::Plugin;

use strict;
use warnings;

=head1 NAME

DBD::Sys::Plugin - embed own tables to DBD::Sys

=head1 SYNOPSIS

This package is not intended to be used directly.

=head1 DESCRIPTION

DBD::Sys is developed to use a unique, well known interface (SQL) to access
data from underlying system which is available in tabular context (or
easily could transformed into).

The major goal of DBD::Sys is the ability to have an interface to collect
relevant data to operate a system - regardless the individual type. Therefore
it uses plugins to provide the accessible tables and can be extended by adding
plugins.

=head2 Plugin structure

Each plugin must be named C<DBD::Sys::Plugin::>I<Plugin-Name>. This package
can provide an external callable method named C<get_supported_tables> which
must return a hash containing the provided tables as key and the classes which
implement the tables as associated value, e.g.:

  package DBD::Sys::Plugin::Foo;

  use base qw(DBD::Sys::Plugin);

  sub get_supported_tables()
  {
      (
          mytable => 'DBD::Sys::Plugin::Foo::MyTable';
      )
  }

If the table is located in additional module, it must be required either by
the plugin package on loading or at least when it's returned by
C<get_supported_tables>.

If this method is not provided, the namespace below the plugin name will
be scanned for tables using L<Module::Pluggable::Object>:

  sub DBD::Sys::Plugin::get_supported_tables
  {
      my $proto = blessed($_[0]) || $_[0];
      my $finder = Module::Pluggable::Object->new(
						   require     => 1,
						   search_path => [$proto],
						   inner       => 0,
      );
      my @tableClasses = $finder->plugins();
      ...
  }

It's strongly recommended to derive the table classes from
L<DBD::Sys::Table>, but it's required that it is a
L<SQL::Eval::Table|SQL::Eval> and provides the C<get_col_names> and
C<collect_data> methods:

  package DBD::Sys::Plugin::Foo::MyTable;

  use base qw(DBD::Sys::Table);

  sub get_col_names() { qw(col1 col2 col3) }

  sub collect_data()
  {
      # ...

      return \@data;
  }

=cut

use vars qw($VERSION);

use Carp qw(croak);
use Module::Pluggable::Object;
use Scalar::Util qw(blessed);
use Params::Util qw(_ARRAY);

$VERSION = "0.102";

=pod

=head1 METHODS

=head2 get_supported_tables

This method is using L<Module::Pluggable::Object> to find all tables in
the namespace of the class derived from C<DBD::Sys::Plugin>. It's called
(once at initialization) in package context and returns a hash with the
supported tables as key and the according classes as value.

A plugin what knows it's tables might override this method and return a
static hash.

=cut

sub get_supported_tables
{
    my $self = $_[0];
    my $proto = blessed($self) || $self;
    my $finder = Module::Pluggable::Object->new(
                                                 require     => 1,
                                                 search_path => [$proto],
                                                 inner       => 0,
                                               );

    my %supportedTables;
    my @tblClasses = $finder->plugins();
    foreach my $tblClass (@tblClasses)
    {
        my $tblName;
        $tblClass->can('get_table_name') and $tblName = $tblClass->get_table_name();
        $tblName or ( ( $tblName = $tblClass ) =~ s/.*::(\p{Word}+)$/$1/ );
        exists $supportedTables{$tblName}
          and !defined( _ARRAY( $supportedTables{$tblName} ) )
          and $supportedTables{$tblName} = [ $supportedTables{$tblName} ];
        exists $supportedTables{$tblName} and push( @{ $supportedTables{$tblName} }, $tblClass );
        exists $supportedTables{$tblName} or $supportedTables{$tblName} = $tblClass;
    }

    return %supportedTables;
}

=head2 get_priority

This method returns the default priority of a plugin (and table): 1000.
See L<DBD::Sys::CompositeTable/new> for more information about priorities
of plugin and table classes.

=cut

sub get_priority { return 1000; }

=head1 AUTHOR

    Jens Rehsack
    CPAN ID: REHSACK
    rehsack@cpan.org
    http://search.cpan.org/~rehsack/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-Sys>. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;

