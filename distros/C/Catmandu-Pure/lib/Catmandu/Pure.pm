package Catmandu::Pure;

our $VERSION = '0.05';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Pure - A bundle of Catmandu modules for working with data from Pure

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert Pure \
        --base https://host/ws/api/... \
        --endpoint research-outputs \
        --apiKey "..."

=head1 MODULES

=over

=item

L<Catmandu::Importer::Pure>

=back

=head1 DESCRIPTION

Catmandu::Importer::Pure is a Catmandu package that seamlessly imports data from Elsevier's Pure
system using its REST service. Currently documentation describing the REST service can be found
under /ws on a webserver that is running Pure.

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>

=head1 AUTHOR

Snorri Briem E<lt>briem@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Lund University Library

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
See http://dev.perl.org/licenses/ for more information.

=cut
