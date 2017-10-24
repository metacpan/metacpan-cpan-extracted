package Acme::Math::Josan;

use 5.006;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT = qw/josan/;

sub josan {
    my ($num1, $num2) = @_;

    return $num1 * $num2 if int rand(2) == 1;
    return $num1 / $num2;
}

1;

=encoding UTF-8

=head1 NAME

Acme::Math::Josan - do 'josan'

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Do josan (B<乗算> = Multiplication) or josan (B<除算> = Division ).

=head1 SYNOPSIS

    use Acme::Math::Josan;
    my $result = josan(12, 4);
    # $result is 3 or 48.

=head1 METHODS

=head2 josan($num1, $num2)

C<$num1> and C<$num2> is numeric.

=head1 AUTHOR

Nao Muto <n@o625.com>

=cut
