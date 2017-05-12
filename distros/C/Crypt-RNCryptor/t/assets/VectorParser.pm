package t::assets::VectorParser;
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Spec;

use Class::Accessor::Lite (
    ro => [qw(datasets)],
);

sub load {
    my ($class, $version, $type) = @_;

    my @datasets;

    my $path = File::Spec->catfile(dirname(__FILE__), "v${version}", $type);
    open my $fh, '<', $path;
    my $data = {};
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^\s*$/ || index($line, '#') == 0) {
            push @datasets, $data if scalar(%$data);
            $data = {};
            next;
        }
        my ($key, $value) = $line =~ /^(\w+):\s*(.+)$/;
        $data->{$key} = $value if $key;
    }
    close $fh;

    bless {
        datasets => \@datasets,
    }, $class;
}

sub get {
    my ($self, $idx, $key, $is_hex) = @_;
    my $v = $self->datasets->[$idx]{$key};
    $v ||= '';
    return $v unless $is_hex;
    $v =~ s/ //g;
    pack('H*', $v);
}

sub num { scalar @{$_[0]->datasets} }

1;

__END__

=head1 SYNOPSYS

    use t::assets::VectorParser;
    my $vp = t::assets::VectorParser->load(3, 'kdf');
    $vp->datasets;
    $vp->num;
    $vp->get(0, 'key');
    $vp->get(0, 'hex_key', 1);
