package Data::Frame::Util;

# ABSTRACT: Utility functions

use Data::Frame::Setup;

use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use PDL::Factor  ();
use PDL::SV      ();
use PDL::Logical ();

use List::AllUtils qw(uniq);
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
sub factor  { PDL::Factor->new(@_); }
sub logical { PDL::Logical->new(@_); }


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


sub _is_na {
    my ($na, $include_empty) = @_;

    my @na = uniq(@$na, ($include_empty ? '' : ()));

    # see utils/benchmarks/is_na.pl for why grep is used here
    return sub {
        scalar( grep { $_[0] eq $_ } @na );
    };
}

sub _numeric_from_arrayref {
    my ($x, $na, $f) = @_;
    $f //= \&PDL::Core::pdl;

    my $is_na = _is_na($na, 1);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    my $p = do {
        local $SIG{__WARN__} = sub { };
        $f->($x);
    };
    return $p->setbadif($isbad);
}

sub _logical_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 1);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    my $p = PDL::Logical->new($x);
    return $p->setbadif($isbad);
}

sub _datetime_from_arrayref {
    my ($x, $na) = @_;
    return _numeric_from_arrayref( $x, $na,
        sub { PDL::DateTime->new_from_datetime( $_[0] ) } );
}

sub _factor_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 0);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    if ( $isbad->any ) {    # remove $na from levels
        my $levels = [ sort grep { !&$is_na($_) } uniq(@$x) ];
        return PDL::Factor->new( $x, levels => $levels )->setbadif($isbad);
    } else {
        return PDL::Factor->new($x);
    }
}

sub _pdlsv_from_arrayref {
    my ($x, $na) = @_;

    my $is_na = _is_na($na, 0);
    my $isbad = pdl( [ map { &$is_na($_) } @$x ] );
    return PDL::SV->new($x)->setbadif($isbad);
}

fun guess_and_convert_to_pdl ( (ArrayRef | Value | ColumnLike) $x,
        :$strings_as_factors=false, :$test_count=1000, :$na=[qw(NA BAD)]) {
    return $x if ( $x->$_DOES('PDL') );

    my $is_na0 = _is_na($na, 1);
    my $like_number;
    if ( !ref $x ) {
        $like_number = looks_like_number($x);
        $x           = [$x];
    }
    else {
        $like_number = List::AllUtils::all {
            looks_like_number($_) or &$is_na0($_);
        }
        @$x[ 0 .. List::AllUtils::min( $test_count - 1, $#$x ) ];
    }

    # The $na parameter is only effective for logical and numeric columns.
    # This is in align with R's from_csv behavior.
    if ($like_number) {
        return _numeric_from_arrayref($x, $na);
    }
    else {
        if ($strings_as_factors) {
            return _factor_from_arrayref($x, $na);
        }
        else {
            return _pdlsv_from_arrayref($x, $na);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Util - Utility functions

=head1 VERSION

version 0.0053

=head1 DESCRIPTION

This module provides some utility functions used by the L<Data::Frame> project.

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
