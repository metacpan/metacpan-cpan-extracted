package Acme::Free::Advice 1.0 {
    use v5.38;
    use parent 'Exporter';
    use Module::Load;
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[advice flavors] ] );
    #
    my %flavor = (
        map {
            my $pkg = 'Acme::Free::Advice::' . $_;
            ( eval 'require ' . $pkg ? ( lc($_) => $pkg ) : () ),
        } qw[Slip Unsolicited]
    );

    sub advice ( $flavor //= ( keys %flavor )[ rand keys %flavor ] ) {
        $flavor{$flavor} // return ();
        my $cv = $flavor{$flavor}->can('advice');
        $cv ? $cv->() : ();
    }
    sub flavors () { keys %flavor }
}
1;
__END__

=encoding utf-8

=head1 NAME

Acme::Free::Advice - Wise words. Dumb code.

=head1 SYNOPSIS

    use Acme::Free::Advice qw[advice];
    say advice;

=head1 DESCRIPTION

Acme::Free::Advice spits out advice. Good advice. Bad advice. Advice. It's a forture cookie.

=head1 METHODS

These functions may be imported by name or with the C<:all> tag.

=head2 C<advice( [...] )>

Tear someone down.

    my $wisdom = advice( ); # Random advice
    print advice( ); # stringify
    print advice( 'slip' );

Expected parameters include:

=over

=item C<flavor>

If undefined, a random supported flavor is used.

Currently, supported flavors include:

=over

=item C<slip>

Uses L<Acme::Free::Advice::Slip>

=item C<unsolicited>

Uses L<Acme::Free::Advice::Unsolicited>

=back

=back

=head2 C<flavors( )>

    my @flavors = flavors( );

Returns a list of supported advice flavors.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=head2 ...but why?

I'm inflicting this upon the world because L<oodler577|https://github.com/oodler577/> invited me to help expand Perl's
coverage of smaller open APIs. Blame them or L<join us|https://github.com/oodler577/FreePublicPerlAPIs> in the effort.

=cut

