package Data::SearchEngine::Modifiable;
{
  $Data::SearchEngine::Modifiable::VERSION = '0.33';
}
use Moose::Role;

# ABSTRACT: A role for search engines with an updateable index.


requires qw(add present remove remove_by_id update);

no Moose::Role;
1;


__END__
=pod

=head1 NAME

Data::SearchEngine::Modifiable - A role for search engines with an updateable index.

=head1 VERSION

version 0.33

=head1 DESCRIPTION

This is an add-on role that is used in conjunction with L<Data::SearchEngine>
when wrapping an index that can be updated.  Since some indexes may be read
only, the idea is to keep the required methods in this role separate from the
base one.

=head1 METHODS

=head2 add ($thing)

Adds the specified thing to the index.

=head2 present ($thing)

Returns true if the specified thing is present in the index.

=head2 remove ($thing)

Removes the specified thing from the index.  Consult the documentation
for your specific backend.

=head2 remove_by_id ($id)

Remove a specific thing by id.

=head2 update ($thing)

Updates the specified thing in the index.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

