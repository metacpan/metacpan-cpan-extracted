package Acme::Insult 1.0 {
    use v5.38;
    use parent 'Exporter';
    use Module::Load;
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[insult flavors] ] );
    #
    my %flavor = (
        map {
            my $pkg = 'Acme::Insult::' . $_;
            ( eval 'require ' . $pkg ? ( lc($_) => $pkg ) : () ),
        } qw[Glax Evil Pirate]
    );

    sub insult ( $flavor //= ( keys %flavor )[ rand keys %flavor ] ) {
        $flavor{$flavor} // return ();
        my $cv = $flavor{$flavor}->can('insult');
        $cv ? $cv->() : ();
    }
    sub flavors () { keys %flavor }
}
1;
__END__

=encoding utf-8

=head1 NAME

Acme::Insult - Code That Wasn't Raised Right

=head1 SYNOPSIS

    use Acme::Insult qw[insult];
    say insult;

=head1 DESCRIPTION

Acme::Insult is kind of a jerk.

=head1 METHODS

These functions may be imported by name or with the C<:all> tag.

=head2 C<insult( [...] )>

Tear someone down.

    my $shade = insult( ); # Random insult
    print insult( ); # stringify
    print insult( 'evil' );

Expected parameters include:

=over

=item C<flavor>

If undefined, a random supported flavor is used.

Currently, supported flavors include:

=over

=item C<evil>

Uses L<Acme::Insult::Evil>

=item C<glax>

Uses L<Acme::Insult::Glax>

=back

=back

=head2 C<flavors( )>

    my @flavors = flavors( );

Returns a list of supported insult flavors.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=head2 ...but why?

I'm inflicting this upon the world because L<oodler577|https://github.com/oodler577/> invited me to help expand Perl's
coverage of smaller open APIs. Blame them or L<join us|https://github.com/oodler577/FreePublicPerlAPIs> in the effort.

=cut

