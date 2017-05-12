package API::Assembla::Space;
BEGIN {
  $API::Assembla::Space::VERSION = '0.03';
}
use Moose;

# ABSTRACT: A Space in Assembla



has 'created_at' => (
    is => 'rw',
    isa => 'DateTime'
);


has 'description' => (
    is => 'rw',
    isa => 'Str'
);


has 'id' => (
    is => 'rw',
    isa => 'Str'
);


has 'name' => (
    is => 'rw',
    isa => 'Str'
);

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

API::Assembla::Space - A Space in Assembla

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

Assembla XXX

=head1 ATTRIBUTES

=head2 created_at

The DateTime representing the time at which this space was created.

=head2 description

The space's description

=head2 id

The space's id.

=head2 name

The space's name.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
