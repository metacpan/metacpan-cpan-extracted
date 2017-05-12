# -*- Mode: Perl -*- 

package Bundle::DBD::Yaswi;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::DBD::Yaswi - A bundle to install all DBD::Yaswi related modules

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::DBD::Yaswi'

=head1 CONTENTS

Bundle::DBI  - Bundle for DBI by TIMB (Tim Bunce)

Language::Prolog::Types - Prolog Types
Language::Prolog::Yaswi - SWI-Prolog interface
DBD::Yaswi  - DBD::Driver, all by SALVA (Salvador FandiE<ntilde>o)

=head1 DESCRIPTION

This bundle includes all the modules used by the Perl Database
Interface (DBI) driver for Driver (DBD::Yaswi), assuming the use of
DBI version 1.13 or later, created by Tim Bunce.

If you've not previously used the CPAN module to install any bundles,
you will be interrogated during its setup phase.  But when you've done
it once, it remembers what you told it.  You could start by running:

  perl -MCPAN -e 'install Bundle::CPAN'

 
=head1 SEE ALSO

Bundle::DBI

=head1 AUTHOR

Salvador FandiE<ntilde>o E<lt>F<sfandino@yahoo.com>E<gt>

=cut
