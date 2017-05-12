package Backup::Omni;

use 5.8.8;
our $VERSION = '0.02';

1;

__END__

=head1 NAME

Backup::Omni - A set of modules to interact with HP DataProtector

=head1 DESCRIPTION

This is a set of modules to help automate some tasks with HP's DataProtector
(OmniBack) product. With these modules it is possible to restore items from 
the Filesystem object, monitor sessions, retrieve session results and messages
from the command line. 

There is nothing special about these modules. They are basically wrappers 
around the cli commands that are provided with DataProtector. Sensiable 
defaults have been choosen from the sometimes bewildering array of options 
that those cli commands have. 

So to make these modules useful you need to install those cli commands. 

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
