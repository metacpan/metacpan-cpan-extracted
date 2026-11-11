use v5.36;

package DBIx::Squirrel::Pipeline;

use Ekorn::Pipeline qw();

# A facade over Ekorn::Pipeline, inheriting its methods, and where
# DBIx::Squirrel can change how its pipelines behave without changing
# Ekorn::Pipeline.
our @ISA = ('Ekorn::Pipeline');

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Pipeline - run values through a list of stages

=head1 SYNOPSIS

    use DBIx::Squirrel::Pipeline;

    my $p = DBIx::Squirrel::Pipeline->new(
        sub { $_->{active} ? $_ : () },          # filter
        sub ($row) { @{ $row->{tags} } },        # flatMap
        sub { uc },                              # map
    );

    # Push: values in, a list out
    my @tags = $p->(@rows);

    # Pull: one value per call, from a source
    my $next = $p->iterator(sub { $sth->fetchrow_hashref // () });
    while (my($tag) = $next->()) { ... }

=head1 DESCRIPTION

DBIx::Squirrel's pipeline. Its iterators, result sets, Sugar
statements, and handles' C<pipe> and C<tap> run their stages with it.
It's a subclass of L<Ekorn::Pipeline>, which describes it in full. It
inherits its methods, C<new>, C<iterator> and C<stages>. A pipeline
can be called as a code reference with values, as an Ekorn::Pipeline
can.

A function of your own can take stages from its caller, and run what it
returns through them:

    sub bands (@stages) {
        return DBIx::Squirrel::Pipeline->new(@stages)->(load_bands());
    }

A pipeline can go wherever a stage goes, with more stages before or
after it. Its stages run in its place, as if written out there:

    my $hits = DBIx::Squirrel::Pipeline->new(sub { $_->[1] >= 5000 ? $_ : () }, pluck('name'));
    my @top  = $dbh->iterate($sql, $hits, take(10))->all;

C<stages> returns a pipeline's stages, in order, for a function that
takes only code references.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<DBIx::Squirrel>, L<DBIx::Squirrel::Gather>,
L<DBIx::Squirrel::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
