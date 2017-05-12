package CGI::Untaint::telephone;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.03';

use base 'CGI::Untaint::object';

# a rather basic regex for phone numbers here..
# it should really try and guarantee that if there ARE dots and dashes,
# that they can't occur next to each other..
sub _untaint_re {
    return qr/^\+?\d[-\.\d ]{1,24}$/;
}

sub is_valid {
    my $self = shift;
    my $value = $self->value;
    $value =~ s/[-\.\s]//g;
    return $self->value($value);
}   

1;
__END__

=head1 NAME

CGI::Untaint::telephone

=head1 SYNOPSIS

  # use with CGI::Untaint
  my $untainter = CGI::Untaint->new( $q->Vars );
  $untainter->extract(-as_telephone => 'mobile');

=head1 DESCRIPTION

A plugin for CGI::Untaint, this attempts to validate input as looking vaguely
like a telephone number.

Numbers may optionally start with a +, and may contain dots and dashes, which
will be stripped out.

TODO: Ensure that dots and dashes aren't allowed next to each other, and nor
should they be the only content in the number.

=head1 SEE ALSO

CGI::Untaint

=head1 AUTHOR

Toby Corkindale, E<lt>cpan@corkindale.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2006 by Toby Corkindale

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
