package Catmandu::Fix::latex_decode;

our $VERSION = '0.20';

use Moo;
use Catmandu::Sane;
use Catmandu::Util qw(as_utf8);
use Catmandu::Util::Path qw(as_path);
use LaTeX::Decode;
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);
has opts => (fix_opt => 'collect');

sub _build_fixer {
    my ($self) = @_;
    my $opts = $self->opts;
    as_path($self->path)
        ->updater(if_string => sub {latex_decode($_[0], %$opts)});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Catmandu::Fix::latex_decode - decode test from LaTeX to Unicode

=head1 SYNOPSIS

   # decode the latex string in field 'foo'. E.g. foo => 'b\\"ar'
   latex_decode(foo) # foo => 'bär'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
~    
