package Catalyst::Plugin::Moostash::Base;

use Moose;


has ctx => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

1;    ## eof

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Moostash::Base

=head1 VERSION

version v0.1.2

=head2 ctx

Catalyst context object.

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
