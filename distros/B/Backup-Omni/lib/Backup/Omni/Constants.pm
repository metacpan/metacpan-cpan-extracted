package Backup::Omni::Constants;

our $VERSION = '0.01';

use Backup::Omni::Exception;

use Badger::Class
  version => $VERSION,
  base    => 'Badger::Constants',    # grab the badger constants
  import  => 'class',
;

# ----------------------------------------------------------------------
# Build our constants and export them
# ----------------------------------------------------------------------

{

    my $path = '/opt/omni/bin/%s';

    if ($^O eq "MSWin32") {

        if ($ENV{PATH} =~ m/;(.*OmniBack\\bin);/) {

            $path = $1 . '\\%s.exe';

        } else {

            $path = '"C:\\Program Files\\OmniBack\\bin\\%s.exe"';

        }

    }

    my $constants = {
        OMNIR     => sprintf($path, 'omnir'),
        OMNIDB    => sprintf($path, 'omnidb'),
        OMNISTAT  => sprintf($path, 'omnistat'),
        OMNIABORT => sprintf($path, 'omniabort'),
    };

    my $exports = {
        any => 'OMNIR OMNIDB OMNISTAT OMNIABORT',
        all => 'OMNIR OMNIDB OMNISTAT OMNIABORT',
    };

    class->constant($constants);
    class->exports($exports);

}

1;

__END__

=head1 NAME

Backup::Omni::Constants - Defined constants for Backup::Omni

=head1 SYNOPSIS

 use Backup::Omni::Class
   version   => '0.01',
   base      => 'Backup::Omni::Base',
   constants => ':all',
 ;

 ... or ...

 use Backup::Omni::Class
   version   => '0.01',
   base      => 'Backup::Omni::Base',
   constants => 'OMNIR',
 ;

 ... or ...

 use Backup::Omni::Constants 'OMNIR';

=head1 DESCRIPTION

This module defines constants used within the system. Each constant can
be exported individually or by using ":all". These constants are primarily
used to export the fully qualified cli commands for HP DataProtector. 

=head1 EXPORT

 OMNIR
 OMNIDB
 OMNISTAT
 OMNIABORT

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
