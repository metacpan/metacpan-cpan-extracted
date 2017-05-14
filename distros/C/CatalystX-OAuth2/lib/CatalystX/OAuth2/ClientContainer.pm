package CatalystX::OAuth2::ClientContainer;
use Moose::Role;

# ABSTRACT: A role for providing an oauth2 client object to an arbitrary class

has oauth2 => (
  isa      => 'CatalystX::OAuth2::Client',
  is       => 'rw',
  clearer  => 'clear_oauth2'
);

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::ClientContainer - A role for providing an oauth2 client object to an arbitrary class

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
