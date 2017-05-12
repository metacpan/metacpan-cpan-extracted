package B::Tools;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw(Exporter);

our @EXPORT = qw(op_grep op_walk op_descendants);

sub op_walk(&$) {
    my ($code, $op) = @_;
    local *B::OP::walkoptree_simple = sub {
        local $_ = $_[0];
        $code->();
    };
    B::walkoptree($op, 'walkoptree_simple');
}

sub op_grep(&$) {
    my ($code, $op) = @_;

    my @ret;
    op_walk {
        if ($code->()) {
            push @ret, $_;
        }
    } $op;
    return @ret;
}

sub op_descendants($) {
    my $op = shift;
    my @result;
    op_walk {
        push @result, $_;
    } $op;
    return @result;
}

1;
__END__

=for stopwords grepping grep

=encoding utf-8

=head1 NAME

B::Tools - Simple B operating library

=head1 SYNOPSIS

    use B::Tools;

    op_walk {
        say $_->name;
    } $root;

    my @entersubs = op_grep { $_->name eq 'entersub' } $root;

=head1 DESCRIPTION

B::Tools is simple B operating library.

=head1 FUNCTIONS

=over 4

=item op_walk(&$)

Walk every op from root node.

First argument is the callback function for walking.
Second argument is the root op to walking.

I<Return value>: Useless.

=item op_grep(&$)

Grep the op from op tree.

First argument is the callback function for grepping.
Second argument is the root op to grepping.

I<Return value>: Result of grep.

=item my @descendants = op_descendants($)

Get the descendants from $op.

I<Return value>: @descendants

=back

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<B> is a library for manage B things.

L<B::Generate> to generate OP tree in pure perl code.

L<B::Utils> provides features like this. But this module provides more simple features.

=cut

