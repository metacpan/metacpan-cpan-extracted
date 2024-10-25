package Test2::Tools::DataFrame;
$Test2::Tools::DataFrame::VERSION = '0.006003';
# ABSTRACT: Tools for verifying Data::Frame data frames

use 5.010;
use strict;
use warnings;

# VERSION

use Safe::Isa;
use Test2::API qw/context/;
use Test2::Util::Table qw/table/;
use Test2::Util::Ref qw/render_ref/;

use parent qw(Exporter::Tiny);
our @EXPORT = qw(dataframe_ok dataframe_is);


sub dataframe_ok ($;$) {
    my ( $thing, $name ) = @_;
    my $ctx = context();

    unless ( $thing->$_DOES('Data::Frame') ) {
        my $thingname = render_ref($thing);
        $ctx->ok( 0, $name, ["'$thingname' is not a data frame object."] );
        $ctx->release;
        return 0;
    }

    $ctx->ok( 1, $name );
    $ctx->release;
    return 1;
}


sub dataframe_is ($$;$@) {
    my ( $got, $exp, $name, @diag ) = @_;
    my $ctx = context();

    local $Data::Frame::TOLERANCE_REL = 1e-8 unless $Data::Frame::TOLERANCE_REL;

    unless ( $got->$_DOES('Data::Frame') ) {
        my $gotname = render_ref($got);
        $ctx->ok( 0, $name,
            ["First argument '$gotname' is not a data frame object."] );
        $ctx->release;
        return 0;
    }
    unless ( $exp->$_DOES('Data::Frame') ) {
        my $expname = render_ref($exp);
        $ctx->ok( 0, $name,
            ["Second argument '$expname' is not a data frame object."] );
        $ctx->release;
        return 0;
    }

    my $diff;
    eval { $diff = ( $got != $exp ); };
    if ($@) {
        my $gotname = render_ref($got);
        $ctx->ok( 0, $name, [ "'$gotname' is different from expected.", $@ ],
            @diag );
        $ctx->release;
        return 0;
    }
    my $diff_which = $diff->which( bad_to_val => 1 );
    unless ( $diff_which->isempty ) {
        my $gotname      = render_ref($got);
        my $column_names = $exp->column_names;
        my @table        = table(
            sanitize  => 1,
            max_width => 80,
            collapse  => 1,
            header    => [qw(ROWIDX COLUMN GOT CHECK)],
            rows      => [
                map {
                    my ( $ridx, $cidx ) = @$_;
                    [
                        $ridx, $column_names->[$cidx],
                        $got->at( $ridx, $cidx ), $exp->at( $ridx, $cidx )
                    ]
                } @{ $diff_which->unpdl }
            ]
        );
        $ctx->ok( 0, $name,
            [ "'$gotname' is different from expected.", @table ], @diag );
        $ctx->release;
        return 0;
    }

    $ctx->ok( 1, $name );
    $ctx->release;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::DataFrame - Tools for verifying Data::Frame data frames

=head1 VERSION

version 0.006003

=head1 SYNOPSIS

    use Test2::Tools::DataFrame;

    # Functions are exported by default.
    
    # Ensure something is a data frame.
    dataframe_ok($df);

    # Compare two data frames.
    dataframe_is($got, $expected, 'Same data frame.');

=head1 FUNCTIONS

=head2 dataframe_ok($thing, $name)

Checks that the given C<$thing> is a L<Data::Frame> object.

=head2 dataframe_is($got, $exp, $name);

Checks that data frame C<$got> is same as C<$exp>.

=head1 DESCRIPTION 

This module contains tools for verifying L<Data::Frame> data frame
objects.

=head1 SEE ALSO

L<Data::Frame>,
L<Test2::Suite> 

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
