use strict;

my $class = $ENV{DATETIME_CLASS} || 'DateTimeX::Lite';

my $before = get_memory();
print "memory usage before using $class: $before\n";

eval "require $class";

for(1..100) {
    $class->new(year => 2000, month => 1, day => 1);
}

my $after = get_memory();
print "memory usage after using $class: $after\n";
print "  memory used = ", $after - $before, "\n";

sub get_memory {
    my $output = `ps -opid,rss`;

    foreach (split /\n/, $output) {
        next unless /^\s(\d+)\s+(\d+)/;
        next unless $1 eq $$;

        return $2;
    }
}
