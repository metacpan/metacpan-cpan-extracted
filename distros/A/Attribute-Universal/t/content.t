#!perl

use Test::More tests => 1;

END { done_testing }

our $Stack = {};

END {
    is_deeply(
        $Stack => {
            Test1 => [undef],
            Test2 => [ undef, undef ],
            Test3 => [ undef, undef ],
            Test4 => [ undef, 1, 2 ],
            Test5 => [ 1, 2, 3 ],
        }
    ) or diag( explain($Stack) );
}

use Attribute::Universal Content => 'END';

sub ATTRIBUTE {
    my $hash = Attribute::Universal::to_hash(@_);
    $Stack->{ $hash->{label} } //= [];
    push @{ $Stack->{ $hash->{label} } } => @{ $hash->{content} };
}

sub Test1 : Content;
sub Test2 : Content : Content;
sub Test3 : Content : Content();
sub Test4 : Content : Content(1) : Content(2);
sub Test5 : Content(1) : Content(2) : Content(3);

