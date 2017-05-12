package DBIx::ThinSQL;
use strict;
use warnings;
use DBI;
use Exporter::Tidy
  other => [qw/ bv qv qi sq func OR AND /],
  sql   => [
    qw/
      case
      cast
      coalesce
      concat
      count
      exists
      hex
      length
      lower
      ltrim
      max
      min
      replace
      rtrim
      substr
      sum
      upper
      /
  ];

our @ISA     = 'DBI';
our $VERSION = '0.0.48';

sub ejoin {
    my $joiner = shift;
    return unless @_;

    my @tokens = map { $_, $joiner } @_;
    pop @tokens;

    return @tokens;
}

sub func {
    my $func   = uc shift;
    my $joiner = shift;

    return DBIx::ThinSQL::expr->new( $func, '(',
        DBIx::ThinSQL::ejoin( $joiner, @_ ), ')' );
}

sub bv { DBIx::ThinSQL::expr->new( DBIx::ThinSQL::bind_value->new(@_) ) }

sub qv { DBIx::ThinSQL::expr->new( DBIx::ThinSQL::quote_value->new(@_) ) }

sub qi { DBIx::ThinSQL::expr->new( DBIx::ThinSQL::quote_identifier->new(@_) ) }

sub OR { ' OR ' }

sub AND { ' AND ' }

sub cast { func( 'cast', ' ', @_ ) }

sub case { DBIx::ThinSQL::case->new(@_) }

sub coalesce { func( 'coalesce', ', ', @_ ) }

sub concat { DBIx::ThinSQL::expr->new( DBIx::ThinSQL::ejoin( ' || ', @_ ) ) }

sub count { func( 'count', ', ', @_ ) }

sub exists { func( 'exists', ', ', @_ ) }

sub hex { func( 'hex', ', ', @_ ) }

sub length { func( 'length', ', ', @_ ) }

sub lower { func( 'lower', ', ', @_ ) }

sub ltrim { func( 'ltrim', ', ', @_ ) }

sub max { func( 'max', ', ', @_ ) }

sub min { func( 'min', ', ', @_ ) }

sub replace { func( 'replace', ', ', @_ ) }

sub rtrim { func( 'rtrim', ', ', @_ ) }

sub substr { func( 'substr', ', ', @_ ) }

sub sq { DBIx::ThinSQL::query->new(@_) }

sub sum { func( 'sum', '', @_ ) }

sub upper { func( 'upper', ', ', @_ ) }

package DBIx::ThinSQL::db;
use strict;
use warnings;
use Carp ();
use Log::Any '$log';
use DBIx::ThinSQL::Driver;

our @ISA = qw(DBI::db);
our @CARP_NOT;

sub share_dir {
    require Path::Tiny;

    return Path::Tiny::path($DBIX::ThinSQL::SHARE_DIR)
      if defined $DBIX::ThinSQL::SHARE_DIR;

    require File::ShareDir;
    return Path::Tiny::path( File::ShareDir::dist_dir('DBIx-ThinSQL') );
}

sub throw_error {
    my $self = shift;
    Carp::croak(@_);
}

sub sql_bv {
    my $self   = shift;
    my $sql    = shift;
    my $bv     = shift;
    my $val    = shift;
    my $prefix = shift;

    $prefix = '' unless length($prefix);

    my $ref     = ref $val;
    my $prefix2 = $prefix . '    ';

    # When we call ourself we already have a ref

    if ( $ref eq '' ) {
        $$sql .= defined $val ? $val : 'NULL';
    }
    elsif ( $ref eq 'DBIx::ThinSQL::query' ) {
        my $bracket = length($prefix) ? '(' : '';
        foreach my $pair ( $val->tokens ) {
            $$sql .= "\n" if $pair->[0] =~ /UNION/;
            my $join_on = length( $pair->[0] )
              && ( $pair->[0] =~ m/(JOIN)|(ON)/ ) ? '  ' : '';
            $$sql .=
              ( $bracket || $prefix . $join_on ) . $pair->[0] . "\n" . $prefix2
              if length( $pair->[0] );
            $self->sql_bv( $sql, $bv, $pair->[1], $prefix2 );
            $$sql .= "\n" if length( $pair->[0] ) or length( $pair->[1] );
            $bracket = '';
        }
        $$sql .= $prefix . ")" if length($prefix);
    }
    elsif ( $ref eq 'DBIx::ThinSQL::list' ) {
        my @tokens = $val->tokens;
        my $last   = pop @tokens;
        my $i      = 0;
        foreach my $token (@tokens) {
            $$sql .= $prefix if $i++;
            $self->sql_bv( $sql, $bv, $token, $prefix );
            $$sql .= ",\n";
        }
        $$sql .= $prefix;
        $self->sql_bv( $sql, $bv, $last, $prefix );
    }
    elsif ( $ref eq 'DBIx::ThinSQL::table' ) {
        my @tokens = $val->tokens;
        my $table  = shift @tokens;
        $$sql .= $table . "(\n";

        my $last = pop @tokens;
        foreach my $token (@tokens) {
            $$sql .= $prefix2;
            $self->sql_bv( $sql, $bv, $token, $prefix2 );
            $$sql .= ",\n";
        }
        $$sql .= $prefix2;
        $self->sql_bv( $sql, $bv, $last, $prefix2 );
        $$sql .= "\n" . $prefix . ")";
    }
    elsif ( $ref eq 'DBIx::ThinSQL::values' ) {
        my @tokens = $val->tokens;
        $$sql .= "(\n";

        my $last = pop @tokens;
        foreach my $token (@tokens) {
            $$sql .= $prefix2;
            $self->sql_bv( $sql, $bv, $token, $prefix2 );
            $$sql .= ",\n";
        }
        $$sql .= $prefix2;
        $self->sql_bv( $sql, $bv, $last, $prefix2 );
        $$sql .= "\n" . $prefix . ")";
    }
    elsif ( $ref eq 'DBIx::ThinSQL::case' ) {
        $$sql .= "CASE\n";
        my @tokens = $val->tokens;
        foreach my $pair (@$val) {
            $$sql .= $prefix2 . $pair->[0] . "\n" . $prefix2 . '    ';
            $self->sql_bv( $sql, $bv, $pair->[1], $prefix2 );
            $$sql .= "\n";
        }
        $$sql .= $prefix . "END";
    }
    elsif ( $ref eq 'DBIx::ThinSQL::expr' ) {
        foreach my $token ( $val->tokens ) {
            $self->sql_bv( $sql, $bv, $token, $prefix );
        }
    }
    elsif ( $ref eq 'DBIx::ThinSQL::bind_value' ) {
        $$sql .= '?';
        push( @{$bv}, $val );
    }
    elsif ( $ref eq 'DBIx::ThinSQL::quote_value' ) {
        $$sql .= $self->quote( $val->for_quote );
    }
    elsif ( $ref eq 'DBIx::ThinSQL::quote_identifier' ) {
        $$sql .= $self->quote_identifier( $val->val );
    }
    else {
        Carp::cluck "sql_bv doesn't know $ref";
    }
}

sub query {
    my $self = shift;
    my ( $sql, @bv ) = ('');
    $self->sql_bv( \$sql, \@bv, DBIx::ThinSQL::query->new(@_) );
    return $sql . ";\n", @bv;
}

sub xprepare {
    my $self = shift;
    Carp::croak('xprepare requires arguments!') unless @_;

    my ( $sql, @bv ) = $self->query(@_);

    # TODO these locals have no effect?
    local $self->{RaiseError}         = 1;
    local $self->{PrintError}         = 0;
    local $self->{ShowErrorStatement} = 1;

    my $prepare_ok;
    my $sth;
    my $prepare =
      exists $self->{'_dbix_thinsql_prepare_cached'}
      ? 'prepare_cached'
      : 'prepare';

    eval {
        $sth        = $self->$prepare($sql);
        $prepare_ok = 1;

        my $i = 1;
        foreach my $bv (@bv) {
            $sth->bind_param( $i++, $bv->for_bind_param );
        }
    };

    if ($@) {
        $log->debug($sql) unless $prepare_ok;
        $self->throw_error($@);
    }

    return $sth;
}

sub xprepare_cached {
    my $self = shift;
    local $self->{'_dbix_thinsql_prepare_cached'} = 1;
    return $self->xprepare(@_);
}

sub xdo {
    my $self = shift;
    my $sth  = $self->xprepare(@_);
    return $sth->execute;
}

sub log_debug {
    my $self = shift;
    my $sql  = (shift) . "\n";

    my $sth = $self->prepare( $sql . ';' );
    $sth->execute(@_);

    my $out = join( ', ', @{ $sth->{NAME} } ) . "\n";
    $out .= '  ' . ( '-' x length $out ) . "\n";
    $out .= '  ' . DBI::neat_list($_) . "\n" for @{ $sth->fetchall_arrayref };
    $log->debug($out);
}

sub log_warn {
    my $self = shift;
    my $sql  = (shift) . "\n";

    my $sth = $self->prepare( $sql . ';' );
    $sth->execute(@_);

    my $out = join( ', ', @{ $sth->{NAME} } ) . "\n";
    $out .= '  ' . ( '-' x length $out ) . "\n";
    $out .= '  ' . DBI::neat_list($_) . "\n" for @{ $sth->fetchall_arrayref };
    warn $out;
}

sub dump {
    my $self = shift;
    my $sth  = $self->prepare(shift);
    $sth->execute(@_);
    $sth->dump_results;
}

sub xdump {
    my $self = shift;
    my $sth  = $self->xprepare(@_);
    $sth->execute;
    $sth->dump_results;
}

sub xval {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;
    my $ref = $sth->arrayref;
    $sth->finish;

    return $ref->[0] if $ref;
    return;
}

sub xvals {
    my $self = shift;
    my $sth  = $self->xprepare(@_);
    $sth->execute;
    return $sth->vals;
}

sub xlist {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;
    my $ref = $sth->arrayref;
    $sth->finish;

    return @$ref if $ref;
    return;
}

sub xarrayref {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;
    my $ref = $sth->arrayref;
    $sth->finish;

    return $ref if $ref;
    return;
}

sub xarrayrefs {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;

    return $sth->arrayrefs;
}

sub xhashref {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;
    my $ref = $sth->hashref;
    $sth->finish;

    return $ref if $ref;
    return;
}

sub xhashrefs {
    my $self = shift;

    my $sth = $self->xprepare(@_);
    $sth->execute;
    return $sth->hashrefs;
}

# Can't use 'local' to managed txn count here because $self is a tied hashref?
# Also can't use ||=.
sub txn {
    my $self      = shift;
    my $subref    = shift;
    my $wantarray = wantarray;
    my $txn       = $self->{private_DBIx_ThinSQL_txn}++;
    my $driver    = $self->{private_DBIx_ThinSQL_driver};

    $driver ||= $self->{private_DBIx_ThinSQL_driver} = do {
        my $class = 'DBIx::ThinSQL::Driver::' . $self->{Driver}->{Name};
        ( my $path = $class ) =~ s{::}{/}g;
        $path .= '.pm';

        eval { require $path; $class->new } || DBIx::ThinSQL::Driver->new;
    };

    my $current;
    if ( !$txn ) {
        $current = {
            RaiseError         => $self->{RaiseError},
            ShowErrorStatement => $self->{ShowErrorStatement},
        };

    }

    $self->{RaiseError} = 1 unless exists $self->{HandleError};
    $self->{ShowErrorStatement} = 1;

    my @result;
    my $result;

    if ( !$txn ) {
        $self->begin_work;
    }
    else {
        $driver->savepoint( $self, 'txn' . $txn );
    }

    eval {

        if ($wantarray) {
            @result = $subref->();
        }
        else {
            $result = $subref->();
        }

        if ( !$txn ) {

            # We check again for the AutoCommit state in case the
            # $subref did something like its own ->rollback(). This
            # really just prevents a warning from being printed.
            $self->commit unless $self->{AutoCommit};
        }
        else {
            $driver->release( $self, 'txn' . $txn )
              unless $self->{AutoCommit};
        }

    };
    my $error = $@;

    $self->{private_DBIx_ThinSQL_txn} = $txn;
    if ( !$txn ) {
        $self->{RaiseError}         = $current->{RaiseError};
        $self->{ShowErrorStatement} = $current->{ShowErrorStatement};
    }

    if ($error) {

        eval {
            if ( !$txn ) {

                # If the transaction failed at COMMIT, then we can no
                # longer roll back. Maybe put this around the eval for
                # the RELEASE case as well??
                $self->rollback unless $self->{AutoCommit};
            }
            else {
                $driver->rollback_to( $self, 'txn' . $txn )
                  unless $self->{AutoCommit};
            }
        };

        $self->throw_error(
            $error . "\nAdditionally, an error occured during
                  rollback:\n$@"
        ) if $@;

        $self->throw_error($error);
    }

    return $wantarray ? @result : $result;
}

package DBIx::ThinSQL::st;
use strict;
use warnings;

our @ISA = qw(DBI::st);

sub val {
    my $self = shift;
    my $ref = $self->fetchrow_arrayref || return;
    return $ref->[0];
}

sub vals {
    my $self = shift;
    my $all = $self->fetchall_arrayref || return;
    return unless @$all;
    return map { $_->[0] } @$all if wantarray;
    return [ map { $_->[0] } @$all ];
}

sub list {
    my $self = shift;
    my $ref = $self->fetchrow_arrayref || return;
    return @$ref;
}

sub arrayref {
    my $self = shift;
    return unless $self->{Active};
    return $self->fetchrow_arrayref;
}

sub arrayrefs {
    my $self = shift;
    return unless $self->{Active};

    my $all = $self->fetchall_arrayref || return;
    return unless @$all;
    return @$all if wantarray;
    return $all;
}

sub hashref {
    my $self = shift;
    return unless $self->{Active};

    return $self->fetchrow_hashref('NAME_lc');
}

sub hashrefs {
    my $self = shift;
    return unless $self->{Active};

    my @all;
    while ( my $ref = $self->fetchrow_hashref('NAME_lc') ) {
        push( @all, $ref );
    }

    return @all if wantarray;
    return \@all;
}

package DBIx::ThinSQL::bind_value;
use strict;
use warnings;
our @ISA = ('DBIx::ThinSQL::expr');

sub new {
    my $class = shift;
    return $_[0]  if ref( $_[0] ) =~ m/DBIx::ThinSQL/;
    return $$_[0] if ref $_[0] eq 'SCALAR';
    return bless [@_], $class;
}

sub val {
    return $_[0]->[0];
}

sub type {
    return $_[0]->[1];
}

sub for_bind_param {
    my $self = shift;

    # value, type
    return @$self if defined $self->[1];

    # value
    return $self->[0];
}

package DBIx::ThinSQL::quote_value;
use strict;
use warnings;
our @ISA = ('DBIx::ThinSQL::expr');

sub new {
    my $class = shift;
    return $_[0]  if ref( $_[0] ) =~ m/DBIx::ThinSQL/;
    return $$_[0] if ref $_[0] eq 'SCALAR';
    return bless [@_], $class;
}

sub val {
    return $_[0]->[0];
}

sub type {
    return $_[0]->[1];
}

sub for_quote {
    my $self = shift;

    # value, type
    return @$self if defined $self->[1];

    # value
    return $self->[0];
}

package DBIx::ThinSQL::quote_identifier;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $id    = shift;
    return bless \$id, $class;
}

sub val {
    my $self = shift;
    return $$self;
}

package DBIx::ThinSQL::expr;
use strict;
use warnings;

sub new {
    my $class = shift;
    my @tokens;
    foreach my $token (@_) {
        if ( ref $token eq 'ARRAY' ) {
            push( @tokens, DBIx::ThinSQL::query->new(@$token) );
        }
        elsif ( ref $token eq 'HASH' ) {
            my @cols = sort keys %$token;
            my $narg;

            foreach my $col (@cols) {
                if ( ref $token->{$col} eq 'SCALAR' ) {
                    $narg->{$col} = ${ $token->{$col} };
                }
                elsif ( ref $token->{$col} eq 'ARRAY' ) {
                    $narg->{$col} =
                      [ map { DBIx::ThinSQL::bind_value->new($_) }
                          @{ $token->{$col} } ];
                }
                elsif ( defined $token->{$col} ) {
                    $narg->{$col} =
                      DBIx::ThinSQL::bind_value->new( $token->{$col} );
                }
            }

            foreach my $col (@cols) {
                my $val = $narg->{$col};

                my $like     = $col =~ s/\s+like$/ LIKE /i;
                my $not_like = $col =~ s/\s+(!|not)\s*like$/ NOT LIKE /i;
                my $not      = $col =~ s/\s*!$//;
                my $gtlt     = $col =~ s/(\s+[><]=?)$/$1 /;

                push( @tokens, $col );
                if ( !defined $val ) {
                    push( @tokens, ' IS ', $not ? 'NOT NULL' : 'NULL' );
                }
                elsif ( ref $val eq 'ARRAY' ) {
                    push( @tokens, ' NOT' ) if $not;
                    push( @tokens, ' IN (', map { $_, ',' } @$val );
                    pop(@tokens) if @$val;
                    push( @tokens, ')' );
                }
                else {
                    push( @tokens, $not ? ' != ' : ' = ' )
                      unless $like
                      or $not_like
                      or $gtlt;

                    push( @tokens, $val );
                }
                push( @tokens, ' AND ' );
            }
            pop @tokens;
        }
        else {
            push( @tokens, $token );
        }
    }
    return bless \@tokens, $class;
}

sub as {
    my $self  = shift;
    my $value = shift;

    return DBIx::ThinSQL::expr->new( $self, ' AS ',
        DBIx::ThinSQL::quote_identifier->new($value) );
}

sub tokens {
    my $self = shift;
    return @$self;
}

package DBIx::ThinSQL::case;
use strict;
use warnings;
our @ISA = ('DBIx::ThinSQL::expr');

sub new {
    my $class = shift;
    my @tokens;

    while ( my ( $key, $val ) = splice( @_, 0, 2 ) ) {
        ( $key = uc($key) ) =~ s/_/ /g;
        push( @tokens, [ $key, DBIx::ThinSQL::expr->new($val) ] );
    }

    return bless \@tokens, $class;
}

package DBIx::ThinSQL::list;
use strict;
use warnings;

sub new {
    my $class = shift;
    my @tokens;
    foreach my $token (@_) {
        if ( ref $token eq 'ARRAY' ) {
            push( @tokens, DBIx::ThinSQL::query->new(@$token) );
        }
        else {
            push( @tokens, $token );
        }
    }
    return bless \@tokens, $class;
}

sub tokens {
    my $self = shift;
    return @$self;
}

package DBIx::ThinSQL::table;
our @ISA = ('DBIx::ThinSQL::list');

package DBIx::ThinSQL::values;
our @ISA = ('DBIx::ThinSQL::list');

package DBIx::ThinSQL::query;
use strict;
use warnings;

sub new {
    my $class = shift;
    my @query;

    eval {
        while ( my ( $word, $arg ) = splice( @_, 0, 2 ) ) {
            ( $word = uc($word) ) =~ s/_/ /g;
            my $ref = ref $arg;

            if ( $ref =~ m/^DBIx::ThinSQL/ ) {
                push( @query, [ $word, $arg ] );
            }
            elsif ( $ref eq 'ARRAY' ) {
                if ( $word =~ m/((SELECT)|(ORDER)|(GROUP))/ ) {
                    push( @query, [ $word, DBIx::ThinSQL::list->new(@$arg) ] );
                }
                elsif ( $word =~ m/INSERT/ ) {
                    push( @query, [ $word, DBIx::ThinSQL::table->new(@$arg) ] );
                }
                elsif ( $word =~ m/(^AS$)|(FROM)|(JOIN)/ ) {
                    push( @query, [ $word, DBIx::ThinSQL::query->new(@$arg) ] );
                }
                elsif ( $word eq 'VALUES' ) {
                    push(
                        @query,
                        [
                            $word,
                            DBIx::ThinSQL::values->new(
                                map { DBIx::ThinSQL::bind_value->new($_) }
                                  @$arg
                            )
                        ]
                    );
                }
                else {
                    push( @query, [ $word, DBIx::ThinSQL::expr->new(@$arg) ] );
                }
            }
            elsif ( $ref eq 'HASH' ) {

                if ( $word =~ m/^((WHERE)|(ON))/ ) {
                    push( @query, [ $word, DBIx::ThinSQL::expr->new($arg) ] );
                }
                elsif ( $word eq 'SET' ) {
                    my @cols = sort keys %$arg;
                    push(
                        @query,
                        [
                            $word,
                            DBIx::ThinSQL::list->new(
                                map {
                                    DBIx::ThinSQL::expr->new(

                                        # quote_identifier?
                                        $_, ' = ',
                                        ref $arg->{$_} eq 'SCALAR'
                                        ? ${ $arg->{$_} }
                                        : DBIx::ThinSQL::bind_value->new(
                                            $arg->{$_}
                                        )
                                      )
                                } @cols
                            )
                        ]
                    );
                }
                elsif ( $word eq 'VALUES' ) {
                    my @cols = sort keys %$arg;

                    # map quote_identifier?
                    $query[-1]->[1] =
                      DBIx::ThinSQL::table->new( $query[-1]->[1], @cols );

                    push(
                        @query,
                        [
                            $word,
                            DBIx::ThinSQL::values->new(
                                map {
                                    ref $arg->{$_} eq 'SCALAR'
                                      ? ${ $arg->{$_} }
                                      : DBIx::ThinSQL::bind_value->new(
                                        $arg->{$_} )
                                } @cols
                            )
                        ]
                    );
                }
                else {
                    warn "cannot handle $word => HASH";
                }
            }
            else {
                push( @query, [ $word, $arg ] );
            }
        }
    };

    Carp::croak("Bad Query: $@") if $@;
    return bless \@query, $class;
}

sub as {
    my $self  = shift;
    my $value = shift;

    return DBIx::ThinSQL::expr->new( '(', $self, ') AS ',
        DBIx::ThinSQL::quote_identifier->new($value) );
}

sub tokens {
    my $self = shift;
    return @$self;
}

1;

__END__

=head1 NAME

DBIx::ThinSQL - A lightweight SQL helper for DBI

=head1 VERSION

0.0.48 (2016-11-01) development release.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use DBIx::ThinSQL qw/ bv qv /;

    my $db = DBIx::ThinSQL->connect(
        'dbi:Driver:...'
        'username',
        'password',
    );

    # Some basic CrUD statements to show the simple stuff first. Note
    # the inline binding of data that you normally have to call
    # $dbh->bind_param() on.

    my $success = $db->xdo(
        insert_into => 'actors',
        values      => {
            id    => 1,
            name  => 'John Smith',
            photo => bv( $image, DBI::SQL_BLOB ),
        },
    );

    # A "where" with a HASHref "AND"s the elements together

    my $count = $db->xdo(
        update => 'actors',
        set    => { name => 'Jack Smith' },
        where  => { id => 1, name => \'IS NOT NULL' },
    );

    # A "where" with an ARRAYref concatenates items together. Note the
    # string that is quoted according to the database type.

    my $count = $db->xdo(
        delete_from => 'actors',
        where       => [
            'actor_id = 1', ' OR ',
            'last_name != ', qv("Jones", DBI::SQL_VARCHAR ),
        ],
    );

    # Methods for reading from the database depend on the type of
    # structure you want back: arrayref or hashref references.

    my $ref = $db->xhashref(
        select => [ 'id', 'name', qv("Some string") ],
        from   => 'actors',
        where  => [
            'id = ', qv( 1, DBI::SQL_INTEGER ),
            ' AND photo IS NOT NULL',
        ],
        limit  => 1,
    );

    $db->xdo(
        insert_into => [ 'table', 'col1', 'col2', 'col3' ],
        select => [ 't1.col3', 't3.col4', bv( 'value', DBI::SQL_VARCHAR ) ],
        from   => 'table AS t1',
        inner_join => 'other_table AS t2',
        on         => 't1.something = t2.else',
        left_join  => 'third_table AS t3',
        on    => [ 't3.dont = t1.care AND t1.fob = ', qv( 1, DBI::SQL_INT ) ],
        where => [],
        order_by => [ 't3.dont', 't1.col4' ],
        limit    => 2,
    );

    $db->txn( sub {
        # Anything you like, done inside a BEGIN/COMMIT pair, with
        # nested calls to txn() done inside a SAVEPOINT/RELEASE pair.
    })


=head1 DESCRIPTION

Sorry, this documentation is invalid or out of date.

B<DBIx::ThinSQL> is an extension to the Perl Database Interface
(L<DBI>).  It is designed for complicated queries and efficient access
to results.  With an API that lets you easily write almost-raw SQL,
DBIx::ThinSQL gives you unfettered access to the power and flexibility
of your underlying database. It aims to be a tool for programmers who
want their databases to work just as hard as their Perl scripts.

DBIx::ThinSQL gives you access to aggregate expressions, joins, nested
selects, unions and database-side operator invocations. Transactional
support is provided via L<DBIx::Connector>.  Security conscious coders
will be pleased to know that all user-supplied values are bound
properly using L<DBI> "bind_param()".  Binding binary data is handled
transparently across different database types.

DBIx::ThinSQL offers a couple of very simple Create, Retrieve, Update
and Delete (CRUD) action methods.  These are designed to get you up and
running quickly when your query data is already inside a hashref. The
methods are abstractions of the real API, but should still read as much
as possible like SQL.

Although rows can be retrieved from the database as simple objects,
DBIx::ThinSQL does not attempt to be an Object-Relational-Mapper (ORM).
There are no auto-inflating columns or automatic joins and the code
size and speed reflect the lack of complexity.

DBIx::ThinSQL uses the light-weight L<Log::Any> for logging.

=head1 CONSTRUCTOR

Works like a normal DBI. Can be used with things like
L<DBIx::Connector> to get nice transaction support.

=head1 DBH METHODS

=over

=item share_dir -> Path::Tiny

Returns the path to the distribution share directory. If
C<$DBIx::ThinSQL::SHARE_DIR> is set then that value will be returned
instead of the default method which uses L<File::ShareDir>.

=item throw_error

If B<DBIX::ThinSQL> or a statement raises an exception then the
C<throw_error()> method will be called. By default it just croaks but
classes that inherit from B<DBIx::ThinSQL> can override it. The
original use case was to turn database error text into blessed objects.

=item xprepare

Does a prepare but knows about bind values and quoted values.

=item xprepare_cached

Does a prepare_cached but knows about bind values and quoted values.

=item xval

Creates a statement handle using xprepare(), executes it, and returns
the result of the val() method.

=item xlist

Creates a statement handle using xprepare(), executes it, and returns
the result of the list() method.

=item xarrayref

Does a prepare but knows about bind values and quoted values.

=item xarrayrefs

Does a prepare but knows about bind values and quoted values.

=item xhashref

Does a prepare but knows about bind values and quoted values.

=item xhashrefs

Does a prepare but knows about bind values and quoted values.

=item txn( &coderef )

Runs the &coderef subroutine inside an SQL transaction.  If &coderef
raises an exception then the transaction is rolled back and the error
gets re-thrown.

Calls to C<txn> can be nested. Savepoints will be used by nested C<txn>
calls for databases that support them.

=item dump( $sql, [ @bind_values ] )

=item xdump( @tokens )

Debugging shortcut methods.  Take either an SQL string (for C<dump>) or
a set of tokens (for C<xdump>), run the query, and then call the
C<dump_results> (which pretty-prints to STDOUT) on the resulting
statement handle.

=item log_debug( $sql, [ @bind_values ] )

Like C<dump> but sends the results to L<Log::Any> C<debug()>.

=item log_warn( $sql, [ @bind_values ] )

Like C<dump> but displays the results using Perl's C<warn> function.

=back

=head1 STH METHODS

=over

=item val -> SCALAR

Return the first value of the first row as a scalar.

=item list -> LIST

Return the first row from the query as a list.

=item arrayref -> ARRAYREF

Return the first row from the query as an array reference.

=item arrayrefs -> ARRAYREF

=item arrayrefs -> LIST

Update rows in the database and return the number of rows affected.
This method is retricted to the wholesale replacement of column values
(no database-side calculations etc).  Multiple WHERE key/values are
only 'AND'd together. An 'undef' value maps to SQL's NULL value.

=item hashref -> HASHREF

Delete rows from the database and return the number of rows affected.

=item hashrefs -> ARRAYREF[HASHREF]

=item hashrefs -> LIST

Delete rows from the database and return the number of rows affected.

=back

=head1 CLASS FUNCTIONS

The following functions can be exported individually or all at once
using the ':all' tag.  They all return an object which can be combined
with or used inside other functions.

=over 4

=item bv( $value, [ $bind_type ] ) -> L<DBIx::ThinSQL::BindValue>

This function returns an object which tells DBIx::ThinSQL to bind
$value using a placeholder. The optional $bind_type is a database type
(integer, varchar, timestamp, bytea, etc) which will be converted to
the appropriate bind constant during a prepare() or prepare_cached()
call.

=item qv( $value )

=item AND

=item OR

=item C<sq ( @subquery )> -> L<DBIx::ThinSQL::_expr>

A function for including a sub query inside another:

    $db->xarrayref(
        select => 'subquery.col',
        from   => sq(
            select => 'col',
            from   => 'table',
            where  => 'condition IS NOT NULL',
        )->as('subquery'),
    );

=item sql_and( @args ) -> L<DBIx::ThinSQL::Expr>

Maps to "$arg1 AND $arg2 AND ...".

=item sql_case( @stmts ) -> L<DBIx::ThinSQL::Expr>

Wraps @stmts inside a CASE/END pair while converting arguments to
expressions where needed.

    sql_case(
        when => $actors->name->is_null,
        then => 'No Name',
        else => $actors->name,
    )->as('name')

    # CASE WHEN actors0.name IS NULL
    # THEN ? ELSE actors0.name END AS name

=item sql_coalesce(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "COALESCE($arg1, $arg2, ...)".

=item sql_cast($arg1, as => $arg2) -> L<DBIx::ThinSQL::Expr>

Maps to "CAST( $arg1 AS $arg2 )".

=item sql_concat(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "$arg1 || $arg2 || ...".

=item sql_count(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "COUNT($arg1, $arg2, ...)".

=item sql_exists(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "EXISTS(@args)".

=item sql_func('myfunc', @args) -> L<DBIx::ThinSQL::Expr>

Maps to "MYFUNC($arg1, $arg2, ...)".

=item sql_hex(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "HEX($arg1, $arg2, ...)".

=item sql_length(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "LENGTH(@args)".

=item sql_lower(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "LOWER(@args)".

=item sql_ltrim(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "LTRIM(@args)".

=item sql_max(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "MAX(@args)".

=item sql_min(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "MIN(@args)".

=item sql_rtrim(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "RTRIM(@args)".

=item sql_sum(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "MIN(@args)".

=item sql_or(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "$arg1 OR $arg2 OR ...".

=item sql_replace(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "REPLACE($arg1,$arg2 [,$arg3])".

=item sql_substr(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "SUBSTR($arg1, $arg2, ...)".

=item sql_table($name, @columns) -> L<DBIx::ThinSQL::Expr>

Maps to "name(col1,col2,...)".

=item sql_upper(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "UPPER(@args)".

=item sql_values(@args) -> L<DBIx::ThinSQL::Expr>

Maps to "VALUES($arg1, $arg2, ...)".

=back

=head1 SEE ALSO

L<Log::Any>

=head1 DEVELOPMENT & SUPPORT

DBIx::ThinSQL is managed via Github:

    https://github.com/mlawren/p5-DBIx-ThinSQL/tree/devel

DBIx::ThinSQL follows a semantic versioning scheme:

    http://semver.org

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

