package API::Handle::Base;
{
  $API::Handle::Base::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;
use Carp;
use feature ':5.10';

with 'API::Handle';

# Generic base class.

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

API::Handle::Base

=head1 VERSION

version 0.02

=head1 AUTHOR

Nour Sharabash <amirite@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nour Sharabash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
