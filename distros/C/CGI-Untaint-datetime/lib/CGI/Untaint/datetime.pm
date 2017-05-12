package CGI::Untaint::datetime;

use strict;
use base 'CGI::Untaint::printable';
use Time::Piece;

use vars qw/$VERSION/;
$VERSION = '0.06';

sub is_valid {
    my $self=shift;
    my $date;
    my $val=$self->value;
    $val.=":00" if length($val) ==16; 
    substr($val,10,1,"T") if length($val) ==19;
    eval {
    $date=Time::Piece->strptime($val,"%FT%H:%M:%S")
	or return;
    } or return;
    $self->value($date);
    return $date;
}

=head1 NAME

CGI::Untaint::datetime - validate a date

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $date = $handler->extract(-as_datetime => 'timestamp');

=head1 DESCRIPTION

This Input Handler verifies that the input is a valid datetime, as
specified by ISO 8601, that is, something resembling YYYY-MM-DDTHH:MM:SS
it can even handle YYYY-MM-DD HH::MM::SS or YYYY-MM-D HH::MM

=head1 METHODS

=over 4 

=item is_valid

The actual validation check. See CGI::Untaint for more information.

=back

=head1 SEE ALSO

L<Time::Piece>. L<CGI::Untaint>

=head1 AUTHOR

Marcus Ramberg <marcus@thefeed.no>

=head1 COPYRIGHT

Copyright (C) 2004 Marcus Ramberg. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
