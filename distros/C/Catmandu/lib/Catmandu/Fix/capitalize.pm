package Catmandu::Fix::capitalize;

use Catmandu::Sane;

our $VERSION = '1.2025';

use Moo;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Util       qw(as_utf8);
use namespace::clean;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path => (fix_arg => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)
        ->updater(if_string => sub {ucfirst lc as_utf8 $_[0]});
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::capitalize - capitalize the value of a key

=head1 SYNOPSIS

   # Capitalize the value of foo. E.g. foo => 'bar'
   capitalize(foo)  # foo => 'Bar'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
