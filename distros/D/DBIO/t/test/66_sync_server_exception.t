use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);

use DBIO::Test;
use DBIO::Exception::Server ();

# karr k335, ADR 0062 decision 2026-10-12: the synchronous path raises a
# refused statement as DBIO::Exception::Server too. Storage::DBI's HandleError
# handler (`_dbi_handle_error`) used to throw a plain DBIO::Exception whose text
# was "DBI Exception: $msg" plus the caller; `$h->state` was never read. Now
# the same text goes into a Server object that also carries the handle's
# SQLSTATE, so a caller tells 40001 / 23505 apart without parsing text.
#
# Claim of each block: the text and the DBIO::Exception class are what they
# were (existing catch blocks and =~ keep working); sqlstate comes from the
# handle's state; an error with no state is still a valid object with sqlstate
# undef; nothing but the state is invented.

{
  package K335::Handle;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub state { $_[0]{state} }
}

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;

sub raised_by {
  my ($code) = @_;
  my $ok = eval { $code->(); 1 };
  return $@;
}

# --- the general path: a handle that reports a SQLSTATE ---------------------
{
  my $h = K335::Handle->new(state => '23505');
  my $e = raised_by(sub { $storage->_dbi_handle_error('duplicate key value', $h) });
  ok blessed($e) && $e->isa('DBIO::Exception::Server'), 'a DBIO::Exception::Server';
  ok $e->isa('DBIO::Exception'), 'and still a DBIO::Exception: existing catch blocks keep working';
  is $e->sqlstate, '23505', 'sqlstate is the handle\'s state';
  ok !defined $e->constraint && !defined $e->table && !defined $e->detail,
    'constraint, table and detail stay undef: the handle gave none';
  like "$e", qr/DBI Exception: duplicate key value at \S+ line \d+/,
    'the text is the decorated "DBI Exception: ..." it was, caller included';
  like $e, qr/DBI Exception: duplicate key value/, '=~ on the object';
}

# --- the text is the one the plain exception had ----------------------------
{
  my $plain = raised_by(sub { $storage->throw_exception('DBI Exception: boom') });
  my $e     = raised_by(sub { $storage->_dbi_handle_error('boom', K335::Handle->new(state => '40001')) });
  (my $a = "$plain") =~ s/ at \S+ line \d+\.?\n?$//;
  (my $b = "$e")     =~ s/ at \S+ line \d+\.?\n?$//;
  is $b, $a, 'same text as the DBIO::Exception the handler threw before, bar the line';
  is $e->sqlstate, '40001', 'sqlstate';
}

# --- no state: a valid object, sqlstate undef --------------------------------
for my $state (undef, '', '00000', 'S1000') {
  my $label = defined $state ? "'$state'" : 'undef';
  my $e = raised_by(sub { $storage->_dbi_handle_error('no state here', K335::Handle->new(state => $state)) });
  ok blessed($e) && $e->isa('DBIO::Exception::Server'), "state $label: still the object";
  ok !defined $e->sqlstate, "state $label: sqlstate undef (DBI's \"no SQLSTATE\", not a code)";
  like "$e", qr/DBI Exception: no state here/, "state $label: the text";
}

# --- a handle that cannot say, and no handle at all -------------------------
{
  my $e = raised_by(sub { $storage->_dbi_handle_error('opaque', bless({}, 'K335::NoState')) });
  ok blessed($e) && $e->isa('DBIO::Exception::Server') && !defined $e->sqlstate,
    'a handle without state(): object, sqlstate undef';
  $e = raised_by(sub { $storage->_dbi_handle_error('none') });
  ok blessed($e) && $e->isa('DBIO::Exception::Server') && !defined $e->sqlstate,
    'no handle: object, sqlstate undef';
}

# --- the driver seam: more fields only where the driver has them -------------
{
  {
    package K335::Storage::Rich;
    our @ISA = (ref $storage);
    sub _dbi_error_fields {
      my ($self, $h) = @_;
      return { %{ $self->next::method($h) }, constraint => 'artist_name_key', table => 'artist' };
    }
  }
  require mro;
  mro::set_mro('K335::Storage::Rich', 'c3');
  my $rich = bless { %$storage }, 'K335::Storage::Rich';
  my $e = raised_by(sub { $rich->_dbi_handle_error('dup', K335::Handle->new(state => '23505')) });
  is $e->sqlstate, '23505', 'seam: the base still gives the state';
  is $e->constraint, 'artist_name_key', 'seam: a driver adds constraint';
  is $e->table, 'artist', 'seam: and table';
  ok !defined $e->detail, 'seam: detail stays undef where the driver gave none';
}

# --- a user's exception_action decides as before ------------------------------
{
  my $s2 = DBIO::Test->init_schema;
  my @seen;
  $s2->exception_action(sub { push @seen, $_[0]; die bless({ mine => 1 }, 'K335::Mine') });
  my $e = raised_by(sub { $s2->storage->_dbi_handle_error('x', K335::Handle->new(state => '23505')) });
  isa_ok $e, 'K335::Mine', 'an exception_action that throws its own object keeps it';
  like $seen[0], qr/^DBI Exception: x/, 'exception_action got the text it always got';
}

done_testing;
