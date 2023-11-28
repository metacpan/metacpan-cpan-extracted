package At::Bluesky {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use DateTime::Tiny;
    use At;

    class At::Bluesky : isa(At) {
        field $identifier : param;
        field $password : param;

        # Required in subclasses of At
        method host { URI->new('https://bsky.social') }
        ADJUST {
            require At::Lexicons::app::bsky::feed::post;
            require At::Lexicons::app::bsky::richtext::facet;
            #
            $self->server->createSession( identifier => $identifier, password => $password );    # auto-login
            $self->_repo( At::Lexicon::AtProto::Repo->new( client => $self, did => $self->http->session->did->raw ) );
        }

        # Sugar
        method post (%args) {
            use Carp qw[confess];
            confess 'text must be fewer than 300 charactersf' if length $args{text} > 300;
            $args{createdAt} //= At::_now();
            $self->repo->createRecord( collection => 'app.bsky.feed.post', record => { '$type' => 'app.bsky.feed.post', %args } );
        }
    }
};
1;
__END__
=encoding utf-8

=head1 NAME

At::Bluesky - Bluesky Sugar for the AT Protocol

=head1 SYNOPSIS

    use At::Bluesky;
    my $at = At::Bluesky->new( identifier => 'sanko', password => '1111-aaaa-zzzz-0000' );
    $at->post( text => 'Hello world! I posted this via the API.' );

=head1 DESCRIPTION

This is a cookbook. Or, it will be, eventually.

=head1 Methods

Bluesky. It's new.

=head2 C<new( ... )>

    At::Bluesky->new( identifier => 'sanko', password => '1111-2222-3333-4444' );

Expected parameters include:

=over

=item C<identifier> - required

Handle or other identifier supported by the server for the authenticating user.

=item C<password> - required

You know this!

=back

=head2 C<post( ... )>

This one is easy.

    use At;
    my $bsky = At::Bluesky->new( identifier => 'sanko', password => '1111-aaaa-zzzz-0000' );
    $bsky->post( text => 'Nice.' );

Expected parameters:

=over

=item C<createdAt> - required

Timestamp in ISO 8601.

=item C<text> - required

Post content. 300 max chars.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

Bluesky

=end stopwords

=cut
