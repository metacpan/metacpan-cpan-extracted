package CatalystX::ASP::Exception::End;

use Moose;
use namespace::clean -except => 'meta';

with 'Catalyst::Exception::Basic';

=head1 NAME

CatalystX::ASP::Exception::End - Exception to end ASP processing

=head1 DESCRIPTION

This is the class for the Catalyst Exception which is thrown then you call
C<< $Response->End() >>.

This class is not intended to be used directly by users.

=cut

has '+message' => (
    default => "asp_end\n",
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SEE ALSO

=over

=item * L<Catalyst>

=item * L<Catalyst::Exception>

=back
