package DBD::Sys::CompositeTable;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

require SQL::Eval;
require DBI::DBD::SqlEngine;
use Scalar::Util qw(blessed weaken);
use Clone qw(clone);
use Carp qw(croak);

@ISA     = qw(DBD::Sys::Table);
$VERSION = "0.102";

=pod

=head1 NAME

DBD::Sys::CompositeTable - Table implementation to compose different sources into one table

=head1 ISA

  DBD::Sys::CompositeTable
  ISA DBD::Sys::Table
    ISA DBI::DBD::SqlEngine::Table

=head1 DESCRIPTION

DBD::Sys::CompositeTable provides a table which composes the data from
several sources in one data table.

While constructing this table, the columns of the embedded tables are
collected and a heading and a merge plan for the composed result table
is generated.

Simplified example of table procs:

  $alltables = $dbh->selectall_hashref("select * from procs", "pid");

  # calls
  # DBD::Sys::CompositeTable( [ 'DBD::Sys::Plugin::Any::Procs',
  #                             'DBD::Sys::Plugin::Win32::Procs' ],
  #                           $attr );

This will fetch the column names from both embedded tables and get (simplfied):

  # %colNames = (
  #     'DBD::Sys::Plugin::Any::Procs' => [
  #       'pid', 'ppid', 'uid', 'gid', 'cmndline', 'sess', 'priority', 'ttynum', 'start', 'run', 'status',
  #     ],
  #     'DBD::Sys::Plugin::Win32::Procs' => [
  #       'pid', 'ppid', 'uid', 'gid', 'cmndline', 'sess', 'priority', 'thread', 'start', 'run', 'status',
  #     ]
  # );
  # @colNames = (
  #       'pid', 'ppid', 'uid', 'gid', 'cmndline', 'sess', 'priority', 'ttynum', 'start', 'run', 'status', 'threads',
  # );
  # %mergeCols = (
  #     'DBD::Sys::Plugin::Any::Procs' => [
  #         0 .. 10,
  #     ],
  #     'DBD::Sys::Plugin::Win32::Procs' => [
  #         7,
  #     ]
  # );
  # $primaryKey = 'pid';

The merge phase in C<collect_data()> finally does (let's assume running
in a cygwin environment, where Proc::ProcessTable and Win32::Process::Info
both are working):

  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+
  | pid | ppid | uid | gid | cmndline | sess | priority |  ttynum | start | run | status  |
  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+
  |   0 |    0 |   0 |   0 | 'init'   |    0 |        4 | <undef> |     0 | 999 | 'ioblk' |
  | 100 |    0 | 200 |  20 | 'bash'   |    1 |        8 |   pty/1 | 10000 | 200 | 'wait'  |
  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+

  +-----+------+-----+-----+----------+------+----------+-------+-----+---------+---------+
  | pid | ppid | uid | gid | cmndline | sess | priority | start | run | status  | threads |
  +-----+------+-----+-----+----------+------+----------+-------+-----+---------+---------+
  | 782 |  241 | 501 | 501 | 'cygwin' |    0 |        4 |     0 | 999 | 'ioblk' |       2 |
  | 100 |    0 | 501 | 501 | 'bash'   |    1 |        8 | 10000 | 200 | 'wait'  |       8 |
  +-----+------+-----+-----+----------+------+----------+-------+-----+---------+---------+

The resulting table would be:

  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+---------+
  | pid | ppid | uid | gid | cmndline | sess | priority |  ttynum | start | run | status  | threads |
  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+---------+
  |   0 |    0 |   0 |   0 | 'init'   |    0 |        4 | <undef> |     0 | 999 | 'ioblk' | <undef> |
  | 100 |    0 | 200 |  20 | 'bash'   |    1 |        8 |   pty/1 | 10000 | 200 | 'wait'  |       8 |
  | 782 |  241 | 501 | 501 | 'cygwin' |    0 |        4 | <undef> |     0 | 999 | 'ioblk' |       8 |
  +-----+------+-----+-----+----------+------+----------+---------+-------+-----+---------+---------+

In the real world, it's a bit more complicated and especially the process
table is a bit larger, but it illustrates the most important points:

=over 4

=item *

missing columns are attached right

=item *

missing rows are appended at the end of the first table (and are
constructed as good as possible from the data we have)

=item *

once existing data are neither verified nor overwritten (see the difference
in the cygwin uid (root => uid 0) and win32 uid (Administrator => uid 501).

=back

This is a fictive example - it's not verified how DBD::Sys behaves in
I<cygwin>! Maybe the user mapping works fine - maybe there will be no
problem at all. Maybe you will get duplicated lines for each process
with completely different data.

This is an experimental feature. Use with caution!

=head1 METHODS

=head2 new

  sub new( $proto, $tableInfo, $attrs ) { ... }

Creates a new composite table based on the tables in C<$tableInfo>,
analyses the result view and create a merge plan for extending rows and
appending rows.

The order of the embedded tables is primarily influenced by the priority
of the table and secondarily by the alphabetic order of their package
names.

In L</DESCRIPTION|above> example, C<DBD::Sys::Plugin::Any::Procs> has
a priority of 100 and C<DBD::Sys::Plugin::Win32::Procs> has a priority
of 500. So C<D::S::P::Any::Procs> dominates.

=cut

my %compositedInfo;

sub _pk_cmp_fail
{
    my ( $pk, $epk ) = @_;
    ref($pk) eq ref($epk)
      or return
      sprintf(
               "Can't compare primary key type (%s) of '%s' with primary key type (%s) of '%s'",
               ref($epk) ? "\\" . ref($epk) : "SCALAR", "%s",
               ref($pk)  ? "\\" . ref($pk)  : "SCALAR", "%s"
             );
    if ( ref($pk) eq "" )
    {
        $pk eq $epk and return;
        return
          sprintf( "Primary key (%s) of '%s' differs from primary key (%s) of '%s'",
                   DBI::neat($epk), "%s", DBI::neat($pk), "%s" );
    }
    elsif ( ref($pk) eq "ARRAY" )
    {
        join( "\0", sort @$epk ) eq join( "\0", sort @$pk ) and return;
        return
          sprintf( "Primary key (%s) of '%s' differs from primary key (%s) of '%s'",
                   DBI::neat_list($epk), "%s", DBI::neat_list($pk), "%s" );
    }

    croak "Invalid type for primary key: " . ref($pk);
}

sub new
{
    my ( $proto, $tableInfo, $attrs ) = @_;

    my @tableClasses =
      sort { ( $a->get_priority() <=> $b->get_priority() ) || ( blessed($a) cmp blessed($b) ) }
      @$tableInfo;

    my $compositeName = join( "-", @tableClasses );
    my ( @embed, %allColNames, @allColNames, $allColIdx, %mergeCols, %enhanceCols, $primaryKey );
    $allColIdx = 0;
    foreach my $tblClass (@tableClasses)
    {
        my %embedAttrs = %$attrs;
        my $embedded   = $tblClass->new( \%embedAttrs );
        push( @embed, $embedded );
        next if ( defined( $compositedInfo{$compositeName} ) );

        my @embedColNames = $embedded->get_col_names();
        if ($allColIdx)
        {
            my $embedPK = $embedded->get_primary_key();
            my $pkFailure = _pk_cmp_fail( $primaryKey, $embedPK );
            $pkFailure and croak( sprintf( $pkFailure, $tblClass, join( ", ", keys %mergeCols ) ) );
            $mergeCols{$tblClass} = [];
            foreach my $colIdx ( 0 .. $#embedColNames )
            {
                my $colName = $embedColNames[$colIdx];
                if ( exists( $allColNames{$colName} ) )
                {
                    $enhanceCols{$tblClass}->{ $allColNames{$colName} } = $colIdx;
                }
                else
                {
                    push( @allColNames,               $colName );
                    push( @{ $mergeCols{$tblClass} }, $colIdx );
                    $allColNames{$colName} = $allColIdx++;
                }
            }
        }
        else
        {
            %allColNames          = map { $_ => $allColIdx++ } @embedColNames;
            @allColNames          = @embedColNames;
            $mergeCols{$tblClass} = [ 0 .. $#embedColNames ];
            $primaryKey           = $embedded->get_primary_key();
        }
    }

    defined( $compositedInfo{$compositeName} )
      or $compositedInfo{$compositeName} = {
                                             col_names    => \@allColNames,
                                             primary_key  => $primaryKey,
                                             merge_cols   => \%mergeCols,
                                             enhance_cols => \%enhanceCols,
                                           };

    $attrs->{meta} = {
                       composite_name => $compositeName,
                       embed          => \@embed,
                       primary_key    => $compositedInfo{$compositeName}->{primary_key},
                       merge_cols     => $compositedInfo{$compositeName}->{merge_cols},
                       enhance_cols   => $compositedInfo{$compositeName}->{enhance_cols},
                     };
    $attrs->{col_names} = clone( $compositedInfo{$compositeName}->{col_names} );

    return $proto->SUPER::new($attrs);
}

=head2 get_col_names

This method is called during the construction phase of the table. It must be
a I<static> method - the called context is the class name of the constructed
object.

=cut

sub get_col_names
{
    return @{ $_[0]->{col_names} };
}

=head2 collect_data

Merges the collected data by the embedded tables into one composed list
of rows. This list of rows will be delivered to C<SQL::Statement> when
C<fetch_row> is called.

The merge phase is demonstrated in the example in L</DESCRIPTION>.

=cut

sub collect_data
{
    my $self = $_[0];
    my %data;

    my $meta          = $self->{meta};
    my $compositeName = $meta->{composite_name};
    my $rowOffset     = 0;
    my @primaryKeys =
      ( ref $meta->{primary_key} ) ? @{ $meta->{primary_key} } : ( $meta->{primary_key} );
    foreach my $embedded ( @{ $meta->{embed} } )
    {
        my @pkIdx         = map { $embedded->column_num($_) } @primaryKeys;
        my $mergeCols     = $meta->{merge_cols}->{ blessed($embedded) };
        my $enhanceCols   = $meta->{enhance_cols}->{ blessed($embedded) };
        my $nextRowOffset = $rowOffset + scalar(@$mergeCols);

        while ( my $row = $embedded->fetch_row() )
        {
            my $pks = join( "\0", map { DBI::neat($_) } @$row[@pkIdx] );
            my $ref = \%data;
            $ref = $ref->{$pks} ||= [];
            if ( @{$ref} )
            {
                if ( scalar( @{$ref} ) == $nextRowOffset )
                {
                    warn "primary key '"
                      . $meta->{primary_key}
                      . "' is not unique for "
                      . blessed($embedded);
                }
                else
                {
                    push( @{$ref}, @$row[@$mergeCols] );
                }
            }
            else
            {
                if ( 0 == $rowOffset )
                {
                    @$ref = @$row;
                }
                else
                {
                    my @entry = (undef) x $rowOffset;
                    @entry[ keys %{$enhanceCols} ] = @$row[ values %{$enhanceCols} ];
                    push( @entry, @$row[@$mergeCols] );
                    @$ref = @entry;
                }
            }
        }

        $rowOffset = $nextRowOffset;
    }

    my @data = values %data;

    return \@data;
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

Free support can be requested via regular CPAN bug-tracking system. There is
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

1;
