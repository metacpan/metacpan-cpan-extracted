package App::Zapzi::Database::Schema;
# ABSTRACT: database schema for zapzi

use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use base 'DBIx::Class::Schema';

# Load Result classes under this schema
__PACKAGE__->load_classes(qw/Article ArticleText Config Folder/);


sub schema_version
{
    return 2;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Database::Schema - database schema for zapzi

=head1 VERSION

version 0.017

=head1 METHODS

=head2 schema_version

The version of the database schema that the code expects

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
