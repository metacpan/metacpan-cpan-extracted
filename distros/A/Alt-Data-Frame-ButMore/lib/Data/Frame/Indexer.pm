package Data::Frame::Indexer;

# ABSTRACT: Function interface for indexer

use Data::Frame::Setup;

use Data::Frame::Indexer::Integer;
use Data::Frame::Indexer::Label;
use Data::Frame::Types qw(:all);
use Data::Frame::Util qw(is_discrete);

use parent qw(Exporter::Tiny);

our @EXPORT_OK   = qw(indexer_s indexer_i);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


my $NumericIndices =
  ColumnLike->where( sub { $_->type ne 'byte' and not is_discrete($_) } );

fun _as_indexer ($fallback_indexer_class) {
    return sub {
        my $x = @_ > 1 ? \@_ : @_ == 1 ? $_[0] : [];

        return undef unless defined $x;
        return $x if ( Indexer->check($x) );

        unless ( Ref::Util::is_plain_arrayref($x) or $x->$_DOES('PDL') ) {
            $x = [$x];
        }
        if ( $NumericIndices->check($x) ) {
            return Data::Frame::Indexer::Integer->new( indexer => $x->unpdl );
        }
        $fallback_indexer_class->new( indexer => $x );
    };
}

*indexer_s  = _as_indexer('Data::Frame::Indexer::Label');
*indexer_i = _as_indexer('Data::Frame::Indexer::Integer');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Indexer - Function interface for indexer

=head1 VERSION

version 0.0045

=head1 DESCRIPTION

A basic feature needed in a data frame library is the ability of subsetting
a data frame by either numeric indices or string labels of columns and rows.
Because of the ambiguity of number and string in Perl, there needs a way to 
allow user to explicitly specify whether their indexer is by numeric
indices or string labels. This modules provides functions that serves this
purpose. 

=head1 FUNCTIONS

=head2 indexer_s

    indexer_s($x)

Returns either C<undef> or an indexer object, by trying below rules,

=over 4

=item *

If called with C<undef>, returns C<undef>.

=item *

If the argument is an indexer object, just returns it.

=item *

If the argument is a PDL of numeric types, create an indexer object

of L<Data::Frame::Indexer::Integer> 

=item *

Fallbacks to create an indexer object of

L<Data::Frame::Indexer::Label>.

=back

=head2 indexer_i

    indexer_i($x)

Similar to C<indexer_s> but would fallback to an indexer object of
L<Data::Frame::Indexer::Integer>.

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
