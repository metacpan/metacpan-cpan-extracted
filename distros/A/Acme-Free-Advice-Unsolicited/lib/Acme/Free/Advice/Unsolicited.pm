package Acme::Free::Advice::Unsolicited 1.0 {    # https://kk-advice.koyeb.app/api
    use v5.38;
    use HTTP::Tiny;
    use JSON::Tiny qw[decode_json];
    use parent 'Exporter';
    our %EXPORT_TAGS = ( all => [ our @EXPORT_OK = qw[advice all] ] );
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
    sub advice ( $advice_id //= () ) {
        my $res = _http( 'https://kk-advice.koyeb.app/api/advice' . ( $advice_id ? '/' . $advice_id : '' ) );
        defined $res->{error} ? () : bless $res, __PACKAGE__;
    }

    sub all () {
        my $res = _http('https://kk-advice.koyeb.app/api/advice/all');
        map { bless $_, __PACKAGE__ } @{ $res // [] };
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Acme::Free::Advice::Unsolicited - Solicit Unsolicited Advice from the Unsolicited Advice API

=head1 SYNOPSIS

    use Acme::Free::Advice::Unsolicited qw[advice];
    say advice( 224 )->{advice};

=head1 DESCRIPTION

Acme::Free::Advice::Unsolicited provides wisdom from author and leading tech observer, L<Kevin
Kelly|https://en.wikipedia.org/wiki/Kevin_Kelly_(editor)>.

=head1 METHODS

These functions may be imported by name or with the C<:all> tag.

=head2 C<advice( [...] )>

Seek wisdom.

    my $advice = advice( ); # Random advice
    my $wisdom = advice( 20 ); # Advice by ID

You may request specific advice by ID.

Advice is provided as a hash reference containing the following keys:

=over

=item C<advice>

The sage advice you were looking for.

=item C<id>

The advice's ID in case you'd like to request it again in the future.

=item C<source>

The source of the wisdom. Typically a URL on Kevin's block.

=back

=head2 C<all( )>

    my @advice = all(  );

Seek all advice.

Advice is provided as a list of hash references containing the following keys:

=over

=item C<advice>

The sage advice you were looking for.

=item C<id>

The advice's ID in case you'd like to request it again in the future.

=item C<source>

The source of the wisdom. Typically a URL on Kevin's blog.

=back

=head1 LICENSE & LEGAL

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

Unsolicited advice provided by L<Kevin Kelly|https://kk.org/>.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=head2 ...but why?

I'm inflicting this upon the world because L<oodler577|https://github.com/oodler577/> invited me to help expand Perl's
coverage of smaller open APIs. Blame them or L<join us|https://github.com/oodler577/FreePublicPerlAPIs> in the effort.

=cut
