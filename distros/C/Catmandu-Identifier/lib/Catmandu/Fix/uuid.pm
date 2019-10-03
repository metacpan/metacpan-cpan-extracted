package Catmandu::Fix::uuid;

our $VERSION = '0.12';

use Catmandu::Sane;
use Data::UUID::MT;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);

    $fixer->emit_create_path($fixer->var, $path, sub {
        my $var = shift;
        "${var} = Data::UUID::MT->new(version => 4)->create_string;";
    });
}

=head1 NAME

Catmandu::Fix::uuid - create a Globally/Universally Unique Identifier

=head1 SYNOPSIS

  uuid(my.field) # my => {field => '4162F712-1DD2-11B2-B17E-C09EFE1DC403' }

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
