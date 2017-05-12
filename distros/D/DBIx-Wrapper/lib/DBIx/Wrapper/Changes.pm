
=pod

=head1 NAME

DBIx::Wrapper::Changes - List of significant changes to DBIx::Wrapper

=head1 CHANGES

=head2 VERSION 0.29

=over 4

=item Fixed tests using SQLite

SQLite sometimes fails with a "database locked" error if the db
file is opened more than once.  This may be because File::Temp is
locking the file.

See RT 76411 (L<https://rt.cpan.org/Public/Bug/Display.html?id=76411>)

=item Documentation fixes

Updated formatting, e.g., variables are now marked as code.

=back
