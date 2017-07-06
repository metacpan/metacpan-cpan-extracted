package Catmandu::Fix::Condition::mab_match;

our $VERSION = '0.15';

use Catmandu::Sane;
use Catmandu::Fix::mab_map;
use Catmandu::Fix::Condition::all_match;
use Catmandu::Fix::set_field;
use Catmandu::Fix::remove_field;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Condition';

has mab_path => ( fix_arg => 1 );
has value    => ( fix_arg => 1 );

sub emit {
    my ( $self, $fixer, $label ) = @_;

    my $perl;

    my $tmp_var = '_tmp_' . int( rand(9999) );
    my $mab_map
        = Catmandu::Fix::mab_map->new( $self->mab_path, "$tmp_var.\$append" );
    $perl .= $mab_map->emit( $fixer, $label );

    my $all_match = Catmandu::Fix::Condition::all_match->new( "$tmp_var.*",
        $self->value );
    my $remove_field = Catmandu::Fix::remove_field->new($tmp_var);

    my $pass_fixes = $self->pass_fixes;
    my $fail_fixes = $self->fail_fixes;

    $all_match->pass_fixes( [ $remove_field, @$pass_fixes ] );
    $all_match->fail_fixes( [ $remove_field, @$fail_fixes ] );

    $perl .= $all_match->emit( $fixer, $label );

    $perl;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Fix::Condition::mab_match - Conditionals on MAB2 fields

=head1 SYNOPSIS

    # mab_match(PICA_PATH,REGEX)

    if mab_match('245','My funny title')
    add_field('my.funny.title','true')
    end

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> 
for a complete overview of the Fix language.

=head1 NAME

Catmandu::Fix::Condition::mab_match - Conditionals on PICA fields

=head1 SEE ALSO

L<Catmandu::Fix>

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
