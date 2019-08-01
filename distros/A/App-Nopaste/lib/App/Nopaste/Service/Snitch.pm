use strict;
use warnings;
package App::Nopaste::Service::Snitch;
# ABSTRACT: Service provider for Snitch - http://nopaste.snit.ch/

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';

sub available {
    my $self = shift;
    my %args = @_;
    return !(exists($args{private}) && $args{private});
}

sub uri { "http://nopaste.snit.ch" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::Snitch - Service provider for Snitch - http://nopaste.snit.ch/

=head1 VERSION

version 1.013

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, <sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
