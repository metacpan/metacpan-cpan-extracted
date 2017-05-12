package YADA::Worker;
# ABSTRACT: "Yet Another Download Accelerator Worker": alias for AnyEvent::Net::Curl::Queued::Easy


use strict;
use utf8;
use warnings qw(all);

use Moo;
extends 'AnyEvent::Net::Curl::Queued::Easy';

our $VERSION = '0.047'; # VERSION

has '+opts' => (default => sub { { encoding => '', maxredirs => 5 } });

## no critic (ProtectPrivateSubs)
after init  => sub { shift->setopt(followlocation => 1) };
after finish => sub { shift->queue->_shift_worker };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

YADA::Worker - "Yet Another Download Accelerator Worker": alias for AnyEvent::Net::Curl::Queued::Easy

=head1 VERSION

version 0.047

=head1 WARNING: GONE MOO!

This module isn't using L<Any::Moose> anymore due to the announced deprecation status of that module.
The switch to the L<Moo> is known to break modules that do C<extend 'AnyEvent::Net::Curl::Queued::Easy'> / C<extend 'YADA::Worker'>!
To keep the compatibility, make sure that you are using L<MooseX::NonMoose>:

    package YourSubclassingModule;
    use Moose;
    use MooseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or L<MouseX::NonMoose>:

    package YourSubclassingModule;
    use Mouse;
    use MouseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or the L<Any::Moose> equivalent:

    package YourSubclassingModule;
    use Any::Moose;
    use Any::Moose qw(X::NonMoose);
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

However, the recommended approach is to switch your subclassing module to L<Moo> altogether (you can use L<MooX::late> to smoothen the transition):

    package YourSubclassingModule;
    use Moo;
    use MooX::late;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

=head1 DESCRIPTION

Exactly the same thing as L<AnyEvent::Net::Curl::Queued::Easy>, however, with a more Perl-ish and shorter name.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::Net::Curl::Queued>

=item *

L<AnyEvent::Net::Curl::Queued::Easy>

=item *

L<YADA>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
