use strict;
use warnings;
package App::Nopaste::Service::WerePaste;
{
  $App::Nopaste::Service::WerePaste::VERSION = '0.02';
}
use Encode qw/decode_utf8/;

use base q/App::Nopaste::Service/;

# ABSTRACT: nopaste service for L<WerePaste>

sub uri { $ENV{WEREPASTE_URL} || 'http://paste.were.space/' }

sub get {
    my ($self, $mech) = @_;

    # Set BasicAuth credentials if needed
    $mech->credentials( $self->_credentials ) if $self->_credentials;

    return $mech->get($self->uri);
}

sub fill_form {
    my ($self, $mech) = (shift, shift);
    my %args = @_;

    my $content = {
        code    => decode_utf8($args{text}),
        title   => decode_utf8($args{desc}),
        lang    => decode_utf8($args{lang}),
    };
    my $exp = $ENV{WEREPASTE_EXP};
    $content->{expiration} = $exp if $exp;
    $mech->credentials( $self->_credentials ) if $self->_credentials;
    @{$mech->requests_redirectable} = ();

    return $mech->submit_form( form_number => 1, fields => $content );
}

sub return {
    my ( $self, $mech ) = @_;
		return (1, $mech->response->header('Location')) if $mech->response->is_redirect;
		return (0, 'Cannot find URL');
}

sub _credentials { ($ENV{WEREPASTE_USER}, $ENV{WEREPASTE_PASS}) }

1;
__END__
=pod

=head1 NAME

App::Nopaste::Service::WerePaste - nopaste service for L<WerePaste>

=head1 VERSION

version 0.02

=head1 SYNOPSIS

L<WerePaste|https://github.com/Maffsie/WerePaste> Service for L<nopaste>.

To use, simple use:

    $ echo "text" | nopaste -s WerePaste

By default it pastes to L<http://paste.were.space>, but you can
override this be setting the C<WEREPASTE_URL> environment variable.

You can set HTTP Basic Auth credentials to use for the nopaste service
if necessary by using:

    WEREPASTE_USER=username
    WEREPASTE_PASS=password

The expiration of the post can be modified by setting the C<WEREPASTE_EXP>
environment variable.  Acceptable values are things like:

    WEREPASTE_EXP=weeks:1
    WEREPASTE_EXP=years:1:months:2
    WEREPASTE_EXP=weeks:1:days:2:hours:12:minutes:10:seconds:5
    WEREPASTE_EXP=never:1  # Never Expire

=head1 AUTHOR

Matthew Connelly <maff@cpan.org>
based on work by
William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE

The MIT License (MIT)

Copyright (c) 2015 Matthew Connelly

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

This work was originally based on works by William Wolf.
The license for the original work (CC0) is as follows:


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

