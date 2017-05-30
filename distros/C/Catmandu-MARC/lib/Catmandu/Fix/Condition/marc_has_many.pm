package Catmandu::Fix::Condition::marc_has_many;
use Catmandu::Sane;
use Catmandu::Fix::marc_map;
use Catmandu::Fix::Condition::exists;
use Catmandu::Fix::set_field;
use Catmandu::Fix::remove_field;
use Moo;
use Catmandu::Fix::Has;

our $VERSION = '1.12';

with 'Catmandu::Fix::Condition';

has marc_path  => (fix_arg => 1);

sub emit {
    my ($self,$fixer,$label) = @_;

    my $perl;

    my $tmp_var  = '_tmp_' . int(rand(9999));
    my $marc_map = Catmandu::Fix::marc_map->new(
                        $self->marc_path ,
                        "$tmp_var" ,
                        -split=>1 ,
                        -nested_arrays=>1
                    );
    $perl .= $marc_map->emit($fixer,$label);

    my $all_match    =
        $self->marc_path =~ m{^...(\/\d+-\d+)?$} ?
            Catmandu::Fix::Condition::exists->new("$tmp_var.1") :
            Catmandu::Fix::Condition::exists->new("$tmp_var.0.1");

    my $remove_field = Catmandu::Fix::remove_field->new($tmp_var);

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    $all_match->pass_fixes([  @$pass_fixes ]);
    $all_match->fail_fixes([  @$fail_fixes ]);

    $perl .= $all_match->emit($fixer,$label);

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::marc_has_many - Test if a MARC has more than one (sub)field

=head1 SYNOPSIS

   # marc_has_many(MARC_PATH)

   if marc_has_many('245')
   	add_field('error.$append','more than one 245!')
   end

=head1 DESCRIPTION

Evaluate the enclosing fixes only if the MARC has more than one (sub)field.

=head1 METHODS

=head2 marc_has_many(MARC_PATH)

Evaluates to true when the MARC has more than one (sub)field, false otherwise.

=head1 SEE ALSO

L<Catmandu::Fix::marc_has>

=cut

1;
