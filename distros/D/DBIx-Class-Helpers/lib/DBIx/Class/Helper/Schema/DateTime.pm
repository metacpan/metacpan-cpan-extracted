package DBIx::Class::Helper::Schema::DateTime;
$DBIx::Class::Helper::Schema::DateTime::VERSION = '2.036000';
# ABSTRACT: DateTime helper

use strict;
use warnings;

use parent 'DBIx::Class::Schema';

sub datetime_parser { return shift->storage->datetime_parser }

sub parse_datetime { return shift->datetime_parser->parse_datetime(@_) }

sub format_datetime { return shift->datetime_parser->format_datetime(@_) }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Schema::DateTime - DateTime helper

=head1 SYNOPSIS

 package MyApp::Schema;

 __PACKAGE__->load_components('Helper::Schema::DateTime');

 ...

 $schema->resultset('Book')->search({
   written_on => $schema->format_datetime(DateTime->now)
 });

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
