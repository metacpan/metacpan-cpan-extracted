package AnyEvent::FTP::Request;

use strict;
use warnings;
use 5.010;
use overload '""' => sub { shift->as_string };

# ABSTRACT: Request class for asynchronous ftp server
our $VERSION = '0.16'; # VERSION


sub new
{
  my($class, $cmd, $args, $raw) = @_;
  bless { command => $cmd, args => $args, raw => $raw }, $class;
}


sub command { shift->{command} }


sub args    { shift->{args}    }


sub raw     { shift->{raw}     }


sub as_string
{
  my $self = shift;
  join ' ', $self->command, $self->args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Request - Request class for asynchronous ftp server

=head1 VERSION

version 0.16

=head1 DESCRIPTION

Instances of this class represent client requests.

=head1 ATTRIBUTES

=head2 command

 my $command = $req->command;

The command, usually something like C<USER>, C<PASS>, C<HELP>, etc.

=head2 args

 my $args = $res->args;

The arguments passed in with the command

=head2 raw

 my $raw = $res->raw;

The raw, unparsed request.

=head1 METHODS

=head2 as_string

 my $str = $res->as_string
 my $str = "$res";

Returns a string representation of the request.  This may not be exactly the same as
what was actually sent to the server (see C<raw> attribute for that).  You can also
call this by treating the object like a string (using string operators, or including
it in a double quoted string), so

 print "$req";

is the same as

 print $req->as_string;

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
