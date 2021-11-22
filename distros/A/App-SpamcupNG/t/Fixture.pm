package Fixture;
use strict;
use warnings;
use Exporter 'import';
use File::Spec;

our @EXPORT_OK = qw(read_html);

sub read_html {
    my $html_file = shift;
    my $full_path = File::Spec->catfile( ( 't', 'responses' ), $html_file );
    open( my $in, '<', $full_path ) or die "Cannot read $full_path: $!";
    local $/ = undef;
    my $content = <$in>;
    close($in);
    return \$content;
}

1;
