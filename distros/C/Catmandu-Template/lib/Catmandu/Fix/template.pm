package Catmandu::Fix::template;

use Moo;
use Template;
use Catmandu;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path  => (fix_arg => 1);
has value => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;

    my $path  = $fixer->split_path($self->path);
    my $value = $fixer->emit_value($self->value);
    my $tt    = $fixer->capture(Template->new);

    $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $var    = shift;
            my $root   = $fixer->var;
            my $output = $fixer->generate_var;
            my $perl   = $fixer->emit_declare_vars($output, '""');
            $perl .= "${tt}->process(\\${value},${root},\\${output});";
            $perl .= "${var} = ${output};";
            $perl;
        }
    );
}

=head1 NAME

Catmandu::Fix::template - add a value to the record based on a template

=head1 SYNOPSIS

   # Your record contains:
   #
   #  name: John
   #  age: 44

   template(message,"Mr [%name%] is [%age%] years old")

   # Result:
   #
   #  name: John
   #  age: 44
   #  message: Mr John is 44  years old

=head1 SEE ALSO

L<Catmandu::Fix>, L<Template>

=cut

1;
