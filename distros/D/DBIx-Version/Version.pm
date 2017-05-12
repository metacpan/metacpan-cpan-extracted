package DBIx::Version;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Version ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

# Preloaded methods go here.

sub Version {
   my $dbh = shift;

   return (undef, undef, undef) if not defined $dbh;

   my $version;

   # look for MontySQL
   if (exists $dbh->{'mysql_serverinfo'}) {
      $version = $dbh->{'mysql_serverinfo'};
      if ($version =~ /^(\d{1,2}\.\d{1,2}\.\d{1,2}-)/) {
# 4.0.17-standard-log
         return ('mysql', $1, $version);
      }
      else {
         return (undef, undef, undef);
      }
   }

   # look for PostgreSQL
   eval {
      my $sql = q{select version()};

      my $sth = $dbh->prepare($sql);

      my $rv = $sth->execute();

      ($version) = $sth->fetchrow_array();
      $sth->finish();
   };
   if ($@) { # prolly not valid query for this database
   }
   else {
      if ($version =~ /^PostgreSQL (\d{1,2}\.\d{1,2}\.\d{1,2}) /) {
# PostgreSQL 7.4.1 on i686-pc-linux-gnu, compiled by GCC gcc (GCC) 3.3.2 20031107 (Red Hat Linux 3.3.2-2)
         return ('postgresql', $1, $version);
      }
      else {
         return (undef, undef, undef);
      }
   }

   # look for Oracle
   # alternately, $dbh->get_info(18); # SQL_DBMS_VER
   eval {
      my $sql = q{SELECT version FROM V$INSTANCE};

      my $sth = $dbh->prepare($sql);

      my $rv = $sth->execute();

      ($version) = $sth->fetchrow_array();
      $sth->finish();
   };
   if ($@) { # prolly not valid query for this database
   }
   else {
      return ('oracle', $version, $version);
   }

   # look for Microsoft SQL Server or Sybase
   eval {
      my $sql = q{SELECT @@version};

      my $sth = $dbh->prepare($sql);

      my $rv = $sth->execute();

      ($version) = $sth->fetchrow_array();
      $sth->finish();
   };
   if ($@) { # prolly not valid query for this database
   }
   else {
      if ($version =~ / - (\d{1,2}\.\d{1,2}\.\d{3}) /) {
         return ('sqlserver', $1, $version);
      }
      elsif ($version =~ m|/(\d{1,2}\.\d{1,2}\.\d{1,2}\.\d{1,2})/| ) {
# Adaptive Server Enterprise/12.5.0.1/SWR 9982
         return ('sqlserver', $1, $version);
      }
      else {
         return (undef, undef, undef);
      }
   }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

DBIx::Version - Perl extension for getting database software name and version.

=head1 SYNOPSIS

  use DBIx::Version;

  my $dbh = DBI->connect( ... );
  my ($dbname, $dbver, $dbverfull) = DBIx::Version::Version($dbh);

=head1 DESCRIPTION

DBIx::Version lets you query which database software and version you are connected to.

Return Examples:

  (undef, undef, undef)
  ('mysql', '4.0.17', '4.0.17-standard-log')
  ('postgresql', '7.4.1', 'PostgreSQL 7.4.1 on i686-pc-linux-gnu, compiled by GCC gcc (GCC) 3.3.2 20031107 (Red Hat Linux 3.3.2-2)')
  ('oracle', '8.1.7.0.0', '8.1.7.0.0')
  ('sqlserver', '8.00.384', Microsoft SQL Server  2000 - 8.00.384 (Intel X86) 
	May 23 2001 00:02:52 
	Copyright (c) 1988-2000 Microsoft Corporation
	Standard Edition on Windows NT 5.0 (Build 2195: Service Pack 2)')
  ('sybase','12.5.0.1','Adaptive Server Enterprise/12.5.0.1/SWR 9982 IR/P/Sun_svr4/OS 5.8/rel12501/1776/ 64-bit/FBO/Tue Feb 26 01:22:10 2002')
  ('sybase','12.5.0.2','Adaptive Server Enterprise/12.5.0.2/EBF 14000 IR/P/Sun_svr4/OS 5.8/rel12502/1776/64-bit/FBO/Tue Jun 4 01:22:10 2002')

FAQ 1: "Why?"

Answer 1: This module is useful for cross-platform coding, and in environments like shared hosting where you actually didn't install the database yourself and are curious.

FAQ 2: "Can you add support for my database?"

Answer 2: Sure. Email the technique and sample output to james@ActionMessage.com

=head1 EXPORT

None by default.

=head1 AUTHORS

James Briggs, E<lt>james@ActionMessage.comE<gt>

Credits:

Rob Starkey E<lt>falcon@rasterburn.comE<gt> for the PostgreSQL SQL query.

rmah#perlhelp for naming this module.

Tim Bunce for writing DBI.

=head1 COPYRIGHT

The DBIx::Version module is Copyright (c) 2004 by James Briggs, USA. All rights reserved.

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

L<DBI>.

=cut
