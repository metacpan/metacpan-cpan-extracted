package Backup::Omni::Exception;

use base Badger::Exception;
$Badger::Exception::TRACE = 1;

1;

__END__

=head1 NAME

Backup::Omni::Exception - The exception class for Backup::Omni

=head1 DESCRIPTION

This module defines a base exception class for Backup::Omni and 
inherits from Badger::Exception. The only differences is that it turns
stack tracing on by default.

=head1 SEE ALSO

 Badger::Exception

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
