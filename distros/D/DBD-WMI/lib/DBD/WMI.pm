package DBD::WMI;
use strict;
use base 'DBD::File';
use DBI;

use vars qw($ATTRIBUTION $VERSION);

$ATTRIBUTION = 'DBD::WMI by Max Maischein <dbd-wmi@corion.net>';
$VERSION = '0.07';

=head1 NAME

DBD::WMI - interface to the Windows WMI

=head1 ABSTRACT

This module allows you to issue WQL queries
through the DBI.

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect('dbi:WMI:');

  my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM Win32_Process
  WQL

  $sth->execute();
  while (my @row = $sth->fetchrow) {
    my $proc = $row->[0];
    print join "\t", $proc->{Caption}, $proc->{ExecutablePath} || "<system>";
    # $proc->Terminate();
    print "\n";
  }

The WMI
allows you to query various tables ("namespaces"), like the filesystem,
currently active processes and events:

     SELECT * FROM Win32_Process

The driver/WMI implements two kinds of queries, finite queries like the
query above and potentially infinite queries for events as they occur in
the system:

     SELECT * FROM __instanceoperationevent
     WITHIN 1
     WHERE TargetInstance ISA 'Win32_DiskDrive'

This query returns one row (via ->fetchrow_arrayref() ) whenever a disk
drive gets added to or removed from the system (think of an USB stick).

There is currently no support for selecting specific
columns instead of C<*>. Support for selecting columns that
then get returned as plain Perl scalars is planned.

=cut

# Investigate System.Management.MethodData to get at the methods and properties

my $drh;
sub driver {
    return $drh if $drh;

    my ($package,$attr) = @_;

    $package .= "::dr";
    $drh = DBI::_new_drh( $package, {
            Attribution => $ATTRIBUTION,
            Version     => $VERSION,
            Name        => 'WMI',
        },
    );

    $drh
};

package DBD::WMI::dr;
use strict;
use Win32::WQL;

use vars qw($imp_data_size);

$imp_data_size = 0;

sub connect {
    my ($drh, $dr_dsn, $user, $auth, $attr) = @_;

    $dr_dsn ||= ".";
    $dr_dsn =~ /^([^;]*)/i
        or die "Invalid DSN '$dr_dsn'";
    my $machine = $1 || ".";

    my $wmi = Win32::WQL->new(
        machine => $machine
    );

    my ($outer, $dbh) = DBI::_new_dbh(
        $drh,
        { Name => $dr_dsn },
    );
    $dbh->{wmi_wmi} = $wmi;

    #$dbh->STORE('Active',1);
    $outer
}

sub data_sources {
    my ($drh) = @_;

    my $wmi = Win32::WQL->new();
    my $sth = $wmi->prepare(<<WQL);
        SELECT * FROM meta_class
WQL

    my $sources = $sth->execute();
    my @res;
    while (my $ev = $sources->fetchrow()) {
        push @res, $ev->Path_->Class
    };
    @res
}

package DBD::WMI::db;
use strict;

use vars qw($imp_data_size);
$imp_data_size = 0;

sub prepare {
    my ($dbh, $statement, @attribs) = @_;

    my $own_sth = $dbh->{wmi_wmi}->prepare($statement);
    my ($outer, $sth) = DBI::_new_sth($dbh,
        { Statement => $statement,
          wmi_sth => $own_sth,
          wmi_params => [],
        },
    );

    my $columns = __PACKAGE__->parse_columns($statement);
    $sth->STORE('wmi_return_columns', $columns);

    $sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//));

    return $outer;
}

=head2 C<< DBD::WMI::db::parse_columns STATEMENT >>

This routine parses out the requested columns
from the WQL statement and returns an array reference
with the names of the columns.

Currently, this only works for C<SELECT> statements.
All other statements get an implicit column
of C<*>, meaning that the Win32::OLE objects
will be returned.

=cut

sub parse_columns {
    my ($dbh, $statement) = @_;
    my @columns;
    if ($statement =~ /^\s*SELECT \s*(.*?)\s+FROM\b/mi) {
        @columns = map { s/^\s*//; s/\s*$//; $_ } split /,/, $1; # verrry simplicistic parsing
    } else {
        @columns = ('*');
    };
    
    \@columns
};

sub STORE
{
  my ($dbh, $attr, $val) = @_;
  if ($attr eq 'AutoCommit') {
      # AutoCommit is currently the only standard attribute we have
      # to consider.
      if (!$val) { die "Can't disable AutoCommit"; }
      return 1;
  }
  if ($attr =~ m/^wmi_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      # Ideally we should warn about unknown attributes.
      $dbh->{$attr} = $val; # Yes, we are allowed to do this,
      return 1;             # but only for our private attributes
  }
  # Else pass up to DBI to handle for us
  $dbh->SUPER::STORE($attr, $val);
}

sub FETCH
{
  my ($dbh, $attr) = @_;
  if ($attr eq 'AutoCommit') { return 1; }
  if ($attr =~ m/^wmi_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      return $dbh->{$attr}; # Yes, we are allowed to do this,
                            # but only for our private attributes
  }
  # Else pass up to DBI to handle
  $dbh->SUPER::FETCH($attr);
}

package DBD::WMI::st;
use strict;
use Carp qw(croak);

use vars qw($imp_data_size);

$imp_data_size = 0;

sub execute {
    my $sth = shift;

    # Recycle if we're still active
    $sth->finish if $sth->FETCH('Active');

    my $params = (@_) ?
        \@_ : $sth->{wmi_params};
    my $numParam = $sth->FETCH('NUM_OF_PARAMS');
    return $sth->set_err(1, "Wrong number of parameters")
        if @$params != $numParam;
    if ($numParam > 0) {
        return $sth->set_err(1, "DBD::WMI doesn't support parameters yet")
            if @$params > 0;
    };
    #my $statement = $sth->{'Statement'};
    #for (my $i = 0;  $i < $numParam;  $i++) {
    #    $statement =~ s/?/$params->[$i]/; # doesn't deal with quoting etc!
    #
    #};

    my $iter = $sth->{wmi_sth}->execute(@$params);

    #$sth->STORE('Active',1);

    $sth->{'wmi_data'} = $iter;
    $sth->{'wmi_rows'} = 1; # we don't know/can't know
    $sth->STORE('NUM_OF_FIELDS', scalar @{$sth->FETCH('wmi_return_columns')});# $numFields;
    $sth->{'wmi_rows'} || '0E0';
}

sub fetchrow_arrayref
{
    my ($sth) = @_;
    my $data = $sth->{wmi_data};
    my @row = $data->fetchrow();

    if (! @row) {
        $sth->finish;
        return undef;
    }

    # Transform row objects into requested query columns
    if (my $columns = $sth->FETCH('wmi_return_columns')) {
        my $r = $row[0];
        @row = map { $_ eq '*' ? $r : $r->{$_} } @$columns;
    };

    if ($sth->FETCH('ChopBlanks')) {
        map { $_ =~ s/\s+$//; } @row;
    }
    return $sth->_set_fbav(\@row);
}
*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref

sub STORE
{
  my ($sth, $attr, $val) = @_;
  if ($attr =~ m/^wmi_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      # Ideally we should warn about unknown attributes.
      $sth->{$attr} = $val; # Yes, we are allowed to do this,
      return 1;             # but only for our private attributes
  }
  # Else pass up to DBI to handle for us
  $sth->SUPER::STORE($attr, $val);
}

sub FETCH
{
  my ($sth, $attr) = @_;
  if ($attr eq 'AutoCommit') { return 1; }
  if ($attr =~ m/^wmi_/) {
      # Handle only our private attributes here
      # Note that we could trigger arbitrary actions.
      return $sth->{$attr}; # Yes, we are allowed to do this,
                            # but only for our private attributes
  }
  # Else pass up to DBI to handle
  $sth->SUPER::FETCH($attr);
}

1;

=head1 HANDLING OF QUERY COLUMNS

The WMI and WQL return full objects instead of single columns. The specification
of columns is merely a hint to the object what properties to preload. The
DBD interface deviates from that approach in that it returns objects
for queries of the form C<SELECT *> and the values of the object
properties when columns are specified. These columns are then case sensitive.

=head1 FUN QUERIES

=head2 List all printers

  SELECT * FROM Win32_Printer

=head2 List all print jobs on a printer

  SELECT * FROM Win32_PrintJob
    WHERE DriverName = 'HP Deskjet 6122'

=head2 Return a new row whenever a new print job is started

  SELECT * FROM __InstanceCreationEvent
    WITHIN 10
    WHERE
      TargetInstance ISA 'Win32_PrintJob'

=head2 Finding the default printer

  SELECT * FROM Win32_Printer
    WHERE Default = TRUE

=head2 Setting the default printer (untested, WinXP, Win2003)

  use DBI;
  my $dbh = DBI->connect('dbi:WMI:');
  my $sth = $dbh->prepare(<<WQL);
      SELECT * FROM Win32_Printer
  WQL

  $sth->execute;
  while (my @row = $sth->fetchrow) {
      # We get Win32::OLE objects back:
      my $printer = $row[0];
      printf "Making %s the default printer\n", $printer->{Name};
      $printer->SetDefaultPrinter;
  };

=head2 Find all network adapters with IP enabled

  SELECT * from Win32_NetworkAdapterConfiguration
    WHERE IPEnabled = True

=head2 Find files in a directory

  ASSOCIATORS OF {Win32_Directory.Name='C:\WINNT'}
    WHERE ResultClass = CIM_DataFile

=head2 Find printers on a remote machine

  use DBI;
  my $machine = 'dawn';
  my $dbh = DBI->connect('dbi:WMI:'.$machine);
  my $sth = $dbh->prepare(<<WQL);
      SELECT * FROM Win32_Printer
  WQL

  $sth->execute;
  while (my @row = $sth->fetchrow) {
      my $printer = $row[0];
      printf "Making %s the default printer on %s\n", $printer->{Name}, $machine;
      $printer->SetDefaultPrinter;
  };

=head2 Get method names of objects

  use Win32::OLE qw(in);
  ...

  SELECT * FROM Win32_Process

  $sth->execute;

  while (my @row = $sth->fetchrow) {
      for my $method (in $row[0]->Methods_) {
          print "Can call $method() on the object\n"
      };
  };

=head1 TODO

=over 4

=item * Implement placeholders and proper interpolation of values

=item * Need to implement DSN parameters for remote computers, credentials

=back

=head1 SEE ALSO

WMI is Microsofts implementation of the WBEM standard (L<http://www.dmtf.org/standards/wbem/>) except that it uses DCOM and not CIM-XML as the transport medium.

The MS WMI main page at L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wmisdk/wmi/wmi_start_page.asp>

The WQL documentation at L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wmisdk/wmi/wql_sql_for_wmi.asp>

The "Hey Scripting Guy" column at L<http://www.microsoft.com/technet/scriptcenter/resources/qanda/default.mspx>

Wikipedia on WMI at L<http://en.wikipedia.org/wiki/Windows_Management_Instrumentation>

List of available Win32 WMI classes at L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wmisdk/wmi/win32_classes.asp>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dbd-wmi>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-WMI>
or via mail to L<www-mechanize-phantomjs-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2015 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
