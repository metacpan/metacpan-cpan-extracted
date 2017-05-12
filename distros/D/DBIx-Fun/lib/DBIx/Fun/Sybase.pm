#$Id: Sybase.pm,v 1.2 2006/07/14 13:44:03 jef539 Exp $
package DBIx::Fun::Sybase;
use strict;
use DBD::Sybase ();
use Carp        ();

use base 'DBIx::Fun';
our $VERSION = '0.00';

sub _make_procedure {
    my ( $self, $name, $argdef ) = @_;
    my $path = join '.', $self->_path, $name;

    my $sub = sub {
        my ( $self, $name, @args ) = @_;

        Carp::croak "Procedure $name only takes "
          . scalar(@$argdef)
          . " arguments"
          if @args > @$argdef;

        my $declare = '';
        for my $i ( 0 .. $#args ) {
            my $val = ref( $args[$i] ) ? ${ $args[$i] } : $args[$i];

            if ( defined $val ) {
                $val = $self->dbh->quote($val);
                $val = "convert($argdef->[$i]{type}, $val)"
                  unless $argdef->[$i]{type} =~ /char/;
            }
            else {
                $val = 'NULL';
            }
            $declare .= "declare \@p$i $argdef->[$i]{type}\n";
            $declare .= "select  \@p$i = $val\n";
        }
        my $args = join ', ', map { "\@p$_ $argdef->[$_]{output}" } 0 .. $#args;

        my $sth = $self->dbh->prepare( my $sql = <<EOQ);
$declare
exec $path $args
EOQ

        # warn $sql;
        $sth->execute;

        return $sth if $self->{as_cursor};

        my ( @param, $status );
        do {
            while ( my $row = $sth->fetchrow_arrayref ) {
                if ( $sth->{syb_result_type} == DBD::Sybase::CS_PARAM_RESULT ) {
                    @param = @$row;
                }
                elsif (
                    $sth->{syb_result_type} == DBD::Sybase::CS_STATUS_RESULT )
                {
                    $status = $row->[0];
                }
            }
        } while ( $sth->{syb_more_results} );

        for my $i ( 0 .. $#$argdef ) {
            next unless $argdef->[$i]{output} and $i <= $#args;
            my $val = shift @param;
            ${ $_[ $i + 2 ] } = $val if ref $_[ $i + 2 ];
        }

        return $status;
    };
    return $sub;
}

sub _lookup_procedure {
    my ( $self, $proc ) = @_;
    my $path = join '.', $self->_path, $proc;
    my @args;
    eval {
        my $sth = $self->dbh->prepare("sp_helptext '$path'");
        $sth->execute;
        my $text;
        while ( my $ref = $sth->fetchrow_arrayref ) {

            #null
        }
        while ( my ($col) = $sth->fetchrow_array ) {
            $text .= $col;
        }
        $text =~ s{(
            '(?:[^']|'')*' |
            "(?:[^"]|"")*" |
            (/\*.*?\*/) |
            (--.*?\n)
             ) }{ ($2 || $3) ? ' ' : $1 }gsex;

        $text =~ s/^\s*create\s+proc\w*\s+(\S+)\s*\(?//si;

        #$text =~ s/=\s*([^\s'"]+|'([^']|'')*'|"([^"]|"")*")/ = /sg;
        #$text =~ s/\)?\s*(with\s+recompile)?\s*as\s.*//si;
        #$text =~ s/\s+/ /g;
        #print "$proc: $text\n";

        while (
            $text =~ s/^\s* (\@\S+)
                 \s+ (\w+ (?: \s* \([\d\s,]+\))?)
                 \s* (= \s* (?: [^\s'"]+ | '(?:[^']|'')*' | "(?:[^"]|"")*" ) )
                 \s* (output)?
                 \s*,?//ix
          )
        {
            my ( $name, $type, $default, $output ) = ( $1, lc $2, $3, lc $4 );
            push @args,
              {
                name    => $name,
                type    => $type,
                default => $default,
                output  => $output
              };
        }
    };
    return if $@;
    return \@args;
}

sub _lookup_user {
    my ( $self, $name ) = @_;
    my @path = $self->_path;
    return if @path > 1;
    my $prefix = @path ? "$path[0].." : '';
    my $qname  = $self->dbh->quote($name);
    my $sth    = $self->dbh->prepare(<<EOQ);
      SELECT count(*) 
      FROM ${prefix}sysusers
      WHERE name = $qname
EOQ
    $sth->execute;
    my ($count) = $sth->fetchrow_array;
    $sth->finish;
    return $count;
}

sub _lookup_database {
    my ( $self, $name ) = @_;
    return if $self->_path;
    my $ref   = $self->dbh->selectcol_arrayref('sp_databases');
    my $count = grep { $_ eq $name } @$ref;

    return $count;
}

sub _cursor {
    my ($self) = @_;
    return $self->context( as_cursor => 1 );
}

sub _lookup {
    my ( $self, $name ) = @_;

    if ( not $self->{cache}{$name} ) {

        my $obj = $self->_lookup_procedure($name);

        if ( not $obj ) {
            $obj = $self->_lookup_user($name);
        }

        if ( ref $obj ) {
            $self->{cache}{$name} = $self->_make_procedure( $name, $obj );
        }
        elsif ($obj) {
            $self->{cache}{$name} =
              { name => $name, path => [ $self->_path, $name ], cache => {} };
        }
    }
    my $ref = $self->{cache}{$name};

    return $ref if ref($ref) eq 'CODE';
    return $self->context(%$ref) if $ref;
    return \&_fetch_function;
}

sub _fetch_function {
    my ( $self, $name, @args ) = @_;
    my $val;
    eval {
        my $bind = join ', ',
          map { defined $_ ? $self->dbh->quote($_) : 'NULL' } @args;

        my $sth = $self->dbh->prepare("select $name($bind)");
        $sth->execute;
        ($val) = $sth->fetchrow_array;
        $sth->finish;
    };
    if ( my $err = $@ ) {
        if ( $self->dbh->err == 195 or $self->dbh->err == 14216 ) {
            $self->_croak_notfound($name);
        }
        Carp::croak($err);
    }
    return $val;
}
1;
