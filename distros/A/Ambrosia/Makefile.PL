#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long::Descriptive;
use Data::Dumper ();

my $DB_SCHEMA = 'test';
my $DB_HOST = 'localhost';
my $DB_PORT = 3306;
chomp(my $DB_USER = `whoami`);
my $DB_PASSWORD = '';

my ($opt, $usage) = describe_options(
    'Makefile.PL %o ',
    [ 'schema|s=s',   "the schema that use for test", { default => $DB_SCHEMA }],
    [ 'host|h=s',     "the host to connect to", { default => $DB_HOST }],
    [ 'port|p=i',     "the port to connect to", { default => $DB_PORT } ],
    [ 'socket|S',     "use socket insted port to connect to"],
    [ 'user|U=s',     "the user to connect to", { default => $DB_USER } ],
    [ 'password|P=s', "the password to connect to", { default => $DB_PASSWORD } ],
    [],
    [ 'help',       "print usage message and exit" ],
);

print($usage->text), exit if $opt->help;

if ( open(my $fh, '>', './t/db.params') )
{
    my $schema = $opt->schema;
    my $host = $opt->host;
    my $port = $opt->socket ? '' : 'port          => ' . $opt->port . ',';
    my $user = $opt->user;
    my $password = $opt->password;

    print $fh <<EOB;
return {
    DBI => [
        {
            engine_name   => 'mysql',
            source_name   => 'Client',
            catalog       => undef,
            schema        => '$schema',
            host          => '$host',
            $port
            user          => '$user',
            password      => '$password',
            additional_params => { AutoCommit => 0, RaiseError => 1, LongTruncOk => 1 },
            additional_action => sub { my \$dbh = shift; \$dbh->do('SET NAMES utf8')},
        },
    ]
};
EOB
    close $fh;
}

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'a powerful web application framework that can be used to create general applications too.',
  'AUTHOR' => 'Nikolay Kuritsyn <knm@cpan.org>',
  'BUILD_REQUIRES' => {
    'Moose' => '0',
    'Test::Deep' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Ambrosia',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Ambrosia',
  'PREREQ_PM' => {
    'Apache' => '0',
    'Apache::Constants' => '0',
    'Apache::Request' => '0',
    'CGI' => '0',
    'CGI::Cookie' => '0',
    'Carp' => '0',
    'DBI' => '0',
    'Data::Dumper' => '0',
    'Data::Serializer' => '0',
    'Exporter' => '0',
    'File::Path' => '0',
    'Getopt::Long::Descriptive' => '0.087',
    'IO::File' => '0',
    'JSON::XS' => '0',
    'SOAP::Lite' => '0',
    'Scalar::Util' => '0',
    'Time::HiRes' => '0',
    'XML::LibXML' => '0',
    'if' => '0',
    'integer' => '0',
    'overload' => '0'
  },
  'VERSION' => '0.010',
  'test' => {
    'TESTS' => 't/*.t t/Ambrosia/*.t t/Ambrosia/Utils/*.t t/Ambrosia/core/*.t t/Ambrosia/error/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


