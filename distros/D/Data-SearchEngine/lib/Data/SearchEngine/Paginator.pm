package Data::SearchEngine::Paginator;
{
  $Data::SearchEngine::Paginator::VERSION = '0.33';
}
use Moose;

use MooseX::Storage;

with 'MooseX::Storage::Deferred';

extends 'Data::Paginator';

1;
__END__
=pod

=head1 NAME

Data::SearchEngine::Paginator

=head1 VERSION

version 0.33

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

