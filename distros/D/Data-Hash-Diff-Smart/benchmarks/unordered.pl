# unordered.pl
{
    my $old = [ map { int(rand(100)) } 1..2000 ];
    my $new = [ map { int(rand(100)) } 1..2000 ];

    ($old, $new, array_mode => 'unordered');
}
