package Algorithm::MedianSelect::XS;

use strict;
use warnings;
use base qw(Exporter);

use Carp qw(carp croak);

our ($VERSION, @EXPORT_OK);

$VERSION = '0.21';
@EXPORT_OK = qw(median);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub median
{
    my $opts = pop if ref $_[-1] eq 'HASH';
    my @nums = @_;

    my $count = ref $nums[0] eq 'ARRAY' ? @{$nums[0]} : @nums;
    croak "median(): list must have odd count of elements and must have more than one element\n" 
      if ($count % 2 == 0 or $count == 1);

    my $i;
    my %valid_alg = map { $_ => ++$i } qw(bubble quick);

    my $algorithm;

    if (exists $opts->{algorithm} && $valid_alg{$opts->{algorithm}}) {
        $algorithm = $opts->{algorithm};
    }
    else {
        carp "'$opts->{algorithm}' is not a valid algorithm, switching to default...\n"
          if defined $opts->{algorithm};

        $algorithm ||= 'quick';
    }

    no strict 'refs';
    ${__PACKAGE__.'::ALGORITHM'} = $valid_alg{$algorithm};

    if (ref $nums[0] eq 'ARRAY') { return xs_median($nums[0]) }
    else                         { return xs_median(@nums)    }
}

1;
__END__

=head1 NAME

Algorithm::MedianSelect::XS - Median finding algorithm

=head1 SYNOPSIS

 use Algorithm::MedianSelect::XS qw(median);

 @numbers = (21, 6, 2, 9, 5, 1, 14, 7, 12, 3, 19);

 print median(@numbers);
 print median(\@numbers);

 print median(\@numbers, { algorithm => 'bubble' }); # slow algorithm
 print median(\@numbers, { algorithm => 'quick'  }); # default algorithm

=head1 DESCRIPTION

C<Algorithm::MedianSelect::XS> finds the item which is smaller
than half of the integers and bigger than half of the integers.

=head1 FUNCTIONS

=head2 median

Takes a list or reference to list of integers and returns the median number.
Optionally, the algorithm being used for computation may be specified within
a hash reference. See SYNOPSIS for algorithms currently available.

=head1 EXPORT

C<median()> is exportable.

=head1 SEE ALSO

L<http://www.cs.sunysb.edu/~algorith/files/median.shtml>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

