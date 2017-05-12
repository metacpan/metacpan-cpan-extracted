use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception);
use Data::Iterator::SlidingWindow;

my @list = ( 0 .. 20 );

my $iter = iterator 3 => \@list;

isa_ok $iter, 'Data::Iterator::SlidingWindow';

my @w1;
while ( my $data = $iter->next ) {
    push @w1, $data;
}
is scalar(@w1), 19, 'n - (window_size - 1)';

my $i = 0;
$iter = iterator 3 => sub {
    return if $i > 20;
    return $i++;
};

isa_ok $iter, 'Data::Iterator::SlidingWindow';

my @w2;
while (<$iter>) {
    push @w2, $_;
}
is scalar(@w2), 19, 'n - (window_size - 1)';

is_deeply \@w1, \@w2;

like exception { iterator( undef, [] ) }, qr{^window size must be positive integer}, 'Window size value type';
like exception { iterator( 0,     [] ) }, qr{^window size must be positive integer}, 'Window size value type';
like exception { iterator( 'a',   [] ) }, qr{^window size must be positive integer}, 'Window size value type';

like exception { iterator( 2, undef ) }, qr{^data_source must be CODE reference or ARRAY refernce},
    'data_source value type';
like exception { iterator( 2, {} ) }, qr{^data_source must be CODE reference or ARRAY refernce},
    'data_source value type';

done_testing;

__END__
