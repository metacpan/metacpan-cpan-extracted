package DBomb::Tie::PrimaryKeyList;

=head1 NAME

DBomb::Tie::PrimaryKeyList - A list of primary keys that auto creates objects when fetched.

=head1 SYNOPSIS

  tie @ids, 'DBomb::Tie::PrimaryKeyList', 'MyPackage::Customer';

  ## store plain ids, or PrimaryKey objects in the list
  for (@{$dbh->selectrow_arrayref("SELECT id FROM Customer")){
      push @ids, $_; ## Stores the [id] key.
  }

  ## Later, fetch the ids as objects.
  $customer = $ids[0];
  print $customer-name;

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use Tie::Array;
use base qw(Tie::StdArray);

## We need this because Tie::Array doesn't give us anywhere to store extra data.
my %extra; ## $arr => +{ obj_class => $class }

sub TIEARRAY
{
    my ($class, $obj_class, $values) = @_;
    my $arr = $class->SUPER::TIEARRAY;
    $extra{$arr} = +{};
    $extra{$arr}->{'obj_class'} = $obj_class;

    push @$arr, @$values if $values;
    $arr
}

sub DESTROY
{
    delete $extra{shift};
}

sub FETCH
{
    my ($arr, $ix) = @_;
    my $self = $extra{$arr};

    my $v = $arr->[$ix];
    return undef unless defined $v;

    $v = [$v] unless ref $v;
    if (UNIVERSAL::isa($v, 'ARRAY') || UNIVERSAL::isa($v, 'DBomb::Value::Key')){
        my $obj = $self->{'obj_class'}->new($v);
        return $arr->[$ix] = $obj;
    }
    $v
}

#
#sub STORE
#{
#    my ($self, $ix, $value) = @_;
#}
#
#sub FETCHSIZE
#{
#    my $self = shift;
#}
#
#sub STORESIZE
#{
#    my ($self, $count) = @_;
#}
#
#sub EXTEND
#{
#    my ($self, $count) = @_;
#}
#
#sub EXISTS
#{
#    my ($self, $key) = @_;
#}
#
#sub DELETE
#{
#    my ($self, $key) = @_;
#}
#
#sub CLEAR
#{
#    my $self = shift;
#}
#
#sub PUSH
#{
#    my $self = shift;
## LIST
#}
#
#sub POP
#{
#    my $self = shift;
#}
#
#sub SHIFT
#{
#    my $self = shift;
#}
#
#sub UNSHIFT
#{
#    my $self = shift;
## LIST
#}
#
#sub SPLICE
#{
#    my ($self, $offsef, $length, @list) = @_;
#}
#
#sub UNTIE
#{
#    my $self = shift;
#}
#
1;
__END__
