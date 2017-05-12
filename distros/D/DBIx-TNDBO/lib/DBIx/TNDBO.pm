package DBIx::TNDBO;

$VERSION = 0.02;

use strict;
use warnings;
{
    use Carp;
    use Readonly;
    use DBI;
    use SQL::Abstract;
    use Storable;
    use File::Spec;
    use Filter::Simple;
}

$Carp::Internal{ (__PACKAGE__) }++;

my ( $Class_Base, $Debug, %Dbh_For, $Schema_Hr, $Schema_Cache_Filename );

sub new {
    my ( $database, $table, $where_hr, $option_hr ) = @_;

    printf "%s::%s::new(%s)\n", $Class_Base, ucfirst $table,
        _dumper($where_hr)
        if $Debug;

    my $record_hr;

    my $dbh = _get_dbh( $database, $table );

    if ($where_hr) {

        my ( $sql, $param_ar ) = _build_sql( "$database.$table", $where_hr );

        my $sth = $dbh->prepare($sql);

        croak $DBI::errstr
            if $DBI::errstr;

        $sth->execute( @{$param_ar} );

        return
            if !$sth->rows();

        if ( $sth->rows() > 1 ) {
            carp 'matched ', $sth->rows(), ' for: ', _dumper($where_hr);
            return;
        }

        $record_hr = $sth->fetchrow_hashref();
    }
    else {

        $record_hr = {};
    }

    my %config = (
        dbh    => $Dbh_For{$database},
        table  => "$database.$table",
        schema => $Schema_Hr->{"$database.$table"},
    );
    return DBIx::TNDBO::rec->_new( $record_hr, \%config );
}

sub list {
    my ( $database, $table, $where_hr, $option_hr ) = @_;

    printf "%s::%s::list(%s)\n", $Class_Base, ucfirst $table,
        _dumper($where_hr)
        if $Debug;

    my ( $sql, $param_ar ) = _build_sql( "$database.$table", $where_hr );

    my $dbh = _get_dbh( $database, $table );

    my $sth = $dbh->prepare($sql);

    croak $DBI::errstr
        if $DBI::errstr;

    $sth->execute( @{$param_ar} );

    my %config = (
        dbh    => $Dbh_For{$database},
        table  => "$database.$table",
        schema => $Schema_Hr->{"$database.$table"},
    );
    my @records = map { DBIx::TNDBO::rec->_new( $_, \%config ) }
        @{ $sth->fetchall_arrayref( {} ) };

    return @records
        if wantarray;

    return \@records;
}

sub iterator {
    my ( $database, $table, $where_hr, $option_hr ) = @_;

    printf "%s::%s::iterator(%s)\n", $Class_Base, ucfirst $table,
        _dumper($where_hr)
        if $Debug;

    my ( $sql, $param_ar ) = _build_sql( "$database.$table", $where_hr );

    my $dbh = _get_dbh( $database, $table );

    my $sth = $dbh->prepare($sql);

    $sth->execute( @{$param_ar} );

    my %config = (
        dbh    => $Dbh_For{$database},
        table  => "$database.$table",
        schema => $Schema_Hr->{"$database.$table"},
    );
    return DBIx::TNDBO::iter->_new( $sth, \%config );
}

sub count {
    my ( $database, $table, $where_hr, $option_hr ) = @_;

    printf "%s::%s::list(%s)\n", $Class_Base, ucfirst $table,
        _dumper($where_hr)
        if $Debug;

    my ( $sql, $param_ar )
        = _build_sql( "$database.$table", $where_hr, 'count' );

    my $dbh = _get_dbh( $database, $table );

    my $sth = $dbh->prepare($sql);

    croak $DBI::errstr
        if $DBI::errstr;

    $sth->execute( @{$param_ar} );

    my ($n) = $sth->fetchrow();

    $sth->finish();

    return $n;
}

# Called by Perl on use

sub import {
    my ( $class, @databases ) = @_;

    SYMBOL:
    for my $symbol ( keys %:: ) {

        next SYMBOL
            if $symbol !~ m{ :: \z}xms;

        next SYMBOL
            if !defined $::{$symbol}->{ISA};

        if ( grep { $_ eq __PACKAGE__ } @{ $::{$symbol}->{ISA} } ) {

            $Class_Base = substr $symbol, 0, -2;
            last SYMBOL;
        }
    }

    die 'unable to determine the class using ', __PACKAGE__, ' as its base'
        if !$Class_Base;

    {
        no strict 'refs';
        *{ __PACKAGE__ . '::credentials' }
            = *{ $Class_Base . '::credentials' };
    }

    croak sprintf 'You must define %s::credentials( $dbname ) ', $Class_Base
        if !defined &credentials;

    my $creds_key;

    NAME:
    for my $dbname (@databases) {

        if ( $dbname =~ m{\A : ( \w+ ) \z}xms ) {

            $creds_key = $1;
            last NAME;
        }
    }

    if ($creds_key) {

        @databases = grep { $_ ne ":$creds_key" } @databases;

        my $cred_hr = credentials();

        if ( ref $cred_hr->{$creds_key} eq 'ARRAY' ) {

            push @databases, @{ $cred_hr->{$creds_key} };
        }
        elsif ( ref $cred_hr->{$creds_key} eq 'HASH' ) {

            push @databases, keys %{ $cred_hr->{$creds_key} };
        }
        elsif ( $cred_hr->{$creds_key} ) {

            push @databases, $cred_hr->{$creds_key};
        }
    }

    return
        if !@databases;

    if ( !$Schema_Hr ) {

        $Schema_Hr = _read_schema( \@databases );
    }

    my @tables = keys %{ $Schema_Hr };

    for my $database_table (@tables) {

        my ( $database, $table ) = split /[.]/, $database_table;

        for my $method (qw( new list iterator count )) {

            my $class = sprintf '%s::%s', $Class_Base, ucfirst lc $table;
            {
                no strict 'refs';

                *{"${class}::${method}"} = sub {

                    croak 'call constructors with arrow operator:',
                        sprintf ' %s->%s(...)', $class, $method
                        if $_[0] ne $class;

                    shift @_;

                    return *{$method}->( $database, $table, @_ );
                };
            }
        }
    }

    return;
}

# Internal

sub _read_schema {
    my ($database_ar) = @_;

    if ( !$Schema_Cache_Filename ) {

        my $tmpdir = File::Spec->tmpdir();

        my ($sep)    # TODO truly cross platform?
            = grep { $_ ne 'x' }
            reverse split //, File::Spec->catdir( 'x', 'x' );

        my $database_dsv = join '.', @{ $database_ar };

        $Schema_Cache_Filename = "${tmpdir}${sep}tndbo.$database_dsv.schema";
    }

    return Storable::retrieve($Schema_Cache_Filename)
        if stat $Schema_Cache_Filename;

    $Schema_Hr = {};

    for my $database ( @{$database_ar} ) {

        my $dbh = _get_dbh( $database );

        my $sth = $dbh->prepare('show tables');

        croak $DBI::errstr
            if $DBI::errstr;

        $sth->execute();

        croak $DBI::errstr
            if $DBI::errstr;

        croak "failed to find any tables in $database"
            if !$sth || $sth->rows() == 0;

        while ( my ($table) = $sth->fetchrow() ) {

            my $sth = $dbh->prepare("desc $table");

            croak $DBI::errstr
                if $DBI::errstr;

            $sth->execute();

            my @columns;

            while ( my $desc_hr = $sth->fetchrow_hashref() ) {

                # eliminate risk of case inconsistency issues
                # i.e. Type  => INT(10)        vs. TYPE => Int(10)
                #      Extra => auto_increment vs. Extra => AUTO_INCREMENT
                for my $name ( keys %{$desc_hr} ) {

                    my $lc_name = lc $name;

                    my $lc_prop
                        = $lc_name eq 'field'       ? $desc_hr->{$name}
                        : defined $desc_hr->{$name} ? lc $desc_hr->{$name}
                        :                             "";

                    $desc_hr->{$lc_name} = $lc_prop;

                    if ( $name ne $lc_name ) {

                        delete $desc_hr->{$name};
                    }
                }

                push @columns, $desc_hr;
            }

            $Schema_Hr->{"$database.$table"} = \@columns;
        }
    }

    croak sprintf 'failed to read schema from any of (%s)', join ',',
        @{$database_ar}
        if !%{$Schema_Hr};

    Storable::store( $Schema_Hr, $Schema_Cache_Filename );

    return $Schema_Hr;
}

sub _build_sql {
    my ( $from, $where_hr, $operation ) = @_;

    $operation ||= 'select';

    my $sql = SQL::Abstract->new();

    my @fields;

    if ( $operation eq 'count' ) {

        $operation = 'select';
        @fields = qw/ count(*) /;
    }
    else {

        @fields = map { $_->{field} } @{ $Schema_Hr->{$from} };
    }

    my ( $stmt, @bind ) = $sql->$operation( $from, \@fields, $where_hr );

    # TODO error condition handling

    return ( $stmt, \@bind );
}

sub _get_dbh {
    my ($database) = @_;

    my $dbh;

    if ( $database && exists $Dbh_For{$database} ) {

        $dbh = $Dbh_For{$database};
    }

    if ( !$dbh || !$dbh->ping() ) {

        my ( $user, $pass, $driver, $host, $port );
        {
            my $cred_hr = credentials($database);

            my @keys = qw( user pass driver host port );

            my @creds = grep {$_} @{$cred_hr}{@keys};

            croak sprintf 'credentials() should include (%s)', join ',', @keys
                if @creds != @keys;

            ( $user, $pass, $driver, $host, $port ) = @creds;
        }

        my $dsn
            = sprintf 'DBI:%s:database=%s;host=%s;port=%s',
            $driver, $database, $host, $port;

        $dbh = DBI->connect( $dsn, $user, $pass );

        croak $DBI::errstr
            if $DBI::errstr;

        $Dbh_For{$database} = $dbh;
    }

    return $dbh;
}

sub _dumper {
    my ($ref) = @_;

    my $text;
    {
        require Data::Dumper;

        no warnings 'once';
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;

        $text = Data::Dumper::Dumper($ref);
    }

    $text =~ s{ ;? \s* \z}{}xms;

    return $text;
}

# Secluded Iterator Package
{
    package DBIx::TNDBO::iter;

    use strict;
    use warnings;
    {
        use Carp;
    }

    my $Index = 0;
    my ( @Sths, @Configs, @Counts );

    sub _new {
        my ( $class, $sth, $config_hr ) = @_;

        my $self = $Index++;
        {
            $Sths[$self]    = $sth;
            $Counts[$self]  = $sth->rows();
            $Configs[$self] = $config_hr;
        }
        return bless \$self, $class;
    }

    sub has_next {
        my ($self) = @_;
        my $id = ${$self};
        return $Counts[$id] > 0 ? 1 : 0;
    }

    sub next {
        my ($self) = @_;

        my $id = ${$self};

        return
            if !$Counts[$id];

        $Counts[$id]--;

        my $record_hr = $Sths[$id]->fetchrow_hashref();

        return DBIx::TNDBO::rec->_new( $record_hr, $Configs[$id] );
    }

    sub DESTROY {
        my ($self) = @_;
        my $id = ${$self};
        if ( $Sths[$id] ) {
            $Sths[$id]->finish();
        }
        return;
    }

    1;
}

# Secluded Record Package
{
    package DBIx::TNDBO::rec;

    use strict;
    use warnings;
    use overload ( '""' => \&stringify );
    {
        use Carp;
    }

    my $Index = 0;
    my ( @Records, @Dbhs, @Schemas, @Tables, @Updates, @News );

    sub _new {
        my ( $class, $record_hr, $config_hr ) = @_;

        my $self = $Index++;
        {
            $Records[$self] = $record_hr;
            $Dbhs[$self]    = $config_hr->{dbh};
            $Schemas[$self] = $config_hr->{schema};
            $Tables[$self]  = $config_hr->{table};
            $News[$self]    = ( keys %{ $record_hr } == 0 ? 1 : 0 );
        }
        return bless \$self, $class;
    }

    sub get {
        my ($self) = shift @_;

        if ( @_ == 1 ) {

            if ( ref $_[0] eq 'HASH' ) {

                my $value_hr = shift @_;

                for my $column ( keys %{$value_hr} ) {

                    $value_hr->{$column} = $self->get($column);
                }

                return $value_hr;
            }
            elsif ( ref $_[0] eq 'ARRAY' ) {

                my $column_ar = shift @_;

                for my $i ( 0 .. $#{$column_ar} ) {

                    $column_ar->[$i] = $self->get( $column_ar->[$i] );
                }

                return @{$column_ar}
                    if wantarray;

                return $column_ar;
            }
        }

        my ( $column ) = @_;

        croak 'get method called without column name'
            if !$column;

        my $id = ${$self};

        my ($desc_hr) = grep { $_->{field} eq $column } @{ $Schemas[$id] };

        croak "unrecognized column name: $column"
            if !$desc_hr;

        my $value  = $Records[$id]->{$column};
        my $is_int = $desc_hr->{type} =~ m{\A int \W }xms;

        return int $value
            if defined $value && $is_int;

        return $value;
    }

    sub set {
        my ($self) = shift @_;

        if ( @_ == 1 && ref $_[0] eq 'HASH' ) {

            my $value_rh = shift @_;

            while ( my ( $column, $value ) = each %{$value_rh} ) {

                $self->set( $column, $value );
            }

            return $value_rh;
        }

        my ( $column, $value ) = @_;

        my $id = ${$self};

        croak 'get method called without column name'
            if !$column;

        my ($desc_hr) = grep { $_->{field} eq $column } @{ $Schemas[$id] };

        croak "unrecognized column name: $column"
            if !$desc_hr;

        $value
            = defined $value
            ? $value
            : $desc_hr->{default};

        $Updates[$id] ||= {};

        $Updates[$id]->{$column} = $value;

        return $value;
    }

    sub delete {
        my ($self) = @_;

        my $id = ${$self};

        my $sql = SQL::Abstract->new();

        my ( $stmt, @bind ) = $sql->delete( $Tables[$id], $Records[$id] );

        my $sth = $Dbhs[$id]->prepare($stmt);

        $sth->execute(@bind);

        croak $DBI::errstr
            if $DBI::errstr;

        return 1;
    }

    sub commit {
        my ($self) = @_;

        my $id = ${$self};

        return 1
            if !defined $Updates[$id];

        my $is_new    = $News[$id];
        my $table     = $Tables[$id];
        my $update_hr = $Updates[$id];

        my $sql = SQL::Abstract->new();

        my ( $stmt, @bind, $primary_key_value );

        if ($is_new) {

            ( $stmt, @bind ) = $sql->insert( $table, $update_hr );
        }
        else {

            ( $stmt, @bind ) = $sql->update( $table, $update_hr );

            my ($primary_key_name) = map { $_->{name} }
                grep { $_->{key} eq 'pri' && $_->{extra} eq 'auto_increment' }
                @{ $Schemas[$id] };

            if ($primary_key_name) {

                $primary_key_value = $Records[$id]->{$primary_key_name};
            }
        }

        my $sth = $Dbhs[$id]->prepare($stmt);

        $sth->execute(@bind);

        croak $DBI::errstr
            if $DBI::errstr;

        if ( !defined $primary_key_value ) {

            $primary_key_value = $Dbhs[$id]->{mysql_insertid};
        }

        return $primary_key_value;
    }

    sub discard {
        my ( $self ) = @_;

        my $id = ${$self};

        return 1
            if !defined $Updates[$id];

        $Updates[$id] = {};

        return 1;
    }

    sub stringify {
        my ($self) = @_;

        my $id = ${$self};

        my %record = %{ $Records[$id] };

        if ( defined $Updates[$id] ) {

            my @fields = keys %{ $Updates[$id] };

            @record{@fields} = @{ $Updates[$id] }{@fields};
        }

        return sprintf '%s->(%s)', $Tables[$id],
            DBIx::TNDBO::_dumper( \%record );
    }

    sub DESTROY {
        my ( $self ) = @_;
    }

    1;
}

FILTER_ONLY code_no_comments => sub {
    my $source = $_;

    my $eq    = ' \s* = \s* ';
    my $fc    = ' \s* = \s* > \s* ';
    my $dbo   = ' _dbo->    ';
    my $s     = ' \s* [\$]  ';
    my $l     = ' \s* [\@]  ';
    my $alpha = ' ( [A-Z][A-Za-z0-9]+ ) ';
    my $paren = ' \(( .+? )\) ';

    my %xform_for = (

        # FROM: $word_dbo->get_data();
        #   TO: $word_dbo->get('data');
        qr{ ( \w+ $dbo get )_( \w+ ) \( \s* \) }xms => sub {
            return sprintf q{%1$s('%2$s')}, @_;
        },

        # FROM: my $data = $word_dbo->get();
        #   TO: my $data = $word_dbo->get('data');
        qr{ $s( \w+ ) $eq [\$] ( \w+ $dbo get )\( \s* \); }xms => sub {
            return sprintf q{$%1$s = $%2$s('%1$s');}, @_;
        },

        # FROM: data => $word_dbo->get(),
        #   TO: data => $word_dbo->get('data'),
        qr{ ( \w+ ) $fc [\$] ( \w+ $dbo get )\( \s* \)([,\b\n]) }xms => sub {
            return sprintf q{%1$s => $%2$s('%1$s')%3$s}, @_;
        },

        # FROM: $word_dbo->set( $anagram );
        #   TO: $word_dbo->set( 'anagram', $anagram );
        qr{ ( \w+ $dbo set )\( \s* [\$] ( \w+ ) \s* \) }xms => sub {
            return sprintf q{%1$s( '%2$s', $%2$s )}, @_;
        },

        # FROM: my $word_dbo = DB();
        #   TO: my $word_dbo = DB::Word->new();
        qr{ my $s( \w+ )_dbo $eq $alpha $paren; }xms => sub {
            return sprintf q{my $%1$s_dbo = %2$s::%3$s->new(%4$s);}, $_[0],
                $_[1], ( ucfirst lc $_[0] ), ( $_[2] ? $_[2] : '' );
        },

        # FROM: my @word_dbos = DB();
        #   TO: my @word_dbos = DB::Word->list();
        qr{ my $l( \w+ )_dbos $eq $alpha $paren; }xms => sub {
            return sprintf q{my @%1$s_dbos = %2$s::%3$s->list(%4$s);}, $_[0],
                $_[1], ( ucfirst lc $_[0] ), ( $_[2] ? $_[2] : '' );
        },

        # FROM: my $word_itr = DB();
        #   TO: my $word_itr = DB::Word->iterator();
        qr{ my $s( \w+ )_itr $eq $alpha $paren; }xms => sub {
            return sprintf q{my $%1$s_itr = %2$s::%3$s->iterator(%4$s);},
                $_[0], $_[1], ( ucfirst lc $_[0] ), ( $_[2] ? $_[2] : '' );
        },

        # FROM: my $word_count = DB();
        #   TO: my $word_count = DB::Word->count();
        qr{ my $s( \w+ )_count $eq $alpha $paren; }xms => sub {
            return sprintf q{my $%1$s_count = %2$s::%3$s->count(%4$s);},
                $_[0], $_[1], ( ucfirst lc $_[0] ), ( $_[2] ? $_[2] : '' );
        },
    );
    for my $regex ( keys %xform_for ) {

        my $xform_rc = $xform_for{$regex};

        $source =~ s{$regex}{ $xform_rc->( $1, $2, $3, $4 ) }xmseg;
    }

    $_ = $source;

    return;
};

1;
