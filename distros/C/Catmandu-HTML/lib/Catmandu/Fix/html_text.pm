package Catmandu::Fix::html_text;

our $VERSION = '0.02';

use Catmandu::Sane;
use Moo;
use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has join  => (fix_opt => 1);
has split => (fix_opt => 1);

sub fix {
    my ($self,$data) = @_;

    return $data unless Catmandu::Util::is_array_ref($data->{html});

    my $join_char = $self->join // '';
    my $is_split  = $self->split;

    my @token;

    for (@{$data->{html}}) {
        if ($_->[0] eq 'S') {
            push @token , $_->[4];
        }
        elsif ($_->[0] eq 'E') {
            push @token , $_->[2];
        }
        elsif ($_->[0] eq 'T') {
            push @token , $_->[1];
        }
        elsif ($_->[0] eq 'C') {
            push @token , $_->[1];
        }
        elsif ($_->[0] eq 'D') {
            push @token , $_->[1];
        }
        elsif ($_->[0] eq 'PI') {
            push @token , $_->[2];
        }
    }

    if ($is_split) {
        $data->{html} = \@token;
    }
    else {
        $data->{html} = join $join_char , @token;
    }

    return $data;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::html_text - keep only the textual data in the HTML

=head1 SYNOPSIS

   # keep only the text
   html_text()
   # returns:
   #  html: "<html>...</html>"

   # keep only the text but return an array_ref
   html_text(split:1)
   # returns:
   #  html:
   #    - <html>
   #    - ...
   #    - </html>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
