package Apache::Session::Redis;

use strict;
use base qw(Apache::Session::NoSQL);

our $VERSION = '0.1';

sub populate {
    my $self = shift;
    $self->{args}->{Driver} = 'Redis';
    return $self->SUPER::populate(@_);
}

1;
__END__

=pod

=head1 NAME

Apache::Session::Redis - An implementation of Apache::Session

Note: this module is deprecated, Prefer L<Apache::Session::Browseable>

=head1 SYNOPSIS

 use Apache::Session::Redis;
 
 tie %hash, 'Apache::Session::Redis', $id, {
    # optional: default to localhost
    server => '127.0.0.1:6379',
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session::NoSQL. It uses the Redis
storage system

=head1 AUTHOR

This module was written by Xavier Guimard E<lt>x.guimard@free.frE<gt>

=head1 SEE ALSO

L<Apache::Session::NoSQL>, L<Apache::Session>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Thomas Chemineau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
