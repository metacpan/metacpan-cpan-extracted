use DBI ();

package DBD::Sys;

use strict;
use vars qw(@ISA $VERSION $drh);
use base qw(DBI::DBD::SqlEngine);

$VERSION = "0.102";

$drh = undef;    # holds driver handle(s) once initialised

sub driver($;$)
{
    my ( $class, $attr ) = @_;

    $drh->{$class} and return $drh->{$class};

    $attr ||= {};
    {
        no strict "refs";
        $attr->{Version} ||= ${ $class . "::VERSION" };
        $attr->{Name} or ( $attr->{Name} = $class ) =~ s/^DBD\:\://;
        $attr->{Attribution} ||= 'DBD::Sys by Jens Rehsack';
    }

    $drh = $class->SUPER::driver($attr);
    return $drh;
}    # driver

sub CLONE
{
    undef $drh;
}    # CLONE

package DBD::Sys::dr;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA                         = qw(DBI::DBD::SqlEngine::dr);
$DBD::Sys::dr::imp_data_size = 0;

sub data_sources
{
    my ( $drh, $attr ) = @_;
    my (@list) = ();

    # You need more sophisticated code than this to set @list...
    push( @list, 'dbi:Sys:' );

    # End of code to set @list
    return @list;
}

package DBD::Sys::db;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

use Carp qw(croak);

require DBD::Sys::PluginManager;

@ISA                         = qw(DBI::DBD::SqlEngine::db);
$DBD::Sys::db::imp_data_size = 0;

sub set_versions
{
    my $dbh = shift;
    $dbh->{sys_version} = $DBD::Sys::VERSION;

    return $dbh->SUPER::set_versions();
}

sub init_valid_attributes
{
    my $dbh = shift;

    $dbh->{sys_valid_attrs} = {
                                sys_version         => 1,    # DBD::Sys version
                                sys_valid_attrs     => 1,    # DBD::Sys valid attributes
                                sys_readonly_attrs  => 1,    # DBD::Sys readonly attributes
                                sys_pluginmgr       => 1,    # DBD::Sys plugin-manager
                                sys_pluginmgr_class => 1,    # DBD::Sys plugin-manager class
                                sys_plugin_attrs    => 1,    # DBD::Sys plugin attributes
                              };
    $dbh->{sys_readonly_attrs} = {
                                   sys_version        => 1,     # DBD::File version
                                   sys_valid_attrs    => 1,     # File valid attributes
                                   sys_readonly_attrs => 1,     # File readonly attributes
                                   sys_pluginmgr      => 1,     # DBD::Sys plugin-manager
                                   sys_plugin_attrs   => 1,     # DBD::Sys plugin attributes
                                 };

    return $dbh;
}

sub _load_class
{
    my ( $load_class, $missing_ok ) = @_;
    no strict 'refs';
    return 1 if @{"$load_class\::ISA"};    # already loaded/exists
    ( my $module = $load_class ) =~ s!::!/!g;
    eval { require "$module.pm"; };
    return 1 unless $@;
    return 0 if $missing_ok && $@ =~ /^Can't locate \Q$module.pm\E/;
    croak $@;
}

sub init_default_attributes
{
    my $dbh = shift;

    # must be done first, because setting flags implicitly calls $dbdname::db->STORE
    $dbh->SUPER::init_default_attributes();

    $dbh->{sys_pluginmgr_class} = "DBD::Sys::PluginManager";
    $dbh->{sys_pluginmgr}       = DBD::Sys::PluginManager->new();
    $dbh->{sys_plugin_attrs}    = $dbh->{sys_pluginmgr}->get_tables_attrs();
    foreach my $plugin_attr ( keys %{ $dbh->{sys_plugin_attrs} } )
    {
        $dbh->{sys_valid_attrs}->{$plugin_attr} = 1;
    }

    return $dbh;
}

sub validate_STORE_attr
{
    my ( $dbh, $attrib, $value ) = @_;

    $attrib eq "sys_pluginmgr_class" and _load_class( $value, 0 );

    return $dbh->SUPER::validate_STORE_attr( $attrib, $value );
}

sub STORE ($$$)
{
    my ( $dbh, $attrib, $value ) = @_;

    $dbh->SUPER::STORE( $attrib, $value );

    if ( $attrib eq "sys_pluginmgr_class" )
    {
        $@ = undef;
        $dbh->{sys_pluginmgr} = $dbh->{sys_pluginmgr_class}->new();
        my $sys_plugin_attrs = $dbh->{sys_pluginmgr}->get_tables_attrs();

        foreach my $plugin_attr ( keys %{$sys_plugin_attrs} )
        {
            $dbh->{sys_valid_attrs}->{$plugin_attr} = 1;
        }

        foreach my $plugin_attr ( keys %{ $dbh->{sys_plugin_attrs} } )
        {
            unless ( exists( $sys_plugin_attrs->{$plugin_attr} ) )
            {
                exists $dbh->{$plugin_attr} and delete $dbh->{$plugin_attr};
                delete $dbh->{sys_valid_attrs}->{$plugin_attr};
            }
        }

        $dbh->{sys_plugin_attrs} = $sys_plugin_attrs;
    }

    return $dbh;
}

sub get_sys_versions
{
    my ( $dbh, $table ) = @_;

    my $class = $dbh->{ImplementorClass};

    return $dbh->{sys_version};    # sprintf "%s using %s", $dbh->{sys_version}, $dtype;
}

sub get_avail_tables
{
    my ($dbh) = @_;
    my @tables =
      ( $dbh->SUPER::get_avail_tables(), $dbh->selectrow_array("SELECT * FROM alltables"), );
    return @tables;
}

sub disconnect ($)
{
    return $_[0]->SUPER::disconnect();
}

package DBD::Sys::st;

use strict;
use warnings;

use vars qw(@ISA $imp_data_size);

@ISA                         = qw(DBI::DBD::SqlEngine::st);
$DBD::Sys::st::imp_data_size = 0;

package DBD::Sys::Statement;

use strict;
use warnings;

use vars qw(@ISA);

use Scalar::Util qw(weaken);

@ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table($$$$$)
{
    my ( $self, $data, $table, $createMode, $lockMode ) = @_;

    my $attr_prefix = 'sys_' . lc($table) . '_';
    my $attrs       = {};
    my $meta        = {};
    my $dbh         = $data->{Database};
    foreach my $attr ( keys %{$dbh} )
    {
        next unless ( $attr =~ m/^$attr_prefix(.+)$/ );
        $meta->{$1} = $dbh->{$attr};
    }
    $attrs->{meta}     = $meta;
    $attrs->{database} = $dbh;
    $attrs->{owner}    = $self;
    weaken( $attrs->{owner} );
    weaken( $attrs->{database} );

    my $tbl = $dbh->{sys_pluginmgr}->get_table( $table, $attrs );

    return $tbl;
}

#################### main pod documentation start ###################

=head1 NAME

DBD::Sys - System tables interface via DBI

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect('DBI::Sys:');
  my $st  = $dbh->prepare('select distinct * from filesystems join filesysdf on mountpoint');
  my $num = $st->execute();
  if( $num > 0 )
  {
      while( my $row = $st->fetchrow_hashref() )
      {
          # ...
      }
  }

=head1 DESCRIPTION

DBD::Sys is a so called database driver for L<DBI> designed to request
information from system tables using SQL. It's based on L<SQL::Statement> as
SQL engine and allows to be extended by L<DBD::Sys::Plugins>.

=head2 Prerequisites

Of course, a DBD requires L<DBI> to run. Further, L<SQL::Statement> as SQL
engine is required, L<Module::Pluggable> to manage the plugin's and
L<Module::Build> for installation. Finally, to speed up some checks,
L<Params::Util> is needed.

All these modules are mandatory and DBD::Sys will fail when they are not
available.

To request system information, existing modules from CPAN are used - there
are available ones to provide access to some system tables. These modules are
optional, but recommended. It wouldn't make much sense to use DBD::Sys without
the ability to access the tables from the (operating) system.

To get an overview which dependencies are there, please check the plugins
or take a look into META.yml.

=head1 USAGE

=head2 Installation

We chose C<Module::Build> installation, because not every system has a
suitable make utility - but at least everyone who's using perl modules has
a running perl. So installing can be done after extracting

  gzip -dc DBD-Sys-${VERSION}.tar.gz | tar xvf -

without too much extra effort:

  1  cd DBD-Sys-${VERSION}
  2  perl Build.PL
  3  ./Build
  4  ./Build test
  5  ./Build install

If you want to skip the tests (not recommended), you can skip over lines 3
and 4.

=head2 Fetching data

To retrieve data, you can use the following example:

    my $dbh = DBI->connect('DBI:Sys:');
    $st  = $dbh->prepare( 'SELECT DISTINCT username, uid FROM pwent WHERE username=?' );
    $num = $st->execute(getlogin() || $ENV{USER} || $ENV{USERNAME});
    while( $row = $st->fetchrow_hashref() )
    {       
	printf( "Found result row: uid = %d, username = %s\n", $row->{uid}, $row->{username} );
    }       

=head2 Error handling

Errors while processing statements are handled via DBI - read L<DBI>
documentation, especially the C<err> and C<errstr> documentation,
if you're not familiar with error handling in DBI.

Errors while modifying attributes, calling driver methods etc. are
reported by throwing an exception using L<Carp|Carp::croak>.

=head2 Metadata

Each table implementor can request configurable meta data attributes.
They will be accessible via the database handle:

    print $dbh->{"sys_" . lc $table . "_" . $attr}, "\n";
    # e.g.
    print DBI->neat( $dbh->{sys_filesysdf_blocksize} ), "\n";

=head1 BUGS & LIMITATIONS

This module does not support any changes to the provided tables in order
to prevent inconsistent data.

The design of the plugins makes it less predictable what columns are
provided in the end. Well, at least those columns from the tables
provided by the DBD::Sys::Plugin::Meta and DBD::Sys::Plugin::Any
will be available, even if they are not filled with data when the
appropriate module is missing (e.g. if L<Sys::Filesystem> is not
available, the table C<filesystems> gets the columns provided by
L<DBD::Sys::Plugin::Any::Filesys>, but no data at all).

All additional table implementors must use the same primary key as
all other implementors. To stay at the example of C<filesystems>, the
primary key is I<mountpoint> - and if any additional module provides
another implementation (with data from another module than
C<Sys::Filesystem>), it needs to ensure that the column I<mountpoint>
is provided and unique. Additionally it must return I<mountpoint> as
primary key when it's method C<get_primary_key> is invoked.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
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

=head1 SEE ALSO

perl(1), L<DBI>, L<Module::Build>, L<Module::Pluggable>, L<Params::Util>,
L<SQL::Statement>.

=cut

#################### main pod documentation end ###################

1;
