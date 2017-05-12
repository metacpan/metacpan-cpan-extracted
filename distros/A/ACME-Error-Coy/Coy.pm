package ACME::Error::Coy;

use strict;
no  strict 'refs';

use vars q[$VERSION];
$VERSION = '0.01';

use Coy;

*die_handler  = $SIG{__DIE__};
*warn_handler = $SIG{__WARN__};


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

ACME::Error::Coy - Perl extension for blah blah blah

=head1 SYNOPSIS

  use ACME::Error Coy;

=head1 DESCRIPTION

Interface to L<Coy> for printing your errors.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1), L<Coy>.

=cut
