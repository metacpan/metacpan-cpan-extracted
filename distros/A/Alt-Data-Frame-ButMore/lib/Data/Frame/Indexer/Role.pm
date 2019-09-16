package Data::Frame::Indexer::Role;

# ABSTRACT: Role for Data::Frame indexer

use Data::Frame::Role;

use Types::Standard qw(ArrayRef);
use Data::Frame::Types qw(ColumnLike);


has indexer => (
    is  => 'ro',
    isa => (
        ArrayRef->plus_coercions( ColumnLike,
            sub { ( $_->badflag ? $_->where( $_->isgood ) : $_ )->unpdl }
        )
    ),
    required => 1,
    coerce   => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Indexer::Role - Role for Data::Frame indexer

=head1 VERSION

version 0.0053

=head1 ATTRIBUTES

=head2 indexer

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
