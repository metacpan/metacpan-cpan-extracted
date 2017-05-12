package Bundle::libwin32;

$VERSION = '0.31';

1;

__END__

=head1 NAME

Bundle::libwin32 - install all modules that make up the libwin32 bundle

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::libwin32'

=head1 CONTENTS

Win32

Win32::ChangeNotify

Win32::Clipboard

Win32::Console

Win32::Event

Win32::EventLog

Win32::File

Win32::FileSecurity

Win32::IPC

Win32::Internet

Win32::Job

Win32::Mutex

Win32::NetAdmin

Win32::NetResource

Win32::ODBC

Win32::OLE

Win32::PerfLib

Win32::Pipe

Win32::Process

Win32::Registry

Win32::Semaphore

Win32::Service

Win32::Shortcut

Win32::Sound

Win32::TieRegistry

Win32::WinError

Win32API::File

Win32API::Net

Win32API::Registry

=head1 DESCRIPTION

The libwin32 package on CPAN used to contain a set of Win32-specific modules
that provide access to core Windows functionality.  Keeping all the modules
together in a single distribution turned out to be a big maintenance problem
because the releases of the modules were now linked.  This resulted in very
slow release cycle. The modules are now all available on CPAN separately.

The libwin32 package contains only a single pseudo-module Bundle::libwin32
anymore that will pull in all the module originally contained in libwin32.
When you install the Bundle::libwin32, all modules mentioned in L</CONTENTS>
above will be installed instead.

=head1 SEE ALSO

L<CPAN/Bundles>
