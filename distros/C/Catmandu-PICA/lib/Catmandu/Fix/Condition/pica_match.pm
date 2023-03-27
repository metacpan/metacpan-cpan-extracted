package Catmandu::Fix::Condition::pica_match;

our $VERSION = '1.12';

use Catmandu::Sane;
use Catmandu::Fix::pica_map;
use Catmandu::Fix::Condition::all_match;
use Catmandu::Fix::set_field;
use Catmandu::Fix::remove_field;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Condition';

has pica_path => ( fix_arg => 1 );
has value     => ( fix_arg => 1, default => sub { '.*' } );

sub emit {
    my ( $self, $fixer, $label ) = @_;

    my $perl;

    my $tmp_var = '_tmp_' . int( rand(9999) );
    my $pica_map =
      Catmandu::Fix::pica_map->new( $self->pica_path, "$tmp_var.\$append" );
    $perl .= $pica_map->emit( $fixer, $label );

    my $all_match =
      Catmandu::Fix::Condition::all_match->new( "$tmp_var.*", $self->value );
    my $remove_field = Catmandu::Fix::remove_field->new($tmp_var);

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    $all_match->pass_fixes( [ $remove_field, @$pass_fixes ] );
    $all_match->fail_fixes( [ $remove_field, @$fail_fixes ] );

    $perl .= $all_match->emit( $fixer, $label );

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::pica_match - Conditionals on PICA fields

=head1 SYNOPSIS
   
   # pica_match(PICA_PATH,REGEX)
   
   if pica_match('021Aa','My funny title')
   	add_field('my.funny.title','true')
   end

   # pica_match(PICA_PATH)
   # checks whether a field exists
   
   # pica_match($9)
   # checks whether a subfield exists

   if pica_match('001U0')
   	add_field('my.encode_info','true')
   end

=head1 DESCRIPTION

Check whether at least one PICA field or subfield exists or its value matches a
regular expression.

=head1 SEE ALSO

L<Catmandu::Fix::pica_map>

=cut

1;
