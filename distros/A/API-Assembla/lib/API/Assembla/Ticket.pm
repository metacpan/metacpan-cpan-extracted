package API::Assembla::Ticket;
BEGIN {
  $API::Assembla::Ticket::VERSION = '0.03';
}
use Moose;

# ABSTRACT: A Ticket in Assembla.



has 'created_on' => (
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


has 'number' => (
    is => 'rw',
    isa => 'Int'
);


has 'priority' => (
    is => 'rw',
    isa => 'Int'
);


has 'status_name' => (
    is => 'rw',
    isa => 'Str'
);


has 'summary' => (
    is => 'rw',
    isa => 'Str'
);

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

API::Assembla::Ticket - A Ticket in Assembla.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

Assembla XXX

=head1 ATTRIBUTES

=head2 created_on

The DateTime representing the time at which this ticket was created.

=head2 description

The ticket's description

=head2 id

The ticket's id.

=head2 name

The ticket's name.

=head2 number

The ticket's number.

=head2 priority

The ticket's priority.

=head2 status_name

The ticket's status_name.

=head2 summary

The ticket's summary.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
