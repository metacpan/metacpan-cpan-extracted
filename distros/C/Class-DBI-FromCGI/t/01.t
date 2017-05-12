#!/usr/bin/perl -w

use strict;

use CGI::Untaint;
use Test::More;

BEGIN {
  eval "use DBD::SQLite";
  plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 78);
}

#-------------------------------------------------------------------------

package Water;

use base 'Class::DBI';
use Class::DBI::FromCGI;

use File::Temp qw/tempfile/;
my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('Water');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Other   => qw/title count wibble/);
__PACKAGE__->untaint_columns(
    printable => [qw/title/],
    integer   => [qw/id count wibble/],
);

__PACKAGE__->db_Main->do(qq{
     CREATE TABLE Water (
        id     INTEGER,
        title  VARCHAR(80),
        count  INTEGER,
        wibble INTEGER
    )
});

#-------------------------------------------------------------------------


package main;
my %orig = (
  id     => 1,
  title  => 'Bout Ye',
  count  => 2,
  wibble => 10,
);
my $hoker = Water->create(\%orig);
isa_ok $hoker => 'Water';

my %args = (
  title  => 'Quare Geg',
  count  => 10,
  wibble => 8,
);

{ # Test an invalid count
  local $args{count} = "Foo";
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Invalid count)";
  ok !$hoker->update_from_cgi($h), "Update fails";
  ok my %error = $hoker->cgi_update_errors, "We have errors";
  ok $error{$_}, "Error with $_" foreach qw/count/;
  ok !$error{$_}, "No error with $_" foreach qw/title wibble/;
  is $hoker->$_(), $orig{$_}, "$_ unchanged" foreach qw/title count wibble/;
}

{ # Test multiple errors
  local $args{count} = "Foo";
  local $args{wibble} = "Bar";
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Multiple errors)";
  ok !$hoker->update_from_cgi($h), "Update fails";
  ok my %error = $hoker->cgi_update_errors, "We have errors";
  ok $error{$_}, "Error with $_" foreach qw/count wibble/;
  ok !$error{$_}, "No error with $_" foreach qw/title/;
  is $hoker->$_(), $orig{$_}, "$_ unchanged" foreach qw/title count wibble/;
}

{ # Fail update with 'forced' column
  local $args{title} = undef;
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Fail forced)";
  ok !$hoker->update_from_cgi($h => {required => [qw/title/]}), "Update fails";
  ok my %error = $hoker->cgi_update_errors, "We have errors";
  ok $error{$_}, "Error with $_" foreach qw/title/;
  ok !$error{$_}, "No error with $_" foreach qw/wibble count/;
  is $hoker->$_(), $orig{$_}, "$_ unchanged" foreach qw/title count wibble/;
}

{ # Fail update with 'forced' columns
  local $args{title} = undef;
  local $args{wibble} = undef;
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Fail multi-forced)";
  ok !$hoker->update_from_cgi($h => {required => [qw/title wibble/]}), 
     "Update fails";
  ok my %error = $hoker->cgi_update_errors, "We have errors";
  ok $error{$_}, "Error with $_" foreach qw/title wibble/;
  ok !$error{$_}, "No error with $_" foreach qw/count/;
  is $hoker->$_(), $orig{$_}, "$_ unchanged" foreach qw/title count wibble/;
}

{ # Only update some columns
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Partial update)";
  ok $hoker->update_from_cgi($h => 'title'), "Can update";
  ok !$hoker->cgi_update_errors, "No error";
  is $hoker->$_(), $args{$_}, "$_ changed" foreach qw/title/;
  isnt $hoker->$_(), $args{$_}, "$_ not changed" foreach qw/count wibble/;
  $hoker->update;
}

{ # Ignore some
  local $args{title} = "Ignored?";
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Partial update)";
  ok $hoker->update_from_cgi($h => {ignore => [qw/title/]}), "Can update";
  ok !$hoker->cgi_update_errors, "No error";
  is $hoker->$_(), $args{$_}, "$_ changed" foreach qw/count wibble/;
  isnt $hoker->$_(), $args{$_}, "$_ not changed" foreach qw/title/;
  $hoker->update;
}

{ # Update all
  local $args{title} = "Hoke it out";
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Full update)";
  ok $hoker->update_from_cgi($h), "Can update";
  ok !$hoker->cgi_update_errors, "No error";
  is $hoker->$_(), $args{$_}, "$_ changed" foreach qw/title count wibble/;
  $hoker->update;
}

{ # Create
  local $args{id} = 438;
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Creation)";
  my $new = Water->create_from_cgi($h);
  isa_ok $new, 'Water';
  ok !$new->cgi_update_errors, "No error";
  is $new->$_(), $args{$_}, "$_ changed" foreach qw/title count wibble/;

  my $id = $new->id;
  my $fetch = Water->retrieve($id);
  isa_ok $new, 'Water', "It was stored";
}

{ # OK Create - missing args
  my %args = %args;
  $args{id} = 404;
  delete $args{title};
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Missing args create)";
  my $new = Water->create_from_cgi($h);
  isa_ok $new, 'Water';
  ok !$new->cgi_update_errors, "No errors";
  is $new->$_(), $args{$_}, "$_ changed" foreach qw/count wibble/;
}

{ # Failed Create
  local $args{id} = 432;
  my $h = CGI::Untaint->new(%args);
  isa_ok $h => 'CGI::Untaint', "(Failed Creation)";
  my $new = Water->create_from_cgi($h);
  isa_ok $new, 'Water';
  ok !$new->cgi_update_errors, "No error";
  is $new->$_(), $args{$_}, "$_ changed" foreach qw/title count wibble/;
}

is (Water->untaint_type('title'), 'printable', "title is printable");
is (Water->untaint_type('count'), 'integer', "count is integer");
is (Water->untaint_type('wibble'), 'integer', "count is integer");
is (Water->untaint_type('foo'), undef, "no type for id");

eval { 
	Water->untaint_columns({
    printable => [qw/title/],
    integer   => [qw/id count wibble/],
	});
};
ok $@, "Can't set up untaints with hashref: $@";


