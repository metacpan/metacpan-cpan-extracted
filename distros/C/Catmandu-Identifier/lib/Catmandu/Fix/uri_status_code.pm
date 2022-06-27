package Catmandu::Fix::uri_status_code;

our $VERSION = '0.15';

use Catmandu::Sane;
use LWP::UserAgent;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);

    $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $var = shift;
            "${var} = LWP::UserAgent->new->get(${var})->code if is_value(${var}) && length(${var});";
        }
    );
}

=head1 NAME

Catmandu::Fix::uri_status_code - check the HTTP status of a uri

=head1 SYNOPSIS

  copy_field(url,status)
  uri_status_code(status) # status => '200'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
