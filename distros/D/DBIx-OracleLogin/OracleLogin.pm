package DBIx::OracleLogin;

use strict;
use Term::ReadKey;

use vars qw($VERSION @ISA @EXPORT);
require Exporter;
@ISA    = ('Exporter');
@EXPORT = qw( &parse );

$VERSION = '0.02';

sub parse {
    my ($text) = @_;

    my $user;
    my $pass;
    my $sid;
 
    # Return if there are more special characters than expected
    return undef if ( $text =~ /.*\/.*\// or $text =~ /.*\@.*\@/);

    if ( $text =~ /^([^\/]+)\/([^\@]+)\@(.+)$/ ) {    # form UID/PW@SID
        $user = $1;
        $pass = $2;
        $sid  = $3;
    }

    elsif ( $text =~ /^([^\@]+)\@([^\/]+)\/(.+)$/ ) {    # form UID@SID/PW
        $user = $1;
        $sid  = $2;
        $pass = $3;
    }

    elsif ( $text =~ /^([^\@]+)\@([^.]+)$/ ) {           # form UID@SID
        $user = $1;
        $sid  = $2;
    }

    elsif ( $text =~ /^([^\@]+)\/([^.]+)$/ ) {           # form UID/PW
        $user = $1;
        $pass  = $2;
    }

    elsif ( $text =~ /^([^\@\/]+)$/ ) {           # form UID
        $user = $1;
    }

    else {
        undef $user;
        undef $sid;
        undef $pass;
    }


    # return if there is no $user by now...
    return undef if ( !$user);

    # Prompt for password if necessary
     if ( !$pass ) {
            print STDERR "password: ";
            ReadMode('noecho');
            $pass = ReadLine(0);
            chomp $pass;
            print "\n";
     }

    # return if there is no $pass by now...
    return undef if (! $pass);

    # retrieve default sid if none has been provided
    if (!$sid) { if (!$ENV{ORACLE_SID}) {return undef;} else {$sid = $ENV{ORACLE_SID};}
    }

    return ( $user, $pass, $sid );
}


1;
__END__


=head1 NAME

DBIx::OracleLogin - takes a string and splits out individual login information (user id, Oracle sid, and password) to be used in a DBI->connect() statement when connecting to an Oracle database. 

=head1 SYNOPSIS

  use DBIx::OracleLogin;
  my ( $user, $pass, $sid ) = DBIx::OracleLogin::parse($text);

$text should be of the standard form used by Oracle applications such as sqlplus: userid@oracle_sid/password or userid/password@oracle_sid or userid@oracle_sid or userid/password or user.

A password does not need to be provided in the $text argument. If no password is provided then the program prompts for a password.

A oracle_sid does not need to be provided in the $text argument. If no oracle_sid is provided then the program attempts to retrieve a default from $ENV{ORACLE_SID} environment variable.

If the $text format is invalid the program will return null values for $user, $sid and $pass.

=head1 DESCRIPTION

This module is useful to avoid hard-coding of Oracle database login information in a Perl program. 
 
The $text argument provided to the method parse() should be of one of 
these forms: userid@oracle_sid/password or userid/password@oracle_sid or
userid@oracle_sid or userid/password or userid. 

A password does not need to be provided in the $text argument. If no password is provided then the program prompts for a password without echoing to stdout.

A oracle_sid does not need to be provided in the $text argument. If no oracle_sid is provided then the program attempts to retrieve a default from $ENV{ORACLE_SID} environment variable.

If the $text format is invalid the program will return null values for $user, $sid and $pass.

=head1 REQUIRES

Term::ReadKey

=head1 AUTHOR

Diane Benz E<lt>diane@ccgb.umn.eduE<gt>

=head1 SEE ALSO

DBD, DBD::Oracle

=cut

