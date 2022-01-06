package Data::Frame::Partial::Eval;
$Data::Frame::Partial::Eval::VERSION = '0.006002';
# ABSTRACT: Partial class for data frame's eval method

use Data::Frame::Role;
use namespace::autoclean;

use Eval::Quosure 0.001001;
use Types::Standard;

use Data::Frame::Indexer qw(indexer_s);


method eval_tidy ($x) {
    my $is_quosure = $x->$_DOES('Eval::Quosure');
    if (ref($x) and not $is_quosure) {
        return $x;
    }

    my $expr = $is_quosure ? $x->expr : $x;
    if ( $self->exists($expr) ) {
        return $self->column($expr);
    }

    my $quosure = $is_quosure ? $x : Eval::Quosure->new( $expr, 1 );

    # If expr matches a column name in the data frame, return the column.
    my $column_vars = {
        $self->names->map(
            sub {
                my $var = '$' . ( $_ =~ s/\W/_/gr );
                $var => $self->at($_);
            }
        )->flatten
    };

    try {
        return $quosure->eval($column_vars);
    }
    catch ($e) {
        die qq{Error in eval_tidy('$expr', ...) : $e };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Partial::Eval - Partial class for data frame's eval method

=head1 VERSION

version 0.006002

=head1 SYNOPSIS

    $df->eval_tidy($x);

=head1 DESCRIPTION

Do not use this module in your code. This is only internally used by
L<Data::Frame>.

The C<eval_tidy> method is similar to R's data frame tidy evaluation.

=head1 METHODS

=head2 eval_tidy

    eval_tidy($x)

This method is similar to R's data frame tidy evaluation.

Depending on C<$x>,

=over 4

=item * C<$x> is a reference but not an L<Eval::Quosure> object

Return C<$x>.

=item * C<$x> is a column name of the data frame

Return the column.

=item * For other C<$x>,

Coerce C<$x> to an an L<Eval::Quosure> object, add columns of the data
frame into the quosure object's captured variables, and evaluate the
quosure object. For example, 

    # $df has a column named "foo"
    $df->eval_tidy('$foo + 1');

    # above is equivalent to below
    $df->at('foo') + 1;

=back

=head1 SEE ALSO

L<Data::Frame>, L<Eval::Quosure>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2022 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
