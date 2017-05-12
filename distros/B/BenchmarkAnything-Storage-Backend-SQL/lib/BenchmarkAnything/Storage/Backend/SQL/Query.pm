package BenchmarkAnything::Storage::Backend::SQL::Query;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: BenchmarkAnything::Storage::Backend::SQL - querying - base class
$BenchmarkAnything::Storage::Backend::SQL::Query::VERSION = '0.023';
use strict;
use warnings;
use Digest::MD5;

sub new {

    my ( $s_self, $hr_atts ) = @_;

    my $or_self = bless {}, $s_self;

    for my $s_key (qw/ config dbh /) {
        if (! $hr_atts->{$s_key} ) {
            require Carp;
            Carp::confess("missing parameter '$s_key'");
        }
    }

    $or_self->{dbh}       = $hr_atts->{dbh};
    $or_self->{debug}     = $hr_atts->{debug} || 0;
    $or_self->{config}    = $hr_atts->{config};

    return $or_self;

}

sub execute_query {

    my ( $or_self, $s_statement, @a_vals ) = @_;

    if ( $or_self->{debug} ) {
        warn $s_statement . ' (' . (join ',', @a_vals) . ')';
    }

    local $or_self->{dbh}{RaiseError} = 1;

    my $s_key = Digest::MD5::md5($s_statement);
    if ( $or_self->{prepared}{$s_key} ) {
        $or_self->{prepared}{$s_key}->finish();
    }
    else {
        $or_self->{prepared}{$s_key} = $or_self->{dbh}->prepare( $s_statement );
    }

    $or_self->{prepared}{$s_key}->execute( @a_vals );

    return $or_self->{prepared}{$s_key};

}

sub last_insert_id {

    my ( $or_self, $s_table, $s_column ) = @_;

    return $or_self->{dbh}->last_insert_id(
        undef, undef, $s_table, $s_column,
    );

}

sub start_transaction {

    my ( $or_self ) = @_;

    local $or_self->{dbh}{RaiseError} = 1;

    eval {
        $or_self->{old_AutoCommit} = $or_self->{dbh}{AutoCommit};
        $or_self->{dbh}{AutoCommit} = 0;
    };
    if ( $@ ) {
        if ( $or_self->{debug} ) {
            require Carp;
            Carp::cluck('Transactions not supported by your database');
        }
    }
    else {
        $or_self->{transaction_supported} = 1;
    }

    return 1;

}

sub finish_transaction {

    my ( $or_self, $s_error ) = @_;

    if ( $or_self->{transaction_supported} ) {

        local $or_self->{dbh}{RaiseError} = 1;

        if ( $s_error ) {
            require Carp;
            Carp::confess("transaction failed: $s_error");
            $or_self->{dbh}->rollback();
        }
        else {
            $or_self->{dbh}->commit();
        }

        $or_self->{dbh}{AutoCommit} = $or_self->{old_AutoCommit};

    }

    return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Backend::SQL::Query - BenchmarkAnything::Storage::Backend::SQL - querying - base class

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
