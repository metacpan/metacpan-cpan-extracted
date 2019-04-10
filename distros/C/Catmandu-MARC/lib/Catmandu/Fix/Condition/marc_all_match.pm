package Catmandu::Fix::Condition::marc_all_match;
use Catmandu::Sane;
use Catmandu::Fix::marc_map;
use Catmandu::Fix::Condition::all_match;
use Catmandu::Fix::set_field;
use Catmandu::Fix::remove_field;
use Moo;
use Catmandu::Fix::Has;

our $VERSION = '1.251';

with 'Catmandu::Fix::Condition';

has marc_path  => (fix_arg => 1);
has value      => (fix_arg => 1);

sub emit {
    my ($self,$fixer,$label) = @_;

    my $perl;

    my $tmp_var  = '_tmp_' . int(rand(9999));
    my $marc_map = Catmandu::Fix::marc_map->new($self->marc_path , "$tmp_var.\$append");
    $perl .= $marc_map->emit($fixer,$label);

    my $all_match    = Catmandu::Fix::Condition::all_match->new("$tmp_var.*",$self->value);
    my $remove_field = Catmandu::Fix::remove_field->new($tmp_var);

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    $all_match->pass_fixes([ $remove_field , @$pass_fixes ]);
    $all_match->fail_fixes([ $remove_field , @$fail_fixes ]);

    $perl .= $all_match->emit($fixer,$label);

    $perl;
}

=head1 NAME

Catmandu::Fix::Condition::marc_all_match - Test if a MARC (sub)field matches a value

=head1 SYNOPSIS

   # marc_all_match(MARC_PATH,REGEX)

   # Match when 245 contains the value "My funny title"
   if marc_all_match('245','My funny title')
   	add_field('my.funny.title','true')
   end

   # Match when 245a contains the value "My funny title"
   if marc_all_match('245a','My funny title')
   	add_field('my.funny.title','true')
   end

   # Match when all 650 fields contain digits
   if marc_all_match('650','[0-9]')
     add_field('has_digits','true')
   end

=head1 DESCRIPTION

Evaluate the enclosing fixes only if the MARC (sub)field matches a
regular expression. When the MARC field is a repeated fiels, then all
the MARC fields should match the regular expression.

=head1 METHODS

=head2 marc_all_match(MARC_PATH, REGEX)

Evaluates to true when all MARC_PATH values matches the REGEX, false otherwise.

=head1 SEE ALSO

L<Catmandu::Fix::Condition::marc_any_match>

=cut

1;
