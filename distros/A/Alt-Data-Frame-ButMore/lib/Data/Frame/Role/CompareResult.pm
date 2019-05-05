package Data::Frame::Role::CompareResult;

# ABSTRACT: Role for column compare result

use Data::Frame::Role;
use namespace::autoclean;

use PDL::Core qw(null);
use Data::Frame::Types qw(DataFrame);


has both_bad => (
    is      => 'rwp',
    isa     => DataFrame,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Role::CompareResult - Role for column compare result

=head1 VERSION

version 0.0049

=head1 ATTRIBUTES

=head2 both_bad

A data frame of the same dimensions as the two compared data frames.
It Indicates by the true values in it which columns/rows are both bad
in the two compared data frames.

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
