#!/usr/bin/perl -w 

use ExtUtils::MakeMaker;
use File::Spec;
use Cwd qw(abs_path);
use File::Basename;
use Crypt::CBC;

my $do_mysql_tests;
my $do_odbc_tests;
my $default_key = &create_DEFAULT_KEY(20);

print << "[EOM]";
############################################################
# IMPORTANT:
# This module has deprecated functions. I have keep their
# tests, although now, their execution is optional.  They
# require a MySQL connection and an ODBC connection (this
# last if you are on a Win32 machine).
#
# Do you agree to execute MySQL tests ? ( [no], yes )
# (if your answer is 'yes', I will ask you next some 
#  questions about database name, host, port, user and
#  password for configuring a connection to execute these 
#  tests. Please, make sure to take at hand such connection
#  datas)
#
[EOM]

$do_mysql_tests = prompt('Your answer:', 'no');
$do_mysql_tests = $do_mysql_tests =~ /^y(es)?$/i ? 1 : 0;

if( $^O ne 'MSWin32' )
{
    $do_odbc_tests = 0;
}
else
{
    print << "[EOM]";
#
# Your platform is MS Windows.
#
# Do you agree to execute ODBC tests ? ( [no], yes )
# (if your answer is 'yes', I will ask you next some 
#  questions about an ODBC Data Source Name (DSN) 
#  If you haven't one, create it before running 
#  this installation).
#
[EOM]

    $do_odbc_tests = prompt('Your answer:', 'no');
    $do_odbc_tests = $do_odbc_tests =~ /^y(es)?$/i ? 1 : 0;
}


# Reads data of a MySQL connection and saves them in t/connect.ini
# 
&create_ini(
            File::Spec->catfile('.','t','connect.ini'),
            \&read_mysql_params

           ) if $do_mysql_tests;


# Reads data of an ODBC DSN and saves them in t/odbc.ini 
# 
&create_ini(
            File::Spec->catfile('.','t','odbc.ini'),
            \&read_odbc_params

           ) if $do_odbc_tests;


# Creates an ANSWER file marking what tests should be executed
# ANSWER contains source code of a hasref passed as argument,
# ready to be read end evaluated.
#
&save_answers( {
    'do_mysql_tests' => $do_mysql_tests,
    'do_odbc_tests'  => $do_odbc_tests
               } );


sub save_answers
{
    my $answers = shift;

    open( my $fh, '>', File::Spec->catfile('.','t','ANSWERS') );
    print $fh "{\n";
    while ( my($k,$v) = each %$answers )
    {
        print $fh "$k => $v, ";
    } 
    print $fh "}\n";
    close $fh;
}

sub encryptPassword
{
    my $pass = shift;
  
    my $cipher = Crypt::CBC->new( {'key'    => $default_key,

                                   'cipher' => 'Blowfish'       
                                   # Put here your preferred installed Crypt::Module
                                  });
    $cipher->start('Encript');
    my $ciphertext = $cipher->encrypt_hex($pass);
    $cipher->finish();
    
    return $ciphertext;
}

sub read_odbc_params
{
    print "==== Properties of an ODBC DSN ====\n\n";

    my $dsn = prompt("What's the name of a valid ODBC DSN ?\n", '');
    if( ! $dsn )
    {
        print "An ODBC DSN name is mandatory.\n";
        $dsn = prompt("What's the name of a valid ODBC DSN ?\n", '');
        if( !$dsn )
        {
            $do_odbc_tests = 0;
            return undef;
        }   
    }

    my $username  = prompt("What is the username ? (defaults to empty)\n",'');

    my $password  = prompt("What is the password ? (defaults to empty)\n", '');
    $password = &encryptPassword( $password ) if $password;

    return { driver => 'ODBC', dsn => $dsn, username => $username, password => $password };
}

sub read_mysql_params
{
    print "==== Properties of a MySQL connection ====\n\n";

    my $database  = prompt("What is the name of your batabase ?\n",'');
    if( ! $database )
    {
        print "A MySQL database name is mandatory.\n";
        $database = prompt("What is the name of your batabase ?\n", '');
        if( !$database )
        {
            $do_mysql_tests = 0;
            return undef;
        }
    }

    my $host  = prompt("What is the hostname or IP of your MySQL server ? (defaults to localhost)\n",'localhost');
 
    my $port  = prompt("What is the port number where your MySQL listens ? (defaults to 3306)\n",'3306');
 
    my $username  = prompt("What is the username ? (defaults to empty)\n",'');
 
    my $password  = prompt("What is the password ? (defaults to empty)\n", '');
    $password = &encryptPassword( $password ) if $password;

    return { 
        driver => 'mysql', 
        database => $database, 
        host => $host,
        port => $port, 
        username => $username,
        password => $password 
           };
}

sub create_ini
{
    my($ini, $fnc) = @_;

    my $ref = &$fnc;
    return if !$ref;

    my $content = "[connection]\n";
    my %params = %{ $ref };
    while( my($key, $value) = each %params ) 
    {
        $content .= "$key=$value\n";
    }
    
    open(INI_FILE, ">$ini") || die $!;
    print INI_FILE $content;
    close INI_FILE;

    print << "[EOM]"; 
A file $ini with content

$content

has been created.
[EOM]
    
}

sub create_DEFAULT_KEY
{
    my $len = shift;
    
    my @alpha = ( 0..9, 'a'..'z', 'A'..'Z', ' ' );
    my $key = '';
    foreach (1..$len)
    {
        $key .= $alpha[int(rand( @alpha ))];
    }
    
    open(my $fh, '>', 'DEFAULT_KEY') or die $!;
    print $fh $key;
    close $fh;
    
    return $key;
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
              
    NAME	   => 'DBIx::PasswordIniFile',
    VERSION_FROM  => 'PasswordIniFile.pm',
    
    PRINT_PREREQ => 1,
    PREREQ_PM => {
            'Config::IniFiles' => 0,
            'Crypt::CBC'       => 0,
            'Crypt::Blowfish'  => 0,
            'DBI'              => 0,
            'File::HomeDir'    => 0,
            
            'Test::More'       => 0   # Only for tests execution step
    },
    
    PM => {
              'PasswordIniFile.pm' => '$(INST_LIBDIR)/PasswordIniFile.pm'
            , 'DEFAULT_KEY'        => '$(INST_LIBDIR)/DEFAULT_KEY'    
          },
     
    EXE_FILES => [ 'encpassw.pl' ],
    
    clean => { FILES => 'DEFAULT_KEY META.yml *~ t/ANSWERS t/*.ini t/*~'  }
    
    
);


