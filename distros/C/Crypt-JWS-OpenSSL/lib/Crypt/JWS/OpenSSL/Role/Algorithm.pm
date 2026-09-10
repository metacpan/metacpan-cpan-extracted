package Crypt::JWS::OpenSSL::Role::Algorithm;
$Crypt::JWS::OpenSSL::Role::Algorithm::VERSION = '0.005';
use Moo::Role;

requires qw(
    sign
    verify
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Role::Algorithm - Role composed into Crypt::JWS::OpenSSL algorithm modules

=head1 VERSION

version 0.005

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut