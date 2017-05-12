package DCE::UUID;

use vars qw($VERSION @ISA @EXPORT);
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
   &uuid_create &uuid_hash
);

use overload '""' => sub { shift->as_string; };

$VERSION = '1.01';

bootstrap DCE::UUID;

1;
__END__

=head1 NAME

DCE::UUID - Misc UUID functions

=head1 SYNOPSIS

  use DCE::UUID;

=head1 DESCRIPTION

DCE::UUID exports the following functions:

=item uuid_create()

    my($uuid, $status) = uuid_create();

=item uuid_hash()

    my($hash, $status) = uuid_hash($uuid);

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

=head1 SEE ALSO

perl(1), DCE::Status(3), DCE::Registry(3), DCE::Login(3).

=cut
