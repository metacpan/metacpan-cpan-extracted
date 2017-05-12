package Catmandu::Store::REST;

our $VERSION = '0.01';

use Catmandu::Sane;

use Moo;
use Catmandu::Store::REST::Bag;

with 'Catmandu::Store';

has base_url     => (is => 'ro', required => 1);
has query_string => (is => 'ro', default => sub { return ''; });
# TODO: support basic authentication

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Store::REST - Store/retrieve items from a JSON REST-API endpoint

=head1 SYNOPSIS

  # From the command line
  $ catmandu export REST --id 1234 --base_url https://www.example.org/api/v1/books --query_string /page/1 to YAML
  
  # From a Catmandu Fix
  lookup_in_store(
    book_id,
    REST,
    base_url: https://www.example.org/api/v1/books,
    query_string: /page/1
  )

=head1 DESCRIPTION

  # From a Catmandu Fix
  lookup_in_store(
    book_id,
    REST,
    base_url: https://www.example.org/api/v1/books,
    query_string: /page/1
  )

Uses a RESTful API as a L<Catmandu::Store|http://librecat.org/Catmandu/#stores>.

The module allows you to use a RESTful API that uses JSON as data format and uses the URL format
C<[base_url]/[id][query_string]> as a I<Store> for I<Catmandu>.

Retrieving (C<GET>), adding (C<POST>), updating (C<PUT>) and deleting (C<DELETE>) single items is
supported. Data must be provided as JSON by the API, and the API must accept JSON for C<PUT>/C<POST>
requests. The URL must be of the format C<[base_url]/[id][query_string]>, where the C<id>
is absent for C<POST> requests.

=head1 PARAMETERS

You must provide the C<base_url> parameter.

=over

=item C<base_url>

base url of the API endpoint (the entire url before the ID) (e.g. I<https://www.example.org/api/v1/books>).

=item C<query_string>

an optional query string that comes behind the ID (e.g. I</page/1> where the complete URL is
I<https://www.example.org/api/v1/books/1/page/1>).

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter@packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
