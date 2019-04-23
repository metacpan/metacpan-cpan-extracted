package Data::Frame::Partial::Eval;

# ABSTRACT: Partial class for data frame's eval method

use Data::Frame::Role;
use namespace::autoclean;

use Eval::Quosure 0.001;
use Types::Standard;

use Data::Frame::Indexer qw(indexer_s);


method eval_tidy ($x) {
    my $is_quosure = $x->$_DOES('Eval::Quosure');
    if (ref($x) and not $is_quosure) {
        return $x;
    }

    my $expr = $is_quosure ? $x->expr : $x;
    if ( $self->exists($expr) ) {
        return $self->at( indexer_s($expr) );
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

    return $quosure->eval($column_vars);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Partial::Eval - Partial class for data frame's eval method

=head1 VERSION

version 0.0045

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 eval_tidy

    eval_tidy($x)

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

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
