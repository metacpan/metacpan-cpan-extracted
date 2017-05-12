#!perl

use Test::More tests => 5;
use Scalar::Util qw(refaddr);

END { done_testing }

our $Stack = {};

END {
    my $Test1 = refaddr( \&Test1 );
    my $Test2 = refaddr( \&Test2 );
    my $Test3 = refaddr( \&Test3 );
    my $Test4 = refaddr( \&Test4 );
    my $Test5 = refaddr( \&Test5 );
    is_deeply( $Stack->{$Test1}->{Content}->{content} => [undef] );
    is_deeply( $Stack->{$Test2}->{Content}->{content} => [ undef, undef ] );
    is_deeply( $Stack->{$Test3}->{Content}->{content} => [ undef, undef ] );
    is_deeply( $Stack->{$Test4}->{Content}->{content} => [ undef, 1, 2 ] );
    is_deeply( $Stack->{$Test5}->{Content}->{content} => [ 1, 2, 3 ] );
}

use Attribute::Universal Content => 'END';

sub ATTRIBUTE {
    Attribute::Universal::collect_by_referent( $Stack, @_ );
}

sub Test1 : Content;
sub Test2 : Content : Content;
sub Test3 : Content : Content();
sub Test4 : Content : Content(1) : Content(2);
sub Test5 : Content(1) : Content(2) : Content(3);

