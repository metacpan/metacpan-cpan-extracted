#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use Audio::DB::Build;
use Pod::Usage;
use Getopt::Long;
use strict;

my ($adaptor,$dsn,$user,$pass,$host);
GetOptions('adaptor=s' => \$adaptor,
	   'dsn=s'     => \$dsn,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'host=s'    => \$host,
	  );

pod2usage( -verbose=> 2 ) unless ($adaptor && $dsn);

my $build = Audio::DB::Build->new(-user   => $user,
				-pass   => $pass,
				-host   => $host,
				-dsn    => $dsn,
				-create => 1);

# Initialize the database with the default schema
$build->initialize(1);

__END__


=pod

=head1 NAME

create_schema -- create and initialize a new database with the Audio::DB schema.

=head1 SYNPOSIS

 create_schema --user todd --pass password --dsn todds_music

=head1 OPTIONS

Options:
   adaptor  either dbi::sqlite or dbi::mysql
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   host     database host, if other than localhost

=head1 AUTHOR

 Todd Harris (harris@cshl.org);
 $Id: create_schema.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
