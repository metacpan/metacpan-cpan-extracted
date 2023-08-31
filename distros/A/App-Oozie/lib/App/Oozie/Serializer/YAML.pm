package App::Oozie::Serializer::YAML;
$App::Oozie::Serializer::YAML::VERSION = '0.002';
use 5.010;
use strict;
use warnings;
use YAML::XS ();
use Moo;

sub encode {
    my $self = shift;
    my $data = shift;
    YAML::XS::Dump( $data );
}

sub decode {
    my $self = shift;
    my $data = shift;
    YAML::XS::Load( $data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Serializer::YAML

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use App::Oozie::Serializer;
    my $s = App::Oozie::Serializer->new(
        # ...
        format => 'yaml',
    );
    my $d = $s->decode( $input );

=head1 DESCRIPTION

YAML encoder/decoder.

=head1 NAME

App::Oozie::Serializer::YAML - YAML encoder/decoder.

=head1 Methods

=head2 encode

=head2 decode

=head1 SEE ALSO

L<App::Oozie>. L<App::Oozie::Serializer>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
