package Catmandu::Fix::Condition::marc_spec_has;
use Catmandu::Sane;
use Catmandu::Fix::marc_spec;
use Catmandu::Fix::Condition::exists;
use Catmandu::Fix::set_field;
use Catmandu::Fix::remove_field;
use Moo;
use Catmandu::Fix::Has;

our $VERSION = '1.12';

with 'Catmandu::Fix::Condition';

has marc_spec  => (fix_arg => 1);

sub emit {
    my ($self,$fixer,$label) = @_;

    my $perl;

    my $tmp_var  = '_tmp_' . int(rand(9999));
    my $marc_spec = Catmandu::Fix::marc_spec->new($self->marc_spec , "$tmp_var.\$append");
    $perl .= $marc_spec->emit($fixer,$label);

    my $all_match    = Catmandu::Fix::Condition::exists->new("$tmp_var");
    my $remove_field = Catmandu::Fix::remove_field->new($tmp_var);

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    $all_match->pass_fixes([ $remove_field , @$pass_fixes ]);
    $all_match->fail_fixes([ $remove_field , @$fail_fixes ]);

    $perl .= $all_match->emit($fixer,$label);

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::marc_spec_has - Test if a MARCspec references data

=head1 SYNOPSIS

   # marc_spec_has(MARCspec)

   unless marc_spec_has('LDR{/6=\a}{/7=\a|/7=\c|/7=\d|/7=\m}')
        set_field('type','Book')
   end

=head1 DESCRIPTION

Evaluate the enclosing fixes only if the MARCspec does reference data.

Does the same like  L<marc_has|Catmandu::Fix::Condition::marc_has> but uses
MARCspec - A common MARC record path language.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/>
for documentation on the path syntax.

=head1 METHODS

=head2 marc_spec_has(MARCspec)

Evaluates to true when the MARCspec references data, false otherwise.

=head1 SEE ALSO

=over

=item * L<Catmandu::Fix::marc_has>

=item * L<Catmandu::Fix::marc_match>

=item * L<Catmandu::Fix::marc_has_many>

=back

=cut

1;
