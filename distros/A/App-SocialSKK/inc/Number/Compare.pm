#line 1
# $Id: Compare.pm 846 2002-10-25 15:46:01Z richardc $
package Number::Compare;
use strict;
use Carp qw(croak);
use vars qw/$VERSION/;
$VERSION = '0.01';

sub new  {
    my $referent = shift;
    my $class = ref $referent || $referent;
    my $expr = $class->parse_to_perl( shift );

    bless eval "sub { \$_[0] $expr }", $class;
}

sub parse_to_perl {
    shift;
    my $test = shift;

    $test =~ m{^
               ([<>]=?)?   # comparison
               (.*?)       # value
               ([kmg]i?)?  # magnitude
              $}ix
       or croak "don't understand '$test' as a test";

    my $comparison = $1 || '==';
    my $target     = $2;
    my $magnitude  = $3;
    $target *=           1000 if lc $magnitude eq 'k';
    $target *=           1024 if lc $magnitude eq 'ki';
    $target *=        1000000 if lc $magnitude eq 'm';
    $target *=      1024*1024 if lc $magnitude eq 'mi';
    $target *=     1000000000 if lc $magnitude eq 'g';
    $target *= 1024*1024*1024 if lc $magnitude eq 'gi';

    return "$comparison $target";
}

sub test { $_[0]->( $_[1] ) }

1;

__END__

#line 100
