package App::SQLiteKeyValueStoreSimpleUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-18'; # DATE
our $DIST = 'App-SQLiteKeyValueStoreSimpleUtils'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: CLI utilities for SQLite::KeyValueStore::Simple

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SQLiteKeyValueStoreSimpleUtils - CLI utilities for SQLite::KeyValueStore::Simple

=head1 VERSION

This document describes version 0.001 of App::SQLiteKeyValueStoreSimpleUtils (from Perl distribution App-SQLiteKeyValueStoreSimpleUtils), released on 2021-06-18.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<check-sqlite-kvstore-key-exists>

=item * L<get-sqlite-kvstore-value>

=item * L<list-sqlite-kvstore-keys>

=item * L<set-sqlite-kvstore-value>

=back

which are basically CLI front-end for the functions in
L<SQLite::KeyValueStore::Simple>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SQLiteKeyValueStoreSimpleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SQLiteKeyValueStoreSimpleUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SQLiteKeyValueStoreSimpleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQLite::KeyValueStore::Simple>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
