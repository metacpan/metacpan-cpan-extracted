#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(tmpdir);
use Test::More tests => 14;

##############################################################################
# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    } else {
        unshift @INC, 't/lib', 'lib';
    }
}
chdir 't';
use TieOut;

##############################################################################
# Load classes and create prompt object.
BEGIN { use_ok('App::Info::HTTPD::Apache') }
BEGIN { use_ok('App::Info::RDBMS::PostgreSQL') }
BEGIN { use_ok('App::Info::Lib::Expat') }
BEGIN { use_ok('App::Info::Lib::Iconv') }
BEGIN { use_ok('App::Info::Handler::Prompt') }
ok( my $p = App::Info::Handler::Prompt->new, "Create prompt" );
$p->{tty} = 1; # Cheat death.

##############################################################################
# Tie STDOUT and STDIN so I can read them.
my $stdout = tie *STDOUT, 'TieOut' or die "Cannot tie STDOUT: $!\n";
my $stdin = tie *STDIN, 'TieOut' or die "Cannot tie STDIN: $!\n";

##############################################################################
# Test Apache.
##############################################################################
# Set up a couple of answers.
print STDIN "foo3424324\n";
print STDIN "\n";

ok( App::Info::HTTPD::Apache->new( on_confirm => $p,
                                   on_unknown => $p ),
    "Set up for Apache confirm" );

my $expected = qr/Path to your httpd executable?.* Not an executable: 'foo3424324'\nPath to your httpd executable?/;

like ($stdout->read, $expected, "Check Apache cofirm" );

##############################################################################
# Test PostgreSQL.
##############################################################################
# Set up a couple of answers.
print STDIN "foo3424324\n";
print STDIN "\n";

ok( App::Info::RDBMS::PostgreSQL->new( on_confirm => $p,
                                       on_unknown => $p ),
    "Set up for Pg confirm" );

$expected = qr/Path to pg_config?.* Not an executable: 'foo3424324'\nPath to pg_config?/;

like ($stdout->read, $expected, "Check Pg cofirm" );

##############################################################################
# Test Expat.
##############################################################################
# Set up a couple of answers.
print STDIN "foo3424324\n";
print STDIN "\n";

ok( App::Info::Lib::Expat->new( on_confirm => $p,
                                on_unknown => $p ),
    "Set up for Expat confirm" );

$expected = qr/Path to Expat library directory?.* No Expat libraries found in directory: 'foo3424324'\nPath to Expat library directory?/;

like ($stdout->read, $expected, "Check Expat cofirm" );

##############################################################################
# Test Iconv.
##############################################################################
# Set up a couple of answers.
print STDIN "foo3424324\n";
print STDIN "\n";

ok( App::Info::Lib::Iconv->new( on_confirm => $p,
                                on_unknown => $p ),
    "Set up for Iconv confirm" );

$expected = qr/Path to iconv executable?.* Not an executable: 'foo3424324'\nPath to iconv executable?/;

like ($stdout->read, $expected, "Check Iconv cofirm" );



__END__
