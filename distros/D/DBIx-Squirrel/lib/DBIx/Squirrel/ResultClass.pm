use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::ResultClass;

use Sub::Name;
use DBIx::Squirrel::Utils qw/throw/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    $DBIx::Squirrel::ResultClass::VERSION = $DBIx::Squirrel::VERSION;
}

use constant E_BAD_OBJECT     => 'A reference to either an array or hash was expected';
use constant E_STH_EXPIRED    => 'Result is no longer associated with a statement';
use constant E_UNKNOWN_COLUMN => 'Unrecognised column (%s)';

sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    return ref($_[0]) ? bless(shift, $class) : shift;
}

sub result_class {
    return shift->results->result_class;
}

BEGIN {
    *row_base_class = *result_class;
}

sub row_class {
    return shift->results->row_class;
}

sub get_column {
    local($_);
    my($self, $name) = @_;
    return unless defined($name);
    if (UNIVERSAL::isa($self, 'ARRAY')) {
        throw E_STH_EXPIRED unless my $sth = $self->rs->sth;
        my $n = $sth->{NAME_lc_hash}{lc($name)};
        throw E_UNKNOWN_COLUMN, $name unless defined($n);
        return $self->[$n];
    }
    else {
        throw E_BAD_OBJECT unless UNIVERSAL::isa($self, 'HASH');
        return $self->{$name} if exists($self->{$name});
        local($_);
        my($n) = grep {lc eq $_[1]} keys(%{$self});
        throw E_UNKNOWN_COLUMN, $name unless defined($n);
        return $self->{$n};
    }
}

# AUTOLOAD is called whenever a row object attempts invoke an unknown
# method. We assume that the missing method is the name of a column, so
# we try to create an accessor asscoiated with that column. There is some
# initial overhead involved in the accessor's validation and creation.
#
# During accessor creation, AUTOLOAD will decide the best strategy for
# geting the column data depending on the underlying row implementation,
# which is determined by the slice type.

our $AUTOLOAD;

sub AUTOLOAD {
    local($_);
    no strict 'refs';    ## no critic
    return if substr($AUTOLOAD, -7) eq 'DESTROY';
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    my($self)    = @_;
    my $symbol   = $self->row_class . '::' . $name;
    my $accessor = do {
        push @{$self->row_class . '::AUTOLOAD_ACCESSORS'}, $symbol;
        # I'm not needlessly copying code from the `get_column` method, but
        # doing the same checks once, before setting up the accessor, just
        # to have the resulting accessor be as fast as it can be!
        if (UNIVERSAL::isa($self, 'ARRAY')) {
            throw E_STH_EXPIRED unless my $sth = $self->rs->sth;
            my $n = $sth->{NAME_lc_hash}{lc($name)};
            throw E_UNKNOWN_COLUMN, $name unless defined($n);
            sub {$_[0][$n]};
        }
        elsif (UNIVERSAL::isa($self, 'HASH')) {
            if (exists($self->{$name})) {
                sub {$_[0]{$name}};
            }
            else {
                local($_);
                my($n) = grep {lc eq $name} keys(%{$self});
                throw E_UNKNOWN_COLUMN, $name unless defined($n);
                sub {$_[0]{$n}};
            }
        }
        else {
            throw E_BAD_OBJECT;
        }
    };
    *{$symbol} = subname($symbol => $accessor);
    goto &{$symbol};
}

1;
