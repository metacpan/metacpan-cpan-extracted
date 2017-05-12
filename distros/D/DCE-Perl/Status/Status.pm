package DCE::Status;
require Exporter;
require DynaLoader;
require Tie::Scalar;

use vars qw($VERSION @ISA @EXPORT_OK);

@ISA = qw(Tie::StdScalar Exporter DynaLoader);
@EXPORT_OK = qw(&error_string);
@EXPORT = qw(&error_inq_text);

$VERSION = '1.00';

bootstrap DCE::Status $VERSION;

1;

__END__

=head1 NAME 

DCE::Status - Make sense of DCE status codes

=head1 SYNOPSIS

    use DCE::Status;
    
    $errstr = error_inq_text($status);

    tie $status => DCE::Status;

=head1 DESCRIPTION

When a $scalar is tie'd to the DCE::Status class, it has a different
value depending on the context it is evaluated in, similar to the magic
C<$!> variable.  When evaluated in a numeric context, the numeric value
is returns, otherwise, the string value obtained from I<dce_error_inq_text>
is returned.

=head1 EXPORTS

=over 4

=item error_inq_text

Equivalent to the dce_error_inq_text function.

 $errstr = error_inq_text($status);

=back

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

=head1 SEE ALSO

perl(1), DCE::Registry(3), DCE::Login(3), DCE::ACL(3).

=cut


