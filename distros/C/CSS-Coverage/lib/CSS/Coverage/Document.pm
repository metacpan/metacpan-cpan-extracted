package CSS::Coverage::Document;
{
  $CSS::Coverage::Document::VERSION = '0.04';
}
use Moose;
use CSS::Coverage::Deparse;

has delegate => (
    is       => 'ro',
    does     => 'CSS::Coverage::DocumentDelegate',
    required => 1,
);

has deparser => (
    is      => 'bare',
    isa     => 'CSS::Coverage::Deparse',
    default => sub { CSS::Coverage::Deparse->new },
    handles => ['stringify_selector'],
);

sub comment {
    my ($self, $comment) = @_;
    if ($comment =~ /coverage\s*:\s*(\w+)/i) {
        $self->delegate->_got_coverage_directive($1);
    }
}

sub end_selector {
    my ($self, $selectors) = @_;

    for my $parsed_selector (@$selectors) {
        my $selector = $self->stringify_selector($parsed_selector);
        $self->delegate->_check_selector($selector);
    }
}

package CSS::Coverage::DocumentDelegate;
{
  $CSS::Coverage::DocumentDelegate::VERSION = '0.04';
}
use Moose::Role;

requires '_check_selector', '_got_coverage_directive';

1;

__END__

=pod

=head1 NAME

CSS::Coverage::Document

=head1 VERSION

version 0.04

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
