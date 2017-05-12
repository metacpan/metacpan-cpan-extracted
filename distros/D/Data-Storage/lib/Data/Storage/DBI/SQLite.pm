use 5.008;
use strict;
use warnings;

package Data::Storage::DBI::SQLite;
BEGIN {
  $Data::Storage::DBI::SQLite::VERSION = '1.102720';
}
# ABSTRACT: Base class for SQLite DBI storages
use parent 'Data::Storage::DBI';

sub connect_string {
    my $self = shift;
    sprintf("dbi:SQLite:dbname=%s", $self->dbname);
}

# Prepare a test database; unlink the existing database and recreate it with
# the initial data. This method is called at the beginning of test programs.
# The functionality implemented here is specific to SQLite, as that's probably
# only going to be used for tests. If you're testing against Oracle databases
# where setup is going to take a lot more steps than unlinking and recreating,
# you might want to prepare a test database beforehand and leave this method
# empty, so the same database is reused for many tests.
sub test_setup {
    my $self = shift;
    if (-e $self->dbname) {
        unlink $self->dbname
          or throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => sprintf "can't unlink %s: %s\n",
            $self->dbname, $!
          );
    }
    $self->connect;
    $self->setup;
}

sub last_id {
    my $self = shift;
    $self->dbh->func('last_insert_rowid');
}
1;


__END__
=pod

=for stopwords SQLite

=head1 NAME

Data::Storage::DBI::SQLite - Base class for SQLite DBI storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 connect_string

FIXME

=head2 last_id

FIXME

=head2 test_setup

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

