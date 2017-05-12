#!/usr/bin/perl
use strict;
use warnings;
use lib './t/lib';

use Test::More tests => 19;
use Data::Dumper;
$Data::Dumper::Indent = 1;

our $tmp;

BEGIN {
  eval{ require DBD::SQLite; };
  plan skip_all => "Can't use DBD::SQLite"  if $@;

  use File::Temp qw//;
  $tmp = File::Temp->new
	 ( TEMPLATE => 'tempXXXXX', DIR => File::Spec->tmpdir(), SUFFIX => '.db');
  my $dbfile = $tmp->filename;
  diag( "Using dbfile: $dbfile" );

  # prepare the email store database
  system 'perl', '-e', "use Email::Store 'dbi:SQLite:${dbfile}';",
	 '-e', 'Email::Store->setup(0)';

  require TestApp::Model::EmailStore;
  TestApp::Model::EmailStore->config->{dsn} = "dbi:SQLite:${dbfile}";
}

package TestApp;

use Catalyst qw[-Engine=Test];

__PACKAGE__->config( name => qw/TestApp/, home => '.' );
__PACKAGE__->setup();

package DBITest;

use base qw/Email::Store::Mail TestApp::Model::EmailStore/;

package main;

require Catalyst::Test;
Catalyst::Test->import( qw/TestApp/ );

use Email::Simple::Creator;

my $email = Email::Simple->create(
  header => [
    Received => 'from willert by localhost.localdomain;' .
		'Sun, 27 Nov 2005 18:35:29 +0100',
	 From    => 'Sebastian Willert <willert@cpan.org>',
	 To      => 'drain@example.com',
	 Subject => 'Message in a bottle',
  ],
  body => 'Nothing relevant',
);

my $mail_model = TestApp->model( 'EmailStore::Mail' );
isa_ok( $mail_model, 'TestApp::Model::EmailStore::Mail' );

# storing as class method
my $instance = TestApp::Model::EmailStore::Mail->store( $email->as_string );
isa_ok( $instance, 'TestApp::Model::EmailStore::Mail' );
isnt( \$mail_model,  \$instance, 'Model an instance are different objects' );
is( $email->body, $instance->simple->body, 'Body is correct' );

# storing as instance method
$instance = TestApp->model( 'EmailStore::Mail' )->store( $email->as_string );
isa_ok( $instance, 'TestApp::Model::EmailStore::Mail' );
isnt( \$mail_model,  \$instance, 'Model an instance are different objects' );
is( $email->body, $instance->simple->body, 'Body is correct' );

# upgraded relationships
my $mail = $instance;
for ( $mail->addressings ) {
  isa_ok( $_, qw/TestApp::Model::EmailStore::Addressing/ );
  isa_ok( $_, qw/Email::Store::Addressing/ );
}


my ($name) = TestApp->model( qw/EmailStore::Entity::Name/ )
  ->search( name => "Sebastian Willert" );
isa_ok( $name, qw/TestApp::Model::EmailStore::Entity::Name/ );

my @my_mails = map{ $_->mail } $name->addressings( role => "From" );
is( scalar( @my_mails ), 2, "Number of mails" )
  or BAIL_OUT( "Wring number of mails stored" );

isa_ok( $_, qw/TestApp::Model::EmailStore::Mail/ ) for @my_mails;
isa_ok( $_, qw/Email::Store::Mail/ ) for @my_mails;

my ( $m1, $m2 ) = @my_mails;
isnt( $m1->id, $m2->id, "Message IDs are different" );
is( $m1->simple->body, $m2->simple->body, "Message bodies are the same" );
