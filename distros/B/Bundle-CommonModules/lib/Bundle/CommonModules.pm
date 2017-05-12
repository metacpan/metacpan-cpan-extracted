package Bundle::CommonModules;

use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bundle::CommonModules ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    &printYouAreNotDone
    &printYouAreDone
    ) ] );
    
#our @EXPORT_OK   = qw(printYouAreDone printYouAreNotDone);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1.03';

# Preloaded methods go here.

sub printYouAreNotDone  { print "You Are NOT Done.\n";  }
sub printYouAreDone     { print "You Are Done!\n";      }

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bundle::CommonModules - Perl extension for assisting automatic installation of common Perl modules.

=head1 SYNOPSIS

  use Bundle::CommonModules;
  

=head1 DESCRIPTION

This module does nothing, so doing a 'use' is silly.  This module is intended to be useful as a way
to automatically install a variety of common Perl modules that are not in the core distribution, but
may or may not be useful in the wide world of real-world script writing.

=head2 EXPORT

None by default.

=head1 SEE ALSO

There is a module named Bundle::Everything which includes all CPAN modules.  however, it is 
not useful because it fails the first time you do not have a library that some module requires.

This bundle will require no libraries for installatino and do everything it can to keep going 
after any failure, so at least you get some modules installed.

There is no mailing list for this module.  If you have a suggestion for a module to be included,
send an email or post an enhancement request / bug report for this module in the http://rt.cpan.org site.


=head1 AUTHOR

Kevin Rice, E<lt>kevin@justanyone.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kevin J. Rice, Prairie Grove IL 60014 USA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
