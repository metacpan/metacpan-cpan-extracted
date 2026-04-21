package DBIx::Wizard;

use strict;
use SQL::Wizard;
use DBIx::Wizard::ResultSet;
use DBIx::Wizard::DB;
use Exporter 'import';

our $VERSION = '0.04';
our @EXPORT = qw(dbiw);

my $sw = SQL::Wizard->new;
my $default_inflate_class = 'Time::Moment';

sub import {
  my $class = shift;

  # Pull out our options before passing to Exporter
  my %opts = @_;
  if ($opts{inflate_class}) {
    $default_inflate_class = $opts{inflate_class};
  }

  # Let Exporter handle @EXPORT
  my $caller = caller;
  no strict 'refs';
  *{"${caller}::dbiw"} = \&dbiw;
}

sub default_inflate_class {
  my ($class, $new) = @_;
  $default_inflate_class = $new if defined $new;
  return $default_inflate_class;
}

sub dbiw {
  # No args: return SQL::Wizard instance for expression building
  return $sw unless @_;

  my ($db, $table) = split /:/, shift;

  # No table: db-only, return DB wrapper for transactions etc.
  if (!$table) {
    return DBIx::Wizard::DB->wrapper($db);
  }

  return DBIx::Wizard::ResultSet->new({
    table        => $table,
    db           => $db,
    inflate      => 1,
  });
}

1;
