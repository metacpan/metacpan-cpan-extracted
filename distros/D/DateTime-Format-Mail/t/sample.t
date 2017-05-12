use strict;
use Test::More;
use File::Spec ();
use DateTime::Format::Mail;

my $sample = File::Spec->catfile(qw( t sample_dates ));
my $fh;

# Smart open since 5.008 will need to do a raw read rather
# than interpret the data as anything other than bytes.
if ( $] >= 5.008 ) {
    eval 'open $fh, "<:raw", $sample'
        or die "Cannot open $sample: $!";
}
else {
    open $fh, "< $sample"
        or die "Cannot open $sample: $!";
}

# Can we parse?
my $class = 'DateTime::Format::Mail';
my $f     = $class->new()->loose();

while (<$fh>) {
    chomp;
    my $p = eval { $f->parse_datetime($_) };
    ok( ( defined $p and ref $p and not $@), $_ );
}

done_testing;
