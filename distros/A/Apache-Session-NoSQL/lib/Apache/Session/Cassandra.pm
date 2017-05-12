package Apache::Session::Cassandra;

use strict;
use base qw(Apache::Session::NoSQL);

our $VERSION = '0.01';

sub populate {
    my $self = shift;
    $self->{args}->{Driver} = 'Cassandra';
    return $self->SUPER::populate(@_);
}

1;
__END__

=pod

=head1 NAME

Apache::Session::Cassandra - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::Cassandra;
 
 tie %hash, 'Apache::Session::Cassandra', $id, {
 };

=head1 DESCRIPTION

This module is an implementation of Apache::Session::NoSQL. It uses the Cassandra
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
