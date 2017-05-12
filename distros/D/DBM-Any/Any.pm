package DBM::Any;

use strict;
use Carp;
use vars qw(@ISA $VERSION);

$VERSION = '0.1';

=head1 NAME

DBM::Any - object-oriented interface to AnyDBM_File

=head1 SYNOPSIS

  BEGIN { 
    @AnyDBM_File::ISA = qw(DB_File GDBM_File SDBM_File);
  }
  use DBM::Any;

  $db = new DBM::Any($filename, $flags, $mode[, optional...]);

  $val = $db->get($key);

  $db->put($key, $val);

  $db->delete($key);

  if ($db->exists($key)) { ... }

  for my $k ($db->keys()) { ... }

  for my $v ($db->values()) { ... }

  while (($k, $v) = $db->each()) { ... }

  $db->close();

=head1 DESCRIPTION

DBM::Any provides an object-oriented complement to AnyDBM_File's
tied interface.  It was written because it didn't seem to exist on
CPAN, and the author likes BerkeleyDB's object-oriented interface,
but doesn't want to force people to get BerkeleyDB if they don't
want.

The interface is a least common denominator among all available
database types; it contains the basic elements for keeping a
persistent hash on disk.

The methods should map fairly well to regular operations on hashes.
Which is why I won't painstakingly document every method here; you
should already know how to deal with hashes.

DBM::Any Objects should be considered opaque.  Even if you know
what sort of database is underneath, you're a very naughty person
if you attempt to circumvent the prescribed intreface. :-)

=cut

use constant DBM_ANY_TIEREF => 0;
use constant DBM_ANY_HASHREF => 1;

sub new
{
    my $proto = shift;
    my $class = ref($proto)|| $proto;
    if (@_ < 3) {
	croak "Usage: ", __PACKAGE__, "->new(filename, flags, mode[, ...])";
    }
    my $filename = shift;
    my $flags = shift;
    my $mode = shift;
    my @options = @_;
    my $tieref;
    my %tiehash;
    $tieref = tie %tiehash, 'AnyDBM_File', $filename, $flags, $mode, @_;
    return undef unless $tieref;
    return bless [ $tieref, \%tiehash ], $class;
}

sub put
{
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->[DBM_ANY_HASHREF]->{$key} = $value;
}

sub get
{
    my $self = shift;
    my $key = shift;
    return $self->[DBM_ANY_HASHREF]->{$key};
}

sub keys
{
    my $self = shift;
    return keys %{$self->[DBM_ANY_HASHREF]};
}

sub values
{
    my $self = shift;
    return values %{$self->[DBM_ANY_HASHREF]};
}

sub each
{
    my $self = shift;
    return each %{$self->[DBM_ANY_HASHREF]};
}

sub exists
{
    my $self = shift;
    my $key = shift;
    my $r;
    eval { $r = exists $self->[DBM_ANY_HASHREF]->{$key}; };
    if ($@) {
	$r = $self->get($key);
	return defined $r;
    }
    return $r;
}

sub delete 
{
    my $self = shift;
    my $key = shift;
    return delete $self->[DBM_ANY_HASHREF]->{$key};
}

sub close
{
    my $self = shift;
    eval { $self->[DBM_ANY_TIEREF]->sync(); };	## Eh, worth a shot.
    untie $self->[DBM_ANY_HASHREF];
    undef $self->[DBM_ANY_TIEREF];
}

sub DESTROY
{
    $_[0]->close();
}

=head1 BUGS

Currently only supports DB_File access to Sleepycat's Berkeley DB.
I'd like to support BerkeleyDB.pm access as well.  If there is an
elegant solution to this, I need more time to figure it out.

The exists() method could be called on a database format which does
not support a simple existence check.  For these I use a heuristic,
and attempt to retrieve the value associated with the key in
question.  If the value is defined, then we say it exists.  Because of this, I advise against explicit storage 

=head1 AUTHOR

Tony Monroe E<lt>tmonroe+perl@nog.netE<gt>

=head1 SEE ALSO

L<perl>, L<AnyDBM_File>

=cut

1;
__END__
