package CSS::Coverage::Report;
{
  $CSS::Coverage::Report::VERSION = '0.04';
}
use Moose;

has unmatched_selectors => (
    traits  => ['Array'],
    is      => 'bare',
    default => sub { [] },
    handles => {
        unmatched_selectors    => 'elements',
        add_unmatched_selector => 'push',
    },
);

1;

__END__

=pod

=head1 NAME

CSS::Coverage::Report

=head1 VERSION

version 0.04

=head1 NAME

CSS::Coverage::Report

=head1 VERSION

version 0.04

=head1 METHODS

=head2 unmatched_selectors

Returns a list of CSS selectors that were not matched against any document.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
