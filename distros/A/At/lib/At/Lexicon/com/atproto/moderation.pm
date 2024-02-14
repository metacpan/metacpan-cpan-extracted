package At::Lexicon::com::atproto::moderation 0.17 {

    #~ https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/moderation/defs.json
    use v5.38;
    use lib '../../../../../lib';
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::try';    # Be quiet.
    use feature 'class', 'try';
    #
    class At::Lexicon::com::atproto::moderation::reasonType 1 {
        field $type : param($type);
        ADJUST {
            use Carp;
            Carp::confess 'unknown reason'
                unless $type eq 'com.atproto.moderation.defs#reasonSpam' ||
                $type eq 'com.atproto.moderation.defs#reasonViolation'   ||
                $type eq 'com.atproto.moderation.defs#reasonMisleading'  ||
                $type eq 'com.atproto.moderation.defs#reasonSexual'      ||
                $type eq 'com.atproto.moderation.defs#reasonRude'        ||
                $type eq 'com.atproto.moderation.defs#reasonOther'       ||
                $type eq 'com.atproto.moderation.defs#reasonAppeal'
        }

        method _raw() {
            +{ '$type' => $type };
        }
    };
}
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::moderation - Core Moderation Classes

=head1 At::Lexicon::com::atproto::moderation::reasonType

A class with the following known C<$type>s:

=over

=item C<com.atproto.moderation.defs#reasonSpam>

Spam: frequent unwanted promotion, replies, mentions

=item C<com.atproto.moderation.defs#reasonViolation>

Direct violation of server rules, laws, terms of service

=item C<com.atproto.moderation.defs#reasonMisleading>

Misleading identity, affiliation, or content

=item C<com.atproto.moderation.defs#reasonSexual>

Unwanted or mislabeled sexual content

=item C<com.atproto.moderation.defs#reasonRude>

Rude, harassing, explicit, or otherwise unwelcoming behavior

=item C<com.atproto.moderation.defs#reasonOther>

Other: reports not falling under another report category

=back

=head1 See Also

L<https://atproto.com/>

L<https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/admin/defs.json>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=begin stopwords

unwelcoming

=end stopwords

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
