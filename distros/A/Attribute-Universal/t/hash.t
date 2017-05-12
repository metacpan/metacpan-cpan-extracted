#!perl

use Test::More tests => 1;

END { done_testing }

our $Stack = [];

END {
    is_deeply(
        $Stack => [
            {
                attribute => 'Test',
                content   => [undef],
                full_name => '&main::Code',
                label     => 'Code',
                name      => '&Code',
                package   => 'main',
                payload   => undef,
                phase     => 'END',
                referent  => \&Code,
                sigil     => '&',
                symbol    => \*::Code,
                type      => 'CODE',
            },
            {
                attribute => 'Test',
                content   => [undef],
                full_name => '$main::Scalar',
                label     => 'Scalar',
                name      => '$Scalar',
                package   => 'main',
                payload   => undef,
                phase     => 'END',
                referent  => \$Scalar,
                sigil     => '$',
                symbol    => \*::Scalar,
                type      => 'SCALAR',
            },
            {
                attribute => 'Test',
                content   => [undef],
                full_name => '@main::Array',
                label     => 'Array',
                name      => '@Array',
                package   => 'main',
                payload   => undef,
                phase     => 'END',
                referent  => \@Array,
                sigil     => '@',
                symbol    => \*::Array,
                type      => 'ARRAY',
            },
            {
                attribute => 'Test',
                content   => [undef],
                full_name => '%main::Hash',
                label     => 'Hash',
                name      => '%Hash',
                package   => 'main',
                payload   => undef,
                phase     => 'END',
                referent  => \%Hash,
                sigil     => '%',
                symbol    => \*::Hash,
                type      => 'HASH',
            }
        ]
    ) or diag( explain($Stack) );
}

use Attribute::Universal Test => 'END';

sub ATTRIBUTE {
    my $hash = Attribute::Universal::to_hash(@_);
    delete $hash->{file};
    delete $hash->{line};
    push @$Stack => $hash;
}

sub Code : Test;
our $Scalar : Test;
our @Array : Test;
our %Hash : Test;
