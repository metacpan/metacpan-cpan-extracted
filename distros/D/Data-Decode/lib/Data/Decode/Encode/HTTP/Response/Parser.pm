# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode/Encode/HTTP/Response/Parser.pm 8610 2007-11-06T07:46:36.901340Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Encode::HTTP::Response::Parser;
use strict;
use warnings;
use base qw(HTML::Parser);

sub new
{
    my $class = shift;
    $class->SUPER::new(
        api_version => 3,
        start_h     => [ \&_parse_meta, "self, tagname, attr" ]
    );
}

sub extract_encodings
{
    my $self = shift;

    my @encodings;
    $self->utf8_mode(1);
    $self->{encodings} = \@encodings;
    $self->parse($_[0]);
    $self->eof;
    delete $self->{encodings};
    return wantarray ? @encodings : \@encodings;
}

sub _parse_meta
{
    my ($self, $tag, $attrs) = @_;
    return unless $tag eq 'meta';
    return unless $attrs->{'http-equiv'} && 
        lc($attrs->{'http-equiv'}) eq 'content-type';

    my $content = $attrs->{content};
    if (defined $content && $content =~ /charset=([A-Za-z0-9_\-]+)/i) {
        push @{ $self->{encodings} }, $1;
    }
}

1;

__END__

=head1 NAME

Data::Decode::Encode::HTTP::Response::Parser - HTML Parser To Detect Charset Embedded In META Tags

=head1 METHODS

=head2 new

=head2 extract_encodings

=cut