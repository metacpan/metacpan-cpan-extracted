package Test::zxcvbn;
use strict;
use warnings;
use Exporter 'import';
use Test::Most;

our @EXPORT_OK=qw(match_for_testing cmp_match cmp_sequence generate_combinations);

{
    package TestMatch;
    use Moo;
    with 'Data::Password::zxcvbn::Match';
    sub estimate_guesses { 1 }
    sub feedback_warning { }
    sub feedback_suggestions { }
    sub make { }
    sub guesses_for_password { shift->guesses }
}

sub match_for_testing {
    my ($i,$j,$guesses) = @_;

    return TestMatch->new({
        i => $i,
        j => $j,
        guesses => $guesses,
        token => '',
    });
}

sub cmp_match {
    my ($i,$j,$class,%methods) = @_;
    $class = "Data::Password::zxcvbn::Match::$class";

    return all(
        isa($class),
        methods(
            i => $i,
            j => $j,
            %methods,
        ),
    );
}

sub cmp_sequence {
    my ($result, $expected, $message) = @_;

    $expected = { matches => $expected } if ref($expected) eq 'ARRAY';

    cmp_deeply(
        $result,
        methods(%{$expected}),
        $message,
    ) or explain $result;
}

sub generate_combinations {
    my ($pattern,$prefixes,$suffixes) = @_;
    $prefixes ||= []; $suffixes ||= [];
    my @result = ();
    for my $prefix (@{$prefixes},'') {
        for my $suffix (@{$suffixes},'') {
            push @result, [
                "${prefix}${pattern}${suffix}",
                length($prefix),
                length($prefix)+length($pattern)-1,
            ];
        }
    }

    return @result;
}

1;
