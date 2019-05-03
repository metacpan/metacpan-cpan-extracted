package Data::Frame::Util;

# ABSTRACT: Utility functions

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use PDL::Factor  ();
use PDL::SV      ();
use PDL::Logical ();

use List::AllUtils;
use Scalar::Util qw(looks_like_number);
use Type::Params;
use Types::PDL qw(PiddleFromAny);
use Types::Standard qw(ArrayRef Value);

use Data::Frame::Types qw(ColumnLike);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = (
    qw(
      BAD NA
      ifelse is_discrete
      guess_and_convert_to_pdl

      dataframe factor logical
      ),
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );


sub dataframe {
    require Data::Frame;    # to avoid circular use
    Data::Frame->new( columns => \@_ );
}
sub factor    { PDL::Factor->new(@_); }
sub logical   { PDL::Logical->new(@_); }


fun BAD ($n=1) { PDL::Core::zeros($n)->setbadat( PDL::Core::ones($n) ); }
*NA = \&BAD;


fun ifelse ($test, $yes, $no) {
    state $check = Type::Params::compile(
        ( ColumnLike->plus_coercions(PiddleFromAny) ),
        ( ( ColumnLike->plus_coercions(PiddleFromAny) ) x 2 )
    );
    ( $test, $yes, $no ) = $check->( $test, $yes, $no );

    my $l   = $test->length;
    my $idx = which( !$test );

    $yes = $yes->repeat_to_length($l);
    if ( $idx->length == 0 ) {
        return $yes;
    }

    $no = $no->repeat_to_length($l);
    $yes->slice($idx) .= $no->slice($idx);

    return $yes;
}


fun is_discrete (ColumnLike $x) {
    return (
             $x->$_DOES('PDL::Factor')
          or $x->$_DOES('PDL::SV')
          or $x->type eq 'byte'
    );
}


fun guess_and_convert_to_pdl ( (ArrayRef | Value | ColumnLike) $x,
        :$strings_as_factors=false, :$test_count=1000, :$na=[qw(BAD NA)]) {
    return $x if ( $x->$_DOES('PDL') );

    my $is_na = sub {
        length( $_[0] ) == 0 or List::AllUtils::any { $_[0] eq $_ } @$na;
    };

    my $like_number;
    if ( !ref $x ) {
        $like_number = looks_like_number($x);
        $x           = [$x];
    }
    else {
        $like_number = List::AllUtils::all {
            looks_like_number($_) or &$is_na($_);
        }
        @$x[ 0 .. List::AllUtils::min( $test_count - 1, $#$x ) ];
    }

    if ($like_number) {
        my @data   = map { &$is_na($_) ? 'nan' : $_ } @$x;
        my $piddle = pdl( \@data );
        $piddle->inplace->setnantobad;
        return $piddle;
    }
    else {
        my $piddle =
          $strings_as_factors
          ? PDL::Factor->new($x)
          : PDL::SV->new($x);
        my @is_bad = List::AllUtils::indexes { &$is_na($_) } @$x;
        if (@is_bad) {
            $piddle = $piddle->setbadif( pdl( \@is_bad ) );
        }
        return $piddle;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Util - Utility functions

=head1 VERSION

version 0.0047

=head1 DESCRIPTION

This module provides some utility functions used by the Data::Frame project.

=head1 FUNCTIONS

=head2 dataframe

    my $df = dataframe(...); 

Creates a Data::Frame object.

=head2 factor

    my $logical = factor(...); 

Creates a L<PDL::Factor> object.

=head2 logical

    my $logical = logical(...); 

Creates a L<PDL::Logical> object.

=head2 BAD

    my $bad = BAD($n);

A convenient function for generating all-BAD piddles of the given length.

=head2 NA

This is an alias of the C<BAD> function.

=head2 ifelse

    my $rslt_piddle = ifelse($test, $yes, $no)

This function tries to do the same as R's C<ifelse> function. That is,
it returns a piddle of the same length as C<$test>, and is filled with
elements selected from C<$yes> or C<$no> depending on whether the
corresponding element in C<$test> is true or false.

C<$test>, C<$yes>, C<$no> should ideally be piddles or cocere-able to
piddles. 

=head2 is_discrete

    my $bool = is_discrete(ColumnLike $x);

Returns true if C<$x> is discrete, that is, an object of below types,

=over 4

=item *

PDL::Factor

=item *

PDL::SV

=back

=head2 guess_and_convert_to_pdl

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
