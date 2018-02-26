package Config::Pg::ServiceFile;

use strict;
use warnings;
use parent 'Config::INI::Reader';

# ABSTRACT: PostgreSQL connection service file parser

our $VERSION = '0.02';

sub can_ignore {
  my ($self, $line, $handle) = @_;

  # Skip comments and empty lines
  return $line =~ /\A\s*(?:#|$)/ ? 1 : 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Config::Pg::ServiceFile - PostgreSQL connection service file parser

=head1 SYNOPSIS

    # ~/.pg_service.conf

    [foo]
    host=localhost
    port=5432
    user=foo
    dbname=db_foo
    password=password

    # your_program.pl

    use Config::Pg::ServiceFile;

    # {
    #     foo => {
    #         host     => 'localhost',
    #         post     => '5432',
    #         user     => 'foo',
    #         dbname   => 'db_foo',
    #         password => 'passwird',
    #     }
    # }
    my $hash_ref = Config::Pg::ServiceFile->read_file('~/.pg_service.conf');

=head1 DESCRIPTION

L<Config::Pg::ServiceFile> is a parser for the PostgreSQL connection service
file. The connection service file is based on the C<INI> format, but uses a
C<#> as the comment character. As such, this is a simple module that subclasses
L<Config::INI::Reader>, and replaces the comment character accordingly.

The accompanying module L<Pg::ServiceFile> provides a better interface to the
data stored in a PostgreSQL connection file. See L<Pg::ServiceFile> for more
information.

=head1 METHODS

L<Config::Pg::ServiceFile> inherits all methods from L<Config::INI::Reader>.

=head2 read_file

    my $hash_ref = Config::Pg::ServiceFile->read_file($filename);

Given a filename, this method returns a hashref of the contents of that file.

=head2 read_handle

    my $hash_ref = Config::Pg::ServiceFile->read_handle($io_handle);

Given an IO::Handle, this method returns a hashref of the contents of that
handle.

=head2 read_string

    my $hash_ref = Config::INI::Reader->read_string($string);

Given a string, this method returns a hashref of the contents of that string.

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Config::INI::Reader>,
L<Pg::ServiceFile>,
L<https://www.postgresql.org/docs/current/static/libpq-pgservice.html>,
L<https://github.com/postgres/postgres/blob/master/src/interfaces/libpq/fe-connect.c>.

=cut
