package Data::Section::Fixture;
use 5.008005;
use strict;
use warnings;
use Data::Section::Simple;
use Scope::Guard;
use base qw(Exporter);

our $VERSION = "0.01";

our @EXPORT_OK = qw(with_fixture);

sub with_fixture ($&) {
    my ($dbh, $code) = @_;

    my ($pkg) = caller;
    my $reader = Data::Section::Simple->new($pkg);
    my $setup_sqls = $reader->get_data_section('setup') || '';
    my $teardown_sqls = $reader->get_data_section('teardown') || '';

    my $guard = Scope::Guard->new(sub {
        _exec_sqls($dbh, $teardown_sqls);
    });
    _exec_sqls($dbh, $setup_sqls);

    $code->();
}

sub _exec_sqls {
    my ($dbh, $sqls) = @_;
    for (split ';', $sqls) {
        $dbh->do($_) unless $_ =~ /^\s+$/;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Section::Fixture - data section as a fixture

=head1 SYNOPSIS

    use Data::Section::Fixture qw(with_fixture);

    my $dbh = DBI->connect(...);

    with_fixture($dbh, sub {
        # fixture data is only accessible inside this scope.
        my $rows = $dbh->selectall_arrayref('SELECT id FROM t ORDER BY id');
        is_deeply $rows, [[1], [2], [3]];
    });

    __DATA__
    @@ setup
    CREATE TABLE t (
        id int
    );
    INSERT INTO t (id) VALUES (1), (2), (3);

    @@ teardown
    DELETE FROM t;


=head1 DESCRIPTION

Data::Section::Fixture is a module to use C<__DATA__> section as a fixture data. 
This module is intended to be used with unit testing.

The mark C<@@ setup> in C<__DATA__> section stands for setup SQL which is executed just before C<with_fixture>.
The SQL below the mark C<@@ teardown> is executed at the end of C<with_fixture> to tear down fixture data.

=head1 FUNCTION

=head2 with_fixture($dbh, $code_ref);

Fixture data is only accessible inside this function.

=over

=item $dbh

database handler

=item $code_ref

executed code

=back

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

