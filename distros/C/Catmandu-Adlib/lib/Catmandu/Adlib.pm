package Catmandu::Adlib;

use strict;

our $VERSION = '0.02';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Adlib - Catmandu interface to L<Adlib|http://www.adlibsoft.nl/>

=head1 SYNOPSIS

    # From the command line
    catmandu export Adlib to YAML --id 1234 --endpoint http://test2.adlibsoft.com --username foo --password bar --database collect.inf

    # From a Catmandu Fix
    lookup_in_store(
      object_priref,
      Adlib,
      endpoint: http://test2.adlibsoft.com,
      username: foo,
      password: bar,
      database: collect.inf
    )

=head1 MODULES

=over

=item L<Catmandu::Store::Adlib>

=item L<Catmandu::Adlib::API>

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter@packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw, VKC vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
