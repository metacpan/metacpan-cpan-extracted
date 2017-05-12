package DBD::Sys::PluginManager;

use strict;
use warnings;

=head1 NAME

DBD::Sys::Plugin - embed own tables to DBD::Sys

=head1 SYNOPSIS

    my $dbh = DBI->connect( "DBI:Sys:", undef, undef, {
	sys_pluginmgr_class => "DBD::Sys::PluginManager", }
    ) or die $DBI:errstr;

=cut

use vars qw($VERSION);

require DBD::Sys::Plugin;
require DBD::Sys::CompositeTable;

use Scalar::Util qw(weaken);
use Carp qw(croak);
use Params::Util qw(_HASH _ARRAY);
use Clone qw(clone);

use Module::Pluggable
  require     => 1,
  search_path => ['DBD::Sys::Plugin'],
  inner       => 0,
  only        => qr/^DBD::Sys::Plugin::\p{Word}+$/;

$VERSION = "0.102";

=head1 DESCRIPTION

The plugin manager provides a basic management of plugins to extend
DBD::Sys with additional tables. All plugins are expected to be directly
under the C<DBD::Sys::Plugin> namespace:

    use Module::Pluggable
      require     => 1,
      search_path => ['DBD::Sys::Plugin'],
      inner       => 0,
      only        => qr/^DBD::Sys::Plugin::\p{Word}+$/;

=head1 METHODS

=head2 new

Instantiates a new plugin manager and loads all plugins and available
tables. During the loading of all that modules, some internal dictionaries
are created to find the implementor classes for tables and all valid
attributes to tweak the data of the tables.

=cut

sub new
{
    my $class    = $_[0];
    my %instance = ();
    my $self     = bless( \%instance, $class );
    my @tableAttrs;

    foreach my $plugin ( $self->plugins() )
    {
        croak "Invalid plugin: $plugin" unless ( $plugin->isa('DBD::Sys::Plugin') );
        my %pluginTables = $plugin->get_supported_tables();
        foreach my $pluginTable ( keys %pluginTables )
        {
            my $pte = lc $pluginTable;
            my @pluginClasses =
              defined( _ARRAY( $pluginTables{$pluginTable} ) )
              ? @{ $pluginTables{$pluginTable} }
              : ( $pluginTables{$pluginTable} );

            if ( exists( $self->{tables2classes}->{$pte} ) )
            {
                defined( _ARRAY( $self->{tables2classes}->{$pte} ) )
                  or $self->{tables2classes}->{$pte} = [ $self->{tables2classes}->{$pte} ];

                push(
                      @{ $self->{tables2classes}->{$pte} },
                      defined( _ARRAY( $pluginTables{$pluginTable} ) )
                      ? @{ $pluginTables{$pluginTable} }
                      : $pluginTables{$pluginTable}
                    );
            }
            else
            {
                $self->{tables2classes}->{$pte} = $pluginTables{$pluginTable};
            }

            foreach my $pluginClass (@pluginClasses)
            {
                $pluginClass->can('get_attributes')
                  and push( @tableAttrs,
                            map { join( '_', 'sys', $pte, $_ ) } $pluginClass->get_attributes() );
            }
        }
    }

    $self->{tables_attrs} = \@tableAttrs;

    return $self;
}

=head2 get_table_list

Returns the list of the known table names. It's intended for internal use
only, so be aware that the API might change!

=cut

sub get_table_list
{
    return keys %{ $_[0]->{tables2classes} };
}

=head2 get_table_details

Returns a hash containing the table names and the table implementor
classes as value. It's intended for internal use only, so be aware
that the API might change!

=cut

sub get_table_details
{
    return %{ clone( $_[0]->{tables2classes} ) };
}

=head2 get_tables_attrs

Returns a C<< $dbh->{sys_valid_attrs} >> compatible hash map of valid
attributes of the loaded tables. It's intended for internal use only,
so be aware that the API might change!

=cut

sub get_tables_attrs
{
    my $self = $_[0];
    my %attrMap = map { $_ => 1 } @{ $self->{tables_attrs} };
    return \%attrMap;
}

=head2 get_table

Instantiates the appropriate table class for a given table name.
If multiple implementators for the specified table are known, a
L<DBD::Sys::CompositeTable> is instantiated which manages the
merging of the data delivered by each table and return one,
consolidated data set to the calling SQL engine. It's intended for
internal use only, so be aware that the API might change!

=cut

sub get_table
{
    my ( $self, $tableName, $attrs ) = @_;
    $tableName = lc $tableName;
    exists $self->{tables2classes}->{$tableName}
      or croak("Specified table '$tableName' not known");

    my $tableInfo = $self->{tables2classes}->{$tableName};
    my $table;
    if ( ref($tableInfo) )
    {
        $table = DBD::Sys::CompositeTable->new( $tableInfo, $attrs );
    }
    else
    {
        $table = $tableInfo->new($attrs);
    }

    return $table;
}

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
