package BuzzSaw::Types; # -*-perl-*-
use strict;
use warnings;

# $Id: Types.pm.in 22999 2013-04-03 19:38:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22999 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/Types.pm.in $
# $Date: 2013-04-03 20:38:25 +0100 (Wed, 03 Apr 2013) $

our $VERSION = '0.12.0';

use UNIVERSAL::require;

use MooseX::Types -declare => [qw(BuzzSawDB BuzzSawParser
                                  BuzzSawDateTime BuzzSawTimeZone
                                  BuzzSawDataSource BuzzSawDataSourceList
                                  BuzzSawDataSourceFilesNamesList
                                  BuzzSawFilter BuzzSawFilterList
                                  BuzzSawReport BuzzSawReportList)];
use MooseX::Types::Moose qw(ArrayRef HashRef RegexpRef Str);

sub create_new_object {
  my ( $modbase, $modname, @args ) = @_;

  if ( $modname !~ m/^\Q$modbase\E::/ ) {
    $modname = join '::', $modbase, $modname;
  }

  $modname->require or die $UNIVERSAL::require::ERROR;

  if ( scalar @args == 1 && ref $args[0] eq 'ARRAY' ) {
    @args = @{$args[0]};
  }

  return $modname->new(@args);
}

# Parser

role_type BuzzSawParser, { role => 'BuzzSaw::Parser' };

coerce BuzzSawParser,
  from Str,
  via { create_new_object( 'BuzzSaw::Parser', $_ ) };

# Filter

role_type BuzzSawFilter, { role => 'BuzzSaw::Filter' };

coerce BuzzSawFilter,
  from Str,
  via { create_new_object( 'BuzzSaw::Filter', $_ ) };

subtype BuzzSawFilterList,
  as ArrayRef[BuzzSawFilter];

coerce BuzzSawFilterList,
  from ArrayRef,
  via { [ map { to_BuzzSawFilter($_) } @{$_} ] };

# Report

class_type BuzzSawReport, { class => 'BuzzSaw::Report' };

coerce BuzzSawReport,
  from Str,
  via { create_new_object( 'BuzzSaw::Report', $_ ) };

coerce BuzzSawReport,
  from ArrayRef,
  via { create_new_object( 'BuzzSaw::Report', @{$_} ) };

subtype BuzzSawReportList,
  as ArrayRef[BuzzSawReport];

coerce BuzzSawReportList,
  from ArrayRef,
  via { [ map { to_BuzzSawReport($_) } @{$_} ] };

# DB

class_type BuzzSawDB, { class => 'BuzzSaw::DB' };

coerce BuzzSawDB,
  from Str,
  via { require BuzzSaw::DB;
        BuzzSaw::DB->new_with_config(configfile => $_) };

coerce BuzzSawDB,
  from HashRef,
  via { require BuzzSaw::DB;
        BuzzSaw::DB->new($_) };

# DataSource

role_type BuzzSawDataSource, { role => 'BuzzSaw::DataSource' };

coerce BuzzSawDataSource,
  from Str,
  via { create_new_object( 'BuzzSaw::DataSource', $_ ) };

coerce BuzzSawDataSource,
  from ArrayRef,
  via { create_new_object( 'BuzzSaw::DataSource', @{$_} ) };

subtype BuzzSawDataSourceList,
  as ArrayRef[BuzzSawDataSource];

coerce BuzzSawDataSourceList,
  from ArrayRef,
  via { [ map { to_BuzzSawDataSource($_) } @{$_} ] };

# DateTime

class_type BuzzSawDateTime, { class => 'BuzzSaw::DateTime' };

coerce BuzzSawDateTime,
    from Str,
    via {
      require BuzzSaw::DateTime;
      BuzzSaw::DateTime->from_date_string($_);
    };

coerce BuzzSawDateTime,
    from HashRef,
    via {
      require BuzzSaw::DateTime;
      BuzzSaw::DateTime->new( time_zone => 'local', %{$_} );
    };

class_type BuzzSawTimeZone, { class => 'DateTime::TimeZone' };

coerce BuzzSawTimeZone,
    from Str,
    via {
	require DateTime::TimeZone;
	DateTime::TimeZone->new( name => $_ );
    };

# DataSource

subtype BuzzSawDataSourceFilesNamesList,
  as ArrayRef[Str|RegexpRef];

coerce BuzzSawDataSourceFilesNamesList,
  from Str,
  via { [$_] };

coerce BuzzSawDataSourceFilesNamesList,
  from RegexpRef,
  via { [$_] };

1;
__END__
