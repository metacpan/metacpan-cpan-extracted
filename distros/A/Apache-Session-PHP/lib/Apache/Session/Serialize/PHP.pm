package Apache::Session::Serialize::PHP;

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

use PHP::Session::Serializer::PHP;

sub serialize {
    my $session = shift;
    my $serializer = PHP::Session::Serializer::PHP->new;
    $session->{serialized} = $serializer->encode($session->{data});
}

sub unserialize {
    my $session = shift;
    my $serializer = PHP::Session::Serializer::PHP->new;
    $session->{data} = $serializer->decode($session->{serialized});
}

1;
__END__

=head1 NAME

Apache::Session::Serialize::PHP - uses PHP::Session to serialize session

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session::PHP>, L<PHP::Session::Serializer::PHP>

=cut
