use strict;
use warnings;

package DateTime::Format::PGN;
# ABSTRACT: a Perl module for parsing and formatting date fields in chess game databases in PGN format

our $VERSION = '0.05';

use DateTime::Incomplete 0.08;
use Params::Validate 1.23 qw( validate BOOLEAN );


sub new {
    my( $class ) = shift;

    my %args = validate( @_,
        {
            fix_errors => {
                type        => BOOLEAN,
                default     => 0,
                callbacks   => {
                    'is 0, 1, or undef' =>
                        sub { ! defined( $_[0] ) || $_[0] == 0 || $_[0] == 1 },
                },
            },
            use_incomplete => {
                type        => BOOLEAN,
                default     => 0,
                callbacks   => {
                    'is 0, 1, or undef' =>
                        sub { ! defined( $_[0] ) || $_[0] == 0 || $_[0] == 1 },
                },
            },
        }
    );

    $class = ref( $class ) || $class;

    my $self = bless( \%args, $class );

    return( $self );
}



sub parse_datetime {
    my ( $self, $date ) = @_;
    my @matches = ( '????', '??', '??' );
    
    if ($date =~ m/^(\?{4}|[1-2]\d{3})\.(\?{2}|0[1-9]|1[0-2])\.(\?{2}|0[1-9]|[1-2]\d|3[0-1])$/) {
    
        @matches = ( $1,$2,$3 );
    }
    else {
    
        # We can try to fix frequently occuring faults.
        if ($self->{ fix_errors }) {
             
            # if we find a year, we can try to parse the wrong date.
            if ($date =~ /(\A|\D)([1-2]\d{3})(\D|\Z)/ && $2 > 0) {
        
                $matches[0] = $2;
                
                # Try to find month and day.
                if ($date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])\D+(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/) {
                    if (($2 < 13 && $3 > 12) || ($2 == $3 && $2 < 13)) {
                        $matches[1] = $2;
                        $matches[2] = $3;
                    }
                    elsif ($3 < 13 && $2 > 12) {
                        $matches[1] = $3;
                        $matches[2] = $2;
                    }
                }
                elsif (index($date,'Jan') > -1) {
                    $matches[1] = 1;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Feb') > -1) {
                    $matches[1] = 2;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Mar') > -1) {
                    $matches[1] = 3;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Apr') > -1) {
                    $matches[1] = 4;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|30)(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'May') > -1) {
                    $matches[1] = 5;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Jun') > -1) {
                    $matches[1] = 6;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|30)(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Jul') > -1) {
                    $matches[1] = 7;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Aug') > -1) {
                    $matches[1] = 8;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Sep') > -1) {
                    $matches[1] = 9;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|30)(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Oct') > -1) {
                    $matches[1] = 10;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Nov') > -1) {
                    $matches[1] = 11;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|30)(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                elsif (index($date,'Dec') > -1) {
                    $matches[1] = 12;
                    $matches[2] = $2 if $date =~ /(\A|\D)(0?[1-9]|[1-2][0-9]|3[0-1])(\D|\Z)/ && $2 < 32 && $2 > 0;
                }
                
                # check month length
                if (index($matches[1],'?') == -1 && index($matches[2],'?') == -1) {
                    if ($matches[2] == 31 && ($matches[1] == 4 || $matches[1] == 6 || $matches[1] == 9 || $matches[1] == 9 || $matches[1] == 11)) {
                        $matches[1] = '??';
                        $matches[2] = '??';
                    }
                    elsif ($matches[1] == 2) {
                        if (($matches[2] == 29 && $matches[0] % 4 == 0 && $matches[0] % 100 > 0) || $matches[2] < 29) {}
                        else {
                            $matches[1] = '??';
                            $matches[2] = '??';
                        }
                    }
                }
            }
        }
    }    
    
    # If incomplete data should be preserved, we must create a DateTime::Incomplete object instead.
    if ( $self->{ use_incomplete } ) {
    
        grep { $_  = undef if index($_,'?') > -1 } @matches;
        
        return DateTime::Incomplete->new(
            year       => $matches[0],
            month      => $matches[1],
            day        => $matches[2],
            formatter  => $self,
        );
    }
    # Otherwise the usual DateTime object.
    else {
    
        grep { $_  = 1 if index($_,'?') > -1 } @matches;
        
        return DateTime->new(
            year       => $matches[0],
            month      => $matches[1],
            day        => $matches[2],
            formatter  => $self,
        );
    }
}


sub format_datetime {
    my ( $self, $dt ) = @_;
    
    my $year = (defined $dt->year()) ? $dt->year() : '????';
    my $month = (defined $dt->month()) ? $dt->month() : '??';
    my $day = (defined $dt->day()) ? $dt->day() : '??';
    
    return sprintf '%04s.%02s.%02s', $year, $month, $day;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::PGN - a Perl module for parsing and formatting date fields in chess game databases in PGN format

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use DateTime::Format::PGN;
 
    my $f = DateTime::Format::PGN->new();
    my $dt = $f->parse_datetime( '2004.04.23' );
 
    # 2004.04.23
    print $f->format_datetime( $dt );
    
    # return a DateTime::Incomplete object:
    my $fi = DateTime::Format::PGN->new( { use_incomplete => 1} );
    my $dti = $fi->parse_datetime( '2004.??.??' );
    
    # 2004.??.??
    print $fi->format_datetime( $dti );

=head1 METHODS

=head2 new(%options)

Options are Boolean C<use_incomplete> (default 0) and Boolean C<fix_errors> (default 0).

    my $f = DateTime::Format::PGN->new( { fix_errors => 1, use_incomplete => 1 } );

PGN allows for incomplete dates while C<DateTime> does not. All missing date values in C<DateTime> default to 1. So PGN C<????.??.??> becomes 
C<0001.01.01> with C<DateTime>. If C<use_incomplete =E<gt> 1>, a C<DateTime::Incomplete> object is used instead where missing values are C<undef>.

I observed a lot of mistaken date formats in PGN databases downloaded from the internet. If C<fix_errors =E<gt> 1>, an attempt is made to parse the 
date anyway.

=head2 parse_datetime($string)

Returns a C<DateTime> object or a C<DateTime::Incomplete> object if option C<use_incomplete =E<gt> 1>. Since the first recorded chess game 
was played 1485, years with a leading 0 are handled as errors.

=head2 format_datetime($datetime)

Given a C<DateTime> object, this methods returns a PGN date string. If the date is incomplete, use 
a C<DateTime::Incomplete> object (the C<use_incomplete> option does not affect the formatting here).

=head1 Source

L<PGN spec|https://www.chessclub.com/user/help/PGN-spec> by Steven J. Edwards.

=head1 See also

=over 4

=item *

L<Chess::PGN::Parse>

=item *

L<DateTime::Incomplete>

=item *

L<http://datetime.perl.org/>

=back

=head1 AUTHOR

Ingram Braun <ibraun@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ingram Braun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
