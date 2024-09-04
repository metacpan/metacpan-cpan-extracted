package Acme::Free::Advice::Slip 1.0 {    # https://api.adviceslip.com/
    use v5.38;
    use HTTP::Tiny;
    use JSON::Tiny qw[decode_json];
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[advice search] ] );
    #
    use overload '""' => sub ( $s, $u, $b ) { $s->{advice} // () };
    #
    sub _http ($uri) {
        state $http
            //= HTTP::Tiny->new( default_headers => { Accept => 'application/json' }, agent => sprintf '%s/%.2f ', __PACKAGE__, our $VERSION );
        my $res = $http->get($uri);    # {success} is true even when advice is not found but we'll at least know when we have valid JSON
        $res->{success} ? decode_json( $res->{content} ) : ();
    }
    #
    sub advice ( $slip_id //= () ) {
        my $res = _http( 'https://api.adviceslip.com/advice' . ( $slip_id ? '/' . $slip_id : '' ) );
        defined $res->{slip} ? bless $res->{slip}, __PACKAGE__ : ();
    }

    sub search ($query) {
        my $res = _http( 'https://api.adviceslip.com/advice/search/' . $query );
        map { bless $_, __PACKAGE__ } @{ $res->{slips} // [] };
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Acme::Free::Advice::Slip - Seek Advice from the Advice Slip API

=head1 SYNOPSIS

    use Acme::Free::Advice::Slip qw[advice];
    say advice( 224 )->{advice};

=head1 DESCRIPTION

Acme::Free::Advice::Slip provides wisdom from L<AdviceSlip.com|https://adviceslip.com/>.

=head1 METHODS

These functions may be imported by name or with the C<:all> tag.

=head2 C<advice( [...] )>

    my $widsom = advice( ); # Random advice
    my $advice = advice( 20 ); # Advice by ID

Seek advice.

You may request specific advice by ID.

Advice is provided as a hash reference containing the following keys:

=over

=item C<advice>

The sage advice you were looking for.

=item C<id>

The advice's ID in case you'd like to request it again in the future.

=back

=head2 C<search( ... )>

    my @slips = search( 'time' );

Seek topical advice.

Advice is provided as a list of hash references containing the following keys:

=over

=item C<advice>

The sage advice you were looking for.

=item C<date>

The date the wisdom was added to the database. It's in YYYY-MM-DD.

I'm not sure why this isn't also returned when requesting advice by ID but that's how the backend works.

=item C<id>

The advice's ID in case you'd like to request it again in the future.

=back

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

L<AdviceSlip.com|https://adviceslip.com/> is brought to you by L<Tom Kiss|https://tomkiss.net/>.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=head2 ...but why?

I'm inflicting this upon the world because L<oodler577|https://github.com/oodler577/> invited me to help expand Perl's
coverage of smaller open APIs. Blame them or L<join us|https://github.com/oodler577/FreePublicPerlAPIs> in the effort.

=cut
