use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::util;

BEGIN {
    require Exporter;
    @DBIx::Squirrel::util::ISA         = 'Exporter';
    %DBIx::Squirrel::util::EXPORT_TAGS = (
        constants   => ['E_EXP_STATEMENT', 'E_EXP_STH', 'E_EXP_REF',],
        diagnostics => ['throw',           'whine',],
        transform   => ['args_partition',  'transform',],
        sql         => ['statement_trim',  'statement_normalise', 'statement_study', 'sql_trim', 'sql_digest',],
    );
    @DBIx::Squirrel::util::EXPORT_OK = @{
        $DBIx::Squirrel::util::EXPORT_TAGS{all} = [
            qw/
              global_destruct_phase
              uniq
              result
              /,
            do {
                my %seen;
                grep {!$seen{$_}++}
                  map {@{$DBIx::Squirrel::util::EXPORT_TAGS{$_}}} qw/constants diagnostics sql transform/,;
            },
        ]
    };
}

use Carp                     ();
use Devel::GlobalDestruction ();
use Digest::SHA              qw/sha256_base64/;
use Memoize;
use Scalar::Util;
use Sub::Name;

use constant E_EXP_STATEMENT => 'Expected a statement';
use constant E_EXP_STH       => 'Expected a statement handle';
use constant E_EXP_REF       => 'Expected a reference to a HASH or ARRAY';
use constant E_BAD_CB_LIST   => 'Expected a reference to a list of code-references, a code-reference, or undefined';

our $NORMALISE_SQL = !!1;

# Perl versions older than 5.14 do not support ${^GLOBAL_PHASE}, so provide
# a shim that works around the wrinkle.
sub global_destruct_phase {Devel::GlobalDestruction::in_global_destruction()}

sub throw {
    @_ = do {
        if (@_) {
            my($f, @a) = @_;
            if (@a) {
                sprintf $f, @a;
            }
            else {
                defined($f) ? $f : 'Exception';
            }
        } ## end if ( @_ )
        else {
            defined($@) ? $@ : 'Exception';
        }
    };
    goto &Carp::confess;
}

sub whine {
    @_ = do {
        if (@_) {
            my($f, @a) = @_;
            if (@a) {
                sprintf($f, @a);
            }
            else {
                defined($f) ? $f : 'Warning';
            }
        } ## end if ( @_ )
        else {
            'Warning';
        }
    };
    goto &Carp::cluck;
}

sub uniq {
    my %seen;
    return grep {!$seen{$_}++} @_;
}

sub statement_study {
    my($normal, $trimmed, $digest) = statement_normalise(@_);
    return unless length($trimmed);
    my %positions_to_params_map = do {
        if (my @params = $trimmed =~ m{[\:\$\?]\w+\b}g) {
            map {(1 + $_ => $params[$_])} 0 .. $#params;
        }
        else {
            ();
        }
    };
    return \%positions_to_params_map, $normal, $trimmed, $digest;
}

sub statement_normalise {
    my $trimmed = statement_trim(@_);
    my $normal  = $trimmed;
    $normal =~ s{[\:\$\?]\w+\b}{?}g if $NORMALISE_SQL;
    return $normal, $trimmed, sql_digest($trimmed);
}

sub statement_trim {
    my $sth_or_sql = shift;
    if (ref($sth_or_sql)) {
        if (UNIVERSAL::isa($sth_or_sql, 'DBIx::Squirrel::st')) {
            return sql_trim($sth_or_sql->_private_state->{OriginalStatement});
        }
        elsif (UNIVERSAL::isa($sth_or_sql, 'DBI::st')) {
            return sql_trim($sth_or_sql->{Statement});
        }
        else {
            throw E_EXP_STH;
        }
    }
    else {
        return sql_trim($sth_or_sql);
    }
}

memoize('sql_digest');

sub sql_digest {
    return sha256_base64(shift);
}

memoize('sql_trim');

sub sql_trim {
    my $sql = defined($_[0]) && !ref($_[0]) ? shift : '';
    $sql        =~ s{\s+--\s+.*$}{}gm;
    $sql        =~ s{^[[:blank:]\r\n]+}{}gm;
    $sql        =~ s{[[:blank:]\r\n]+$}{}gm;
    return $sql =~ m/\S/ ? $sql : '';
}

sub args_partition {
    my $s = scalar(@_);
    my $n = $s;
    return ([]) unless $n;
    while ($n) {
        last unless UNIVERSAL::isa($_[$n - 1], 'CODE');
        $n -= 1;
    }
    return ([], @_) if $n == $s;
    return ([@_])   if $n == 0;
    return ([@_[$n .. $#_]], @_[0 .. $n - 1]);
}

# Runtime scoping of $_result allows caller to import and use "result" instead
# of "$_" during result transformation.

our $_result;

sub result {$_result}

sub transform {
    my @transforms = do {
        if (UNIVERSAL::isa($_[0], 'ARRAY')) {
            @{+shift};
        }
        elsif (UNIVERSAL::isa($_[0], 'CODE')) {
            shift;
        }
        else {
            ();
        }
    };
    if (@transforms && @_) {
        for my $transform (@transforms) {
            last unless @_ = do {
                local($_result) = @_;
                local($_)       = $_result;
                $transform->(@_);
            };
        }
    }
    return @_ if wantarray;
    $_ = $_[0];
    return scalar(@_) if @_;
}

1;
