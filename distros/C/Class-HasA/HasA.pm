package Class::HasA;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

sub import {
    my ($self, @args) = @_;
    croak "Wrong number of arguments to import" if @args & 1;

    while (my ($method, $how) = splice(@args, 0,2)) {
        my @methods = $method;
        @methods = @$method if ref $method eq "ARRAY";
        for $method (@methods) {
            no strict 'refs';
            *{caller()."::$method"} = sub { (shift->$how)->$method(@_) };
        }
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::HasA - Automatically create has-a relationships

=head1 SYNOPSIS

  package Some::Mail::Thing;
  use Class::HasA ( [ qw/from to subject/ ] => "head" );
  # Equivalent:
  #  sub from { shift->head->from(@_) }
  #  sub to   { shift->head->to(@_) }
  #  ...

=head1 DESCRIPTION

This module produces methods which encapsulates has-a relationships
between objects. For instance, in the example above, a mail message
has-a C<head> object, and the C<from>, C<to> and C<subject> methods act
"through" the C<head> object.

=head1 AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kasei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
