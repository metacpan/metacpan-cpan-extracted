use 5.010_001;
use strict;
use warnings;
no strict 'subs';    ## no critic

package              # hide from PAUSE
  DBIx::Squirrel::db;

use DBI;
use Sub::Name;
use DBIx::Squirrel::st    qw/statement_study/;
use DBIx::Squirrel::Utils qw/throw/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    $DBIx::Squirrel::db::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::db::ISA     = qw/DBI::db/;
}

use constant E_EXP_REF       => 'Expected a reference to a HASH or ARRAY';
use constant E_EXP_STATEMENT => 'Expected a statement';

sub _root_class {
    my $root_class = ref($_[0]) || $_[0];
    $root_class =~ s/::\w+$//;
    return RootClass => $root_class if wantarray;
    return $root_class;
}

sub _private_state {
    my $self = shift;
    $self->{private_ekorn} = {} unless defined($self->{private_ekorn});
    unless (@_) {
        return $self->{private_ekorn}, $self if wantarray;
        return $self->{private_ekorn};
    }
    unless (defined($_[0])) {
        delete $self->{private_ekorn};
        shift;
    }
    if (@_) {
        $self->{private_ekorn} = {} unless defined($self->{private_ekorn});
        if (UNIVERSAL::isa($_[0], 'HASH')) {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, %{$_[0]}};
        }
        elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, @{$_[0]}};
        }
        else {
            $self->{private_ekorn} = {%{$self->{private_ekorn}}, @_};
        }
    }
    return $self;
}

sub prepare {
    my $self      = shift;
    my $statement = shift;
    my($placeholders, $normalised_statement, $original_statement, $digest) = statement_study($statement);
    throw E_EXP_STATEMENT unless defined($normalised_statement);
    my $sth = DBI::db::prepare($self, $normalised_statement, @_)
      or throw $DBI::errstr;
    $sth = bless($sth, $self->_root_class . '::st');
    $sth->_private_state({
        Placeholders        => $placeholders,
        NormalisedStatement => $normalised_statement,
        OriginalStatement   => $original_statement,
        Hash                => $digest,
    });
    return $sth;
}

sub prepare_cached {
    my $self      = shift;
    my $statement = shift;
    my($placeholders, $normalised_statement, $original_statement, $digest) = statement_study($statement);
    throw E_EXP_STATEMENT unless defined($normalised_statement);
    my $sth = DBI::db::prepare_cached($self, $normalised_statement, @_)
      or throw $DBI::errstr;
    $sth = bless($sth, $self->_root_class . '::st');
    $sth->_private_state({
        Placeholders        => $placeholders,
        NormalisedStatement => $normalised_statement,
        OriginalStatement   => $original_statement,
        Hash                => $digest,
        CacheKey            => join('#', (caller(0))[1, 2]),
    });
    return $sth;
}

sub do {
    my $self      = shift;
    my $statement = shift;
    my $sth       = do {
        if (@_) {
            if (ref($_[0])) {
                if (UNIVERSAL::isa($_[0], 'HASH')) {
                    my $statement_attributes = shift;
                    $self->prepare($statement, $statement_attributes);
                }
                elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    $self->prepare($statement);
                }
                else {
                    throw E_EXP_REF;
                }
            }
            else {
                if (defined($_[0])) {
                    $self->prepare($statement);
                }
                else {
                    shift;
                    $self->prepare($statement, undef);
                }
            }
        }
        else {
            $self->prepare($statement);
        }
    };
    return $sth->execute(@_), $sth if wantarray;
    return $sth->execute(@_);
}

sub iterate {
    my $self      = shift;
    my $statement = shift;
    my $sth       = do {
        if (@_) {
            if (ref($_[0])) {
                if (UNIVERSAL::isa($_[0], 'HASH')) {
                    my $statement_attributes = shift;
                    $self->prepare($statement, $statement_attributes);
                }
                elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    $self->prepare($statement);
                }
                elsif (UNIVERSAL::isa($_[0], 'CODE')) {
                    $self->prepare($statement);
                }
                else {
                    throw E_EXP_REF;
                }
            }
            else {
                if (defined($_[0])) {
                    $self->prepare($statement);
                }
                else {
                    shift;
                    $self->prepare($statement, undef);
                }
            }
        }
        else {
            $self->prepare($statement);
        }
    };
    return $sth->iterate(@_);
}

BEGIN {
    *iterator = subname(iterator => \&iterate);
    *itor     = subname(itor     => \&iterate);
    *it       = subname(it       => \&iterate);
}

sub results {
    my $self      = shift;
    my $statement = shift;
    my $sth       = do {
        if (@_) {
            if (ref $_[0]) {
                if (UNIVERSAL::isa($_[0], 'HASH')) {
                    my $statement_attributes = shift;
                    $self->prepare($statement, $statement_attributes);
                }
                elsif (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    $self->prepare($statement);
                }
                elsif (UNIVERSAL::isa($_[0], 'CODE')) {
                    $self->prepare($statement);
                }
                else {
                    throw E_EXP_REF;
                }
            }
            else {
                if (defined($_[0])) {
                    $self->prepare($statement);
                }
                else {
                    shift;
                    $self->prepare($statement, undef);
                }
            }
        }
        else {
            $self->prepare($statement);
        }
    };
    return $sth->results(@_);
}

BEGIN {
    *resultset = subname(resultset => \&results);
    *rset      = subname(rset      => \&results);
    *rs        = subname(rs        => \&results);
}

1;
