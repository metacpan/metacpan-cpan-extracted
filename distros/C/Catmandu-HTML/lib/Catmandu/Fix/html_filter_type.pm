package Catmandu::Fix::html_filter_type;

our $VERSION = '0.02';

use Catmandu::Sane;
use Moo;
use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has type  => (fix_arg => 1);

sub fix {
    my ($self,$data) = @_;

    return $data unless Catmandu::Util::is_array_ref($data->{html});

    my $type = $self->type;

    my @token;

    for (@{$data->{html}}) {
        if ($_->[0] =~ /^$type$/) {
            push @token , $_;
        }
    }

    $data->{html} = \@token;

    return $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::html_filter_tag - filter html on type type

=head1 SYNOPSIS

   # keep only the 'T' type data fields
   html_filter_type(T)

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
