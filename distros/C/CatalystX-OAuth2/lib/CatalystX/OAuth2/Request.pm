package CatalystX::OAuth2::Request;
use Moose::Role;

# ABSTRACT: A role for building oauth2-capable request objects

has oauth2 => (isa => 'CatalystX::OAuth2', is => 'ro', required => 1);

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Request - A role for building oauth2-capable request objects

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
