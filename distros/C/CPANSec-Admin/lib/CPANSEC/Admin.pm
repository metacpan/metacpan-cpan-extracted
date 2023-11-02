use v5.38;
use feature qw( class );
no warnings qw( experimental::class );

use ENV::Util -load_dotenv;
use Pod::Usage;
use CPANSEC::Admin::Command;

class CPANSEC::Admin 0.001 {
    method run (@args) {
        my $dispatcher = CPANSEC::Admin::Command->new( config => {ENV::Util::prefix2hash('CPANSEC_')} );
        $dispatcher->load($_) for qw(Help CVEScan Triage Publish); # Show New);
        $dispatcher->run(@args) or $dispatcher->run('help');
    }
}
__END__

=head1 NAME

CPANSEC::Admin - CPAN Advisory DB Admin Utility

=head1 DESCRIPTION

The L<cpansec-admin> CLI app is an administrative utility for maintaining
the CPAN Advisory Database.

Unless you are a CPANSEC maintainer, you don't need to install or use
this distribution at all.

=head1 LICENSE AND COPYRIGHT

Copyright (C) CPAN Security Working Group.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
