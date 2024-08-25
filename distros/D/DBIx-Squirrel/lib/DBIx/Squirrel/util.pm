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
        transform   => ['part_args',       'transform',],
        sql => ['get_trimmed_sql_and_digest', 'normalise_statement', 'study_statement', 'trim_sql_string', 'hash_sql_string',],
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

memoize('uniq');

sub uniq {
    my %seen;
    return grep {!$seen{$_}++} @_;
}

memoize('is_viable_sql_string');

sub is_viable_sql_string {
    return defined($_[0]) && length($_[0]) && $_[0] =~ m/\S/;
}

memoize('study_statement');

sub study_statement {
    my($normalised, $trimmed_sql, $digest) = &normalise_statement;
    return unless is_viable_sql_string($trimmed_sql);
    my @placeholders = $trimmed_sql =~ m{[\:\$\?]\w+\b}g;
    my $mapped_positions;
    if (@placeholders) {
        $mapped_positions = {map {(1 + $_ => $placeholders[$_])} (0 .. $#placeholders),};
    }
    return $mapped_positions, $normalised, $trimmed_sql, $digest;
}

sub normalise_statement {
    my($trimmed_sql, $digest) = &get_trimmed_sql_and_digest;
    my $normalised = $trimmed_sql;
    $normalised =~ s{[\:\$\?]\w+\b}{?}g if $NORMALISE_SQL;
    return $normalised unless wantarray;
    return $normalised, $trimmed_sql, $digest;
}

sub get_trimmed_sql_and_digest {
    my $sth_or_sql_string = shift;
    my $sql_string        = do {
        if (ref $sth_or_sql_string) {
            if (UNIVERSAL::isa($sth_or_sql_string, 'DBIx::Squirrel::st')) {
                trim_sql_string($sth_or_sql_string->_private->{OriginalStatement});
            }
            elsif (UNIVERSAL::isa($sth_or_sql_string, 'DBI::st')) {
                trim_sql_string($sth_or_sql_string->{Statement});
            }
            else {
                throw E_EXP_STH;
            }
        }
        else {
            trim_sql_string($sth_or_sql_string);
        }
    };
    return $sql_string unless wantarray;
    return $sql_string, hash_sql_string($sql_string);
}

memoize('trim_sql_string');

sub trim_sql_string {
    return do {
        if (&is_viable_sql_string) {
            my $sql = shift;
            $sql =~ s{\s+-{2}\s+.*$}{}gm;
            $sql =~ s{^[[:blank:]\r\n]+}{}gm;
            $sql =~ s{[[:blank:]\r\n]+$}{}gm;
            $sql;
        }
        else {
            '';
        }
    };
}

memoize('hash_sql_string');

sub hash_sql_string {
    return do {
        if (&is_viable_sql_string) {
            &sha256_base64;
        }
        else {
            undef;
        }
    };
}

sub part_args {
    my @args = reverse(@_);
    my @coderefs;
    unshift @coderefs, shift(@args) while UNIVERSAL::isa($args[0], 'CODE');
    return \@coderefs, @args;
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
    return @_         if wantarray;
    return scalar(@_) if @_;
    return do {$_ = $_[0]};
}

1;
