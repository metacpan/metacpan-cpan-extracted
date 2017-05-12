#!perl
# -*- perl -*-
#
# DO NOT EDIT, created automatically by C:/PROJECTS/lib/BUILD/mkprereqinst.pl

# on Thu Jan 13 02:31:00 2005
#

use Getopt::Long;
my $require_errors;
my $use = 'cpan';

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
	       )) {
    die "usage: $0 [-ppm | -cpan]\n";
}

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install Devel-Size'.qq(\n); PPM::InstallPackage(package => 'Devel-Size') or warn ' (not successful)'.qq(\n); } if !eval 'require Devel::Size; Devel::Size->VERSION(0.58)';
    do { print STDERR 'Install Time-HiRes'.qq(\n); PPM::InstallPackage(package => 'Time-HiRes') or warn ' (not successful)'.qq(\n); } if !eval 'require Time::HiRes; Time::HiRes->VERSION(1.59)';
    do { print STDERR 'Install Win32-OLE'.qq(\n); PPM::InstallPackage(package => 'Win32-OLE') or warn ' (not successful)'.qq(\n); } if !eval 'require Win32::OLE; Win32::OLE->VERSION(0.1403)';
    do { print STDERR 'Install XML-Quote'.qq(\n); PPM::InstallPackage(package => 'XML-Quote') or warn ' (not successful)'.qq(\n); } if !eval 'require XML::Quote; XML::Quote->VERSION(1.02)';
    do { print STDERR 'Install Devel-Peek'.qq(\n); PPM::InstallPackage(package => 'Devel-Peek') or warn ' (not successful)'.qq(\n); } if !eval 'require Devel::Peek; Devel::Peek->VERSION(1.01)';
    do { print STDERR 'Install Win32-Process-Info'.qq(\n); PPM::InstallPackage(package => 'Win32-Process-Info') or warn ' (not successful)'.qq(\n); } if !eval 'require Win32::Process::Info; Win32::Process::Info->VERSION(1.002)';
} else {
    use CPAN;
    install 'Devel::Size' if !eval 'require Devel::Size; Devel::Size->VERSION(0.58)';
    install 'Time::HiRes' if !eval 'require Time::HiRes; Time::HiRes->VERSION(1.59)';
    install 'Win32::OLE' if !eval 'require Win32::OLE; Win32::OLE->VERSION(0.1403)';
    install 'XML::Quote' if !eval 'require XML::Quote; XML::Quote->VERSION(1.02)';
    install 'Devel::Peek' if !eval 'require Devel::Peek; Devel::Peek->VERSION(1.01)';
    install 'Win32::Process::Info' if !eval 'require Win32::Process::Info; Win32::Process::Info->VERSION(1.002)';
}
if (!eval 'require Devel::Size; Devel::Size->VERSION(0.58);') { warn $@; $require_errors++ }
if (!eval 'require Time::HiRes; Time::HiRes->VERSION(1.59);') { warn $@; $require_errors++ }
if (!eval 'require Win32::OLE; Win32::OLE->VERSION(0.1403);') { warn $@; $require_errors++ }
if (!eval 'require XML::Quote; XML::Quote->VERSION(1.02);') { warn $@; $require_errors++ }
if (!eval 'require Devel::Peek; Devel::Peek->VERSION(1.01);') { warn $@; $require_errors++ }
if (!eval 'require Win32::Process::Info; Win32::Process::Info->VERSION(1.002);') { warn $@; $require_errors++ }warn "Autoinstallation of prerequisites completed\n" if !$require_errors;
