package DBIx::AssertIndex;

use strict;
use warnings;
use 5.008_009;

our $VERSION = '0.02';

use DBI;

our $OUTPUT = *STDERR;

sub import {
    my ($class) = @_;

    no warnings qw(redefine prototype);
    my $original_st_execute = \&DBI::st::execute;
    *DBI::st::execute            = __explain_and_st_execute($original_st_execute);

    foreach my $db_method (qw/do selectall_arrayref selectrow_array selectrow_arrayref /){
        no strict qw(refs);
        my $original = \&{"DBI::db::$db_method"};
        *{"DBI::db::$db_method"} = __explain_and_db_XXX($original, $original_st_execute);
    }
};

sub __explain_and_db_XXX {
    my($original_db_XXX, $original_st_execute) = @_;

    return sub {
        my ($dbh, $statement, @rest ) = @_;

        __expain($original_st_execute, $dbh, $statement, @rest);
        return $original_db_XXX->(@_);
    };
}

sub __explain_and_st_execute {
    my $original_st_execute = shift;
    return sub {
        my ($sth, @rest ) = @_;

        my $dbh       = $sth->{Database};
        my $statement = $sth->{Statement};
        __expain($original_st_execute, $dbh, $statement, @rest);
        return $original_st_execute->(@_);
    };
}

sub __expain {
    my($original_st_execute, $dbh, $statement, @rest) = @_;

    return unless($dbh->{Driver}{Name} eq 'mysql');
    return unless $statement =~ m/^\s*SELECT/i;
    return unless $statement =~ m/FROM/mi;

    my $explain_sth = $dbh->prepare( 'explain ' . $statement );
    $original_st_execute->($explain_sth, @rest);
    __assert_explain($explain_sth->fetchall_arrayref( +{} ), $statement);
}

sub __assert_explain {
    my($explains, $statement) = @_;
    my $clean_statement = __clean_statement($statement);
    my @using_no_key = grep {__should_alert($_) } @$explains;
    return unless @using_no_key;

    __warn->('[explain alert] ', $clean_statement);
}

sub __should_alert {
    my ( $explain_by_table ) = @_;
    my $extra = $explain_by_table->{Extra};
    my $type  = $explain_by_table->{type};
    my $possible_key   = $explain_by_table->{possible_keys};
    # search uniq/primary key but not found any rows
    return 0 if $extra and $extra =~ m/^Impossible/;
    # not using any index
    return 0 if defined $possible_key;
    return 1 if $type and $type eq 'ALL';
    return 0;
}

sub __clean_statement {
    my $statement = shift;
    $statement =~ s/\n/ /g;
    $statement =~ s/\s+/ /g;
    return $statement;
}

sub __warn {
    my($message, $statement, $using_no_key) = @_;

    if (ref $OUTPUT eq 'CODE') {
        $OUTPUT->(
            message      => $message,
            statement    => $statement,
            using_no_key => $using_no_key,
        );
    } else {
        print {$OUTPUT} $message, ' statement:', $statement;
    }
}

1;
__END__

=head1 NAME

DBIx::AssertIndex - show error when SQL query doesn't use index.

=head1 SYNOPSIS

  use DBIx::AssertIndex;
  my $row = $dbh->selectrow_hashref(q{SELECT * FROM some_table WHERE no_indexed_column = 'foo'});

  or

  > starman -MDBIx::AssertIndex app.psgi

=head1 DESCRIPTION

DBIx::AssertIndex is run explain with SELECT SQL and detect query without any index.

Works only DBD::mysql.

=head1 AUTHOR

daichi hiroki E<lt>daichi.hiroki@mixi.co.jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
