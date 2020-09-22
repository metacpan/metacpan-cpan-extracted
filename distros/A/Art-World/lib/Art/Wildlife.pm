package Art::Wildlife {

    use Zydeco;

    include Behavior::Buyer;
    include Agent;

}

1;

#use Art::Behavior::Crudable;
# does Art::Behavior::Crudable;
# has relations

=encoding UTF-8

=head1 NAME

Agent - Activist of the Art World

=head1 SYNOPSIS

  use Art::Wildlife;

  my $agent = Art::Wildlife->new_agent( name => $f->person_name );

  $agent->participate;    # ==>  "That's interesting"

=head1 DESCRIPTION

A generic entity that can be any activist of the L<Art::World>. Provides all
kind of C<Agents> classes and roles.

=head1 ENTITIES DESCRIPTIONS

=head2 ROLES

=head3 C<Active>

Provide a C<participate> method.

=head3 C<Buyer>

Provide a C<aquire> method requiring some C<money>.

=head2 CLASSES

=head3 C<Artist>

The artist got a lot sof wonderful powers:

=over

=item C<create>

=item C<have_idea> all day long

In the beginning of their carreer they are usually underground, but this can
change in time.

  $artist->is_underground if not $artist->has_collectors;

=back



=head1 AUTHORS

=over

=item Seb. Hu-Rillettes <shr@balik.network>

=item Sébastien Feugère <sebastien@feugere.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2017-2020 Seb. Hu-Rillettes and contributors

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=cut
