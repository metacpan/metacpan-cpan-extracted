package App::Math::Tutor::Util;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Util - Utilities for easier Math Tutorial Exercises generation

=cut

use vars qw();

use Exporter;

our $VERSION     = '0.005';
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(sumcat_terms prodcat_terms);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use Scalar::Util qw/blessed/;

my %sum_opposites = (
    '+'   => '-',
    '-'   => '+',
    '\pm' => '\mp',
    '\mp' => '\pm',
);

=head1 EXPORTS

=head2 sumcat_terms

  my $formatted = sumcat_terms( "-", VulFrac->new( num => $p, denum => 2, sign => -1 ),
                                     Power->new( mode => 1, basis => $d, exponent =>
                                         VulFrac->new( num => 1, denum => 2 ) ) );
  say $formatted;
  # \frac{\frac{7}{4}}{2}\pm\sqrt{-\left(\frac{\frac{7}{4}}{2}\right)-\frac{3}{4}}

Concatenates terms using specified kind of addition operation

=cut

sub sumcat_terms
{
    my ( $op, @terms ) = @_;
    my $str = "";
    my $i   = 0;

    foreach $i ( 0 .. $#terms )
    {
        my $term = $terms[$i];
        $term or next;
        $str = "$term" and next unless $i;
        my $c_op = $op;
        my $sign = blessed $term ? $term->sign : $term <=> 0;
        if ( $sign < 0 )
        {
            $term = blessed $term ? $term->_abs() : abs($term);
            $c_op = $sum_opposites{$op};
        }
        $str .= "${c_op}${term}";
    }

    $str =~ s/^\+//;
    $str;
}

my %prod_ops = (
    '*' => '\cdot',
    '/' => '\div',
);

=head2 prodcat_terms

  my $formatted = prodcat_terms( "/", VulFrac->new( num => $p, denum => 2 ), ...

=cut

sub prodcat_terms
{
    my ( $op, @terms ) = @_;
    my $str = "";
    my $i   = 0;

    foreach $i ( 0 .. $#terms )
    {
        my $term = $terms[$i] or return "0" if ( $op eq "*" );
        $term = $terms[$i] or return "inf" if ( $op eq "/" );
        $str = "$term" and next unless $i;
        my $c_op = $prod_ops{$op};
        $str .= "${c_op}{}${term}";
    }

    $str;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
