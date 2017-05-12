package CGI::Session::Serialize::Base64;

use strict;
use warnings;
use Safe;
use MIME::Base64;
use Data::Dumper;

use vars qw($VERSION);

($VERSION) = '$Revision: 0.1 $' =~ m/Revision:\s*(\S+)/;


sub freeze {
    my ($self, $data) = @_;

    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Purity   = 0;
    local $Data::Dumper::Useqq    = 1;
    local $Data::Dumper::Deepcopy = 0;

    my $d = new Data::Dumper([$data], ["D"]);
    return encode_base64($d->Dump());
}



sub thaw {
    my ($self, $Estring) = @_;

    my $string = decode_base64($Estring);

    # To make -T happy
    my ($safe_string) = $string =~ m/^(.*)$/;

    my $D = undef;
    my $cpt = new Safe();
    $D = $cpt->reval ($safe_string );
    if ( $@ ) {
        die $@;
    }

    return $D;
}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Session::Serialize::Base64 - serializer for CGI::Session

=head1 DESCRIPTION

This library is used by CGI::Session driver to serialize session data before storing it in disk.
It uses base64 encoding to obfuscate the data to deter casual browsers.

=head1 METHODS

=over 4

=item freeze()

receives two arguments. First is the CGI::Session driver object, the second is the data to be
stored passed as a reference to a hash. Should return true to indicate success, undef otherwise,
passing the error message with as much details as possible to $self->error()

=item thaw()

receives two arguments. First being CGI::Session driver object, the second is the string
to be deserialized. Should return deserialized data structure to indicate successs. undef otherwise,
passing the error message with as much details as possible to $self->error().

=back

=head1 WARNING

If you want to be able to store objects, consider using L<CGI::Session::Serialize::Storable> or
L<CGI::Session::Serialize::FreezeThaw> instead.

=head1 COPYRIGHT

Copyright (C) 2004 Matthew Studley. All rights reserved.

This library is free software. It can be distributed under the same terms as Perl itself.

=head1 AUTHOR

Matthew Studley <mjfs@cpan.org>

All bug reports should be directed to Matthew Studley <mjfs@cpan.org>.

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut

