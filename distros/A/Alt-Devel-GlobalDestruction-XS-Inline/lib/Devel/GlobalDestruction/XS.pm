use strict; use warnings;
package Devel::GlobalDestruction::XS;

# our $VERSION = '0.01';
use Alt::Devel::GlobalDestruction::XS::Inline;

use Devel::GlobalDestruction::XS::Inline
    C => 'lib/Devel/GlobalDestruction/XS.c';

1;  # keep require happy

__END__

=head1 NAME

Devel::GlobalDestruction::XS - Faster implementation of the Devel::GlobalDestruction API

=head1 SYNOPSIS

    use Devel::GlobalDestruction;

=head1 DESCRIPTION

This is an XS backend for L<Devel::GlobalDestruction> and should be used through that module.

=head1 AUTHORS

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

Jesse Luehrs E<lt>doy@tozt.netE<gt>

Peter Rabbitson E<lt>ribasushi@cpan.orgE<gt>

Arthur Axel 'fREW' Schmidt E<lt>frioux@gmail.comE<gt>

Elizabeth Mattijsen E<lt>liz@dijkmat.nlE<gt>

Graham Knop E<lt>haarg@haarg.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 - 2013 the Devel::GlobalDestruction::XS L</AUTHORS> as listed
above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
