use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::st;

require Digest::SHA;

use Exporter ();
use Sub::Name 'subname';
use DBIx::Squirrel::util qw(
    confessf
    cluckf
);
use namespace::clean;

use constant E_EXP_STH             => 'Expected a statement handle';
use constant E_INVALID_PLACEHOLDER => 'Cannot bind invalid placeholder (%s)';
use constant W_ODD_NUMBER_OF_ARGS =>
    'Check bind values match placeholder scheme';

BEGIN {
    require DBIx::Squirrel
        unless keys %DBIx::Squirrel::;
    *DBIx::Squirrel::st::VERSION = *DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::st::ISA     = qw(
        DBI::st
        Exporter
    );
    %DBIx::Squirrel::st::EXPORT_TAGS = ( all => [
        @DBIx::Squirrel::st::EXPORT_OK = qw(
            statement_digest
            statement_normalise
            statement_study
            statement_trim
        )
    ] );
}

our $FINISH_ACTIVE_BEFORE_EXECUTE = !!1;
our $STATEMENT_DIGEST             = sub {
    goto &Digest::SHA::sha256_base64;
};

sub _private_state {
    my $self = shift;
    $self->{private_ekorn} = {} unless defined $self->{private_ekorn};
    unless (@_) {
        return $self->{private_ekorn}, $self if wantarray;
        return $self->{private_ekorn};
    }
    unless ( defined $_[0] ) {
        delete $self->{private_ekorn};
        shift;
    }
    if (@_) {
        if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
            $self->{private_ekorn} = { %{ $self->{private_ekorn} }, %{ $_[0] } };
        }
        else {
            $self->{private_ekorn} = { %{ $self->{private_ekorn} }, @_ };
        }
    }
    return $self;
}

sub _placeholders_confirm_positional {
    my $self         = shift;
    my $placeholders = $self->_private_state->{Placeholders};
    my @placeholders = values %{$placeholders};
    my $total_count  = @placeholders;
    my $count        = do {
        local($_);
        grep { m/^[\:\$\?]\d+$/ } @placeholders;
    };
    return unless $count == $total_count;
    return $placeholders;
}

sub _placeholders_map_to_values {
    my $self       = shift;
    my $positional = $self->_placeholders_confirm_positional;
    my @mappings   = do {
        local($_);
        if ($positional) {
            map { ( $positional->{$_} => $_[ $_ - 1 ] ) } keys %{$positional};
        }
        else {
            if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
                %{ $_[0] };
            }
            else {
                if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    cluckf W_ODD_NUMBER_OF_ARGS unless @{ $_[0] } && @{ $_[0] } % 2 == 0;
                    @{ $_[0] };
                }
                else {
                    cluckf W_ODD_NUMBER_OF_ARGS unless @_ && @_ % 2 == 0;
                    @_;
                }
            }
        }
    };
    return wantarray ? @mappings : \@mappings;
}

sub bind {
    my $self = shift;
    if (@_) {
        if ( $self->_placeholders_confirm_positional ) {
            if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                $self->bind_param( $_, $_[0][ $_ - 1 ] ) for 1 .. scalar @{ $_[0] };
            }
            else {
                $self->bind_param( $_, $_[ $_ - 1 ] ) for 1 .. scalar @_;
            }
        }
        else {
            if ( my %kv = @{ $self->_placeholders_map_to_values(@_) } ) {
                while ( my( $k, $v ) = each %kv ) {
                    if ( $k =~ m/^[\:\$\?]?(?<bind_id>\d+)$/ ) {
                        confessf E_INVALID_PLACEHOLDER, $k unless $+{bind_id};
                        $self->bind_param( $+{bind_id}, $v );
                    }
                    else {
                        $self->bind_param( $k, $v );
                    }
                }
            }
        }
    }
    return $self;
}

sub bind_param {
    my $self = shift;
    my @args = do {
        my( $param, $value, @attr ) = @_;
        my $placeholders = $self->_private_state->{Placeholders};
        if ($placeholders) {
            if ( $param =~ m/^[\:\$\?]?(?<bind_id>\d+)$/ ) {
                $+{bind_id}, $value, @attr;
            }
            else {
                local($_);
                map { ( $_, $value, @attr ) } do {
                    if ( $param =~ m/^[\:\$\?]/ ) {
                        grep { $placeholders->{$_} eq $param } keys %{$placeholders};
                    }
                    else {
                        grep { $placeholders->{$_} eq ":$param" } keys %{$placeholders};
                    }
                };
            }
        }
        else {
            $param, $value, @attr;
        }
    };
    return unless $self->SUPER::bind_param(@args);
    return wantarray ? @args : \@args;
}

sub execute {
    my $self = shift;
    $self->finish   if $FINISH_ACTIVE_BEFORE_EXECUTE && $self->{Active};
    $self->bind(@_) if @_;
    return $self->SUPER::execute;
}

sub iterate {
    return DBIx::Squirrel::it->new(@_);
}

BEGIN {
    *iterator = subname( iterator => \&iterate );
    *itor     = subname( itor     => \&iterate );
    *it       = subname( it       => \&iterate );
}

sub results {
    return DBIx::Squirrel::rs->new(@_);
}

BEGIN {
    *resultset = subname( resultset => \&results );
    *rset      = subname( rset      => \&results );
    *rs        = subname( rs        => \&results );
}

sub statement_digest {
    return $STATEMENT_DIGEST->(@_);
}

sub statement_normalise {
    my $statement  = statement_trim(shift);
    my $normalised = $statement;
    $normalised =~ s{[\:\$\?]\w+\b}{?}g;
    return $normalised, $statement, statement_digest($statement);
}

sub statement_study {
    my( $normal, $trimmed, $digest ) = statement_normalise(shift);
    return unless length $trimmed;
    my %positions_to_params_map = do {
        if ( my @params = $trimmed =~ m{[\:\$\?]\w+\b}g ) {
            local($_);
            map { 1 + $_ => $params[$_] } 0 .. $#params;
        }
        else {
            ();
        }
    };
    return \%positions_to_params_map, $normal, $trimmed, $digest;
}

sub statement_trim {
    my $statement = do {
        if ( ref $_[0] ) {
            if ( UNIVERSAL::isa( $_[0], 'DBIx::Squirrel::st' ) ) {
                shift->_private_state->{OriginalStatement};
            }
            elsif ( UNIVERSAL::isa( $_[0], 'DBI::st' ) ) {
                shift->{Statement};
            }
            else {
                confessf(E_EXP_STH);
            }
        }
        else {
            defined $_[0] ? shift : '';
        }
    };
    $statement        =~ s{\s+--\s+.*$}{}gm;
    $statement        =~ s{^[[:blank:]\r\n]+}{}gm;
    $statement        =~ s{[[:blank:]\r\n]+$}{}gm;
    return $statement =~ m/\S/ ? $statement : '';
}

1;
