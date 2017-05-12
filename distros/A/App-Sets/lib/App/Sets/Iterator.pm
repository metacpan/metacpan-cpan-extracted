package App::Sets::Iterator;
$App::Sets::Iterator::VERSION = '0.976';


use strict;
use warnings;

# ABSTRACT: convenience iterator

sub new {
   my ($package, $it) = @_;
   return bless {it => $it}, $package;
}

sub head {
   my ($self) = @_;
   return exists $self->{head} ? $self->{head} : $self->next();
}

sub next {
   my ($self) = @_;
   return $self->{head} = $self->{it}->();
}

sub drop {
   my ($self) = @_;
   my $retval = $self->head();
   $self->next();
   return $retval;
} ## end sub drop

1;

__END__

=pod

=head1 NAME

App::Sets::Iterator - convenience iterator

=head1 VERSION

version 0.976

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
