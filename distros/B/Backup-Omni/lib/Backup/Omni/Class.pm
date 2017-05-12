package Backup::Omni::Class;

use Badger::Class
  uber     => 'Badger::Class',
  constant => {
      UTILS     => 'Backup::Omni::Utils',
      CONSTANTS => 'Backup::Omni::Constants',
  }
;

1;

__END__

=head1 NAME

Backup::Omni::Class - Class defination for Backup::Omni

=head1 SYNOPSIS

 use Backup::Omni::Class
     version => '0.01',
     base    => 'Backup::Omni::Base'
 ;

=head1 DESCRIPTION

This module ties Backup::Omni to the base Badger object framework. It
exposes the defined constants and utilities that reside in Backup::Omni::Constants and
Backup::Omni::Utils. Which inherits from Badger::Constants and Badger::Utils.

=head1 SEE ALSO

 Badger::Base
 Badger::Class
 Badger::Constants
 Badger::Utils

 Backup::Omni::Base
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
