

package Data::Dumper::Again;

use strict;
use warnings;

our $VERSION = '0.01';

# for docs, look for F<Again.pod>

use Data::Dumper ();
use Carp qw(carp croak);

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(ddumper));

# the instance variables
#   ddumper - the Data::Dumper inner object

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $obj = bless {}, $class;
    return $obj->_init(@_);
}

sub _init {
    my $self = shift;
    my %args = @_;

    my $dumper = Data::Dumper->new([]);

    while (my ($k, $v) = each %args) {
        my $p = "\u$k"; # turn into a method name
        if ($dumper->can($p)) {
            #print "invoke $p($v)\n"; # XXX debug for devel
            $dumper->$p($v);
        } else {
            carp "unknown constructor parameter '$k'";
        }
    }
    $self->ddumper($dumper);
    return $self;
}

sub guts {
    return shift->ddumper;
}

# $vname = $self->_varname($wantarray);
sub _varname {
    my $self = shift;
    my $wantarray = shift;
    my $varname = $self->ddumper->Varname;
    return ( $wantarray ? '*' : '$' ) . $varname;
}

# $s = $self->_raw_dump(\@values, \@names);
sub _raw_dump {
    my $self = shift;
    my $values_ref = shift;
    my $names_ref = shift;
    $self->ddumper->Reset; # forget previous invocations
    $self->ddumper->Values( $values_ref );
    $self->ddumper->Names( $names_ref );
    return $self->ddumper->Dump;
}

sub dump {
    my $self = shift;
    my $wantarray = @_ != 1;
    my @values = ( $wantarray ? \@_ : shift );
    my @names =  ( $self->_varname($wantarray) );
    return $self->_raw_dump(\@values, \@names);
}

sub dump_scalar {
    my $self = shift;
    my @values = ( shift );
    my @names =  ( $self->_varname(0) ); # wantarray => 0
    return $self->_raw_dump(\@values, \@names);
}

sub dump_list {
    my $self = shift;
    my @values = ( \@_ );
    my @names =  ( $self->_varname(1) ); # wantarray => 1
    return $self->_raw_dump(\@values, \@names);
}

sub dump_named {
    my $self = shift;
    my @pairs = @_;
    my (@names, @values);
    while (@pairs) {
        my ($n, $v) = splice @pairs, 0, 2;
        push @names, $n;
        push @values, $v;
    }
    return $self->_raw_dump(\@values, \@names);
}

# the following AUTOLOAD sub implements set_*
# and get_* methods

use vars qw($AUTOLOAD);

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    if ($method =~ /[gs]et_(\w+)/) {
        my $prop = "\u$1";
        if ($self->ddumper->can($prop)) {
            return $self->ddumper->$prop(@_);
        } else {
            croak "unknown getter/setter method '$method'"; # XXX
        }
    }
    croak "unknown method '$method'"; # XXX
}

# this avoids invoking AUTOLOAD on destruction

sub DESTROY {}

1;

