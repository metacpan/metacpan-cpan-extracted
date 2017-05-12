package TestParser;

use Catmandu::Sane;
use Moo;

has metadataPrefix => (is => 'ro' , default => sub { "marcxml" });

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my $rec = { test => 'ok' };

    $rec;
}

1;