package DMI::Decode;

our $VERSION = '2.04';

use base 'Exporter';
@EXPORT_OK = qw();
use strict;

use Inline C => 'DATA',
           VERSION => '2.04',
           NAME => 'DMI::Decode';

sub new {
	my ($class, $devmem) = @_;

	$devmem = "/dev/mem" unless defined $devmem;

	my $self = {};

	$self->{obj} = init($class, $devmem);

	bless  $self, $class;
	return $self;
}

sub os_information {
	my $self = shift;
	return get_os_information($self->{obj});
}

sub smbios_version {
	my $self = shift;
	my $ver = get_smbios_version($self->{obj});
	$self->{version} = $ver;
	return $self;
}

sub bios_information {
	my $self = shift;
	return get_bios_information($self->{obj});
}

sub system_information {
	my $self = shift;
	return get_system_information($self->{obj});
}

sub base_board_information {
	my $self = shift;
	return get_base_board_information($self->{obj});
}

sub processor_information {
	my $self = shift;
	return get_processor_information($self->{obj});
}


1;

__DATA__

=pod

=head1 NAME

DMI::Decode - Perl extension for extracting DMI Information

=head1 SYNOPSIS

  #!/usr/bin/perl 

  use strict;
  use warnings;
  use DMI::Decode;

  my $dmi = new DMI::Decode;

  my $bios = $dmi->bios_information;
 
  print "Vendor: " . $bios->{vendor}, "\n";
  print "Version: " . $bios->{version}, "\n";
  print "Rom Size: " . $bios->{romsize}, "\n";
  print "Runtime Size: " . $bios->{runtime}, "\n";
  print "Release Date: " . $bios->{release}, "\n";
 
  foreach (@{$bios->{characteristics}}) { print "\t\t$_\n"; }


=head1 DESCRIPTION

DMI::Decode - is a library that provides a object oriented way to display the 
DMI (Desktop Managment Information) some say SMBIOS (System Managment Basic 
Input Output System) of your computer. 

=head1 METHODS

=over 4

=item B<new($filename)>

- constructor. Optionally accepts a B<filename> argument. Returns DMI::Decode object.
The default B<filename> is B</dev/mem>.

=item B<smbios_version()>

- method. Returns a hash reference to the SMBIOS version.

=item B<bios_information()>

- method. Returns a hash reference to the bios information.

=item B<system_information()>

- method. Returns a hash reference to the system information.

=item B<base_board_information()>

- method. Returns a hash reference to the mother board information.

=item B<processor_information()>

- method. Returns a hash reference to the processor information.

=back


=head2 EXPORT

None by default.


=head1 SEE ALSO

 http://www.nongnu.org/dmidecode/, http://linux.dell.com/libsmbios/, http://sourceforge.net/projects/x86info/, 
 http://www.dmtf.org/standards/smbios, biosdecode(8), dmidecode(8), vpddecode(8) 

=head1 AUTHOR

Russell W. Pettway, E<lt>russell_pettway@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Russell W. Pettway

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

__C__

#include "src/dmidecode.c"
#include "src/util.c"

#include <sys/utsname.h>

char *system_hardware;

typedef struct {

char* smbios_version;

HV* os_information_hash;
HV* bios_information_hash;
HV* system_information_hash;
HV* processor_information_hash;
HV* base_board_information_hash;

} DMI;


SV* init(char* class,const char *devmem) {

int i, fd, found=0;
off_t fp=0xF0000;

#ifdef USE_EFI
        FILE *efi_systab;
        char linebuf[64];
#ifdef USE_MMAP
        u32 mmoffset;
        void *mmp;
#endif /* USE_MMAP */
#endif /* USE_EFI */
#if !(defined(USE_EFI) && defined(USE_MMAP))
        u8 buf[0x20];
#endif

AV* av_bios;
av_bios = newAV();

HV* os_information_hash;
os_information_hash = newHV();

HV* bios_information_hash;
bios_information_hash = newHV();

HV* system_information_hash;
system_information_hash = newHV();

HV* base_board_information_hash;
base_board_information_hash = newHV();

HV* processor_information_hash;
processor_information_hash = newHV();

DMI* dmi = malloc(sizeof(DMI));
SV*      obj_ref = newSViv(0);
SV*      obj = newSVrv(obj_ref, class);

struct utsname uts;


   if(sizeof(u8)!=1 || sizeof(u16)!=2 || sizeof(u32)!=4 || '\0'!=0)
        {
                fprintf(stderr,"%s: compiler incompatibility\n", devmem);
                exit(255);
        }
                                                                                                                             
        if((fd=open(devmem, O_RDONLY))==-1)
        {
                perror(devmem);
                exit(1);
        }
                                                                                                                             
#ifdef USE_EFI
        if((efi_systab=fopen("/proc/efi/systab", "r"))==NULL)
        {
                perror("/proc/efi/systab");
                exit(1);
        }
        while((fgets(linebuf, sizeof(linebuf)-1, efi_systab))!=NULL)
        {
                char* addr=memchr(linebuf, '=', strlen(linebuf));
                *(addr++)='\0';
                if(strcmp(linebuf, "SMBIOS")==0)
                {
                   fp=strtol(addr, NULL, 0);
                        printf("# SMBIOS entry point at 0x%08lx\n", fp);
                }
        }
        if(fclose(efi_systab)!=0)
                perror("/proc/efi/systab");
                                                                                                                             
#ifdef USE_MMAP
        mmoffset=fp%getpagesize();
        mmp=mmap(0, mmoffset+0x20, PROT_READ, MAP_PRIVATE, fd, fp-mmoffset);
    if(mmp==MAP_FAILED)
    {
       perror(devmem);
       exit(1);
    }
                                                                                                                             
        smbios_decode(((u8 *)mmp)+mmoffset, fd, devmem, devmem);
                                                                                                                             
        if(munmap(mmp, mmoffset+0x20)==-1)
                perror(devmem);
#else /* USE_MMAP */
        if(lseek(fd, fp, SEEK_SET)==-1)
        {
                perror(devmem);
                exit(1);
        }
        if(myread(fd, buf, 0x20, devmem)==-1)
                exit(1);
                                                                                                                             
        smbios_decode(buf, fd, devmem, devmem);
#endif /* USE_MMAP */
        found++;
#else /* USE_EFI */
        if(lseek(fd, fp, SEEK_SET)==-1)
        {
                perror(devmem);
                exit(1);
        }
        while(fp<=0xFFFF0)
        {
                if(myread(fd, buf, 0x10, devmem)==-1)
                        exit(1);
                fp+=16;
                                                                                                                             
                if(memcmp(buf, "_SM_", 4)==0 && fp<=0xFFFF0)
                {
                        if(myread(fd, buf+0x10, 0x10, devmem)==-1)
                                exit(1);
                        fp+=16;
                                                                                                                             
                        if(smbios_decode(buf, fd, devmem, devmem))
                        {
#ifndef USE_MMAP
                                /* dmi_table moved us far away */
                                lseek(fd, fp, SEEK_SET);
#endif /* USE_MMAP */
                                found++;
                        }
                }
     else if(memcmp(buf, "_DMI_", 5)==0
                 && checksum(buf, 0x0F))
                {

                        printf("Legacy DMI %u.%u present.\n", buf[0x0E]>>4, buf[0x0E]&0x0F);
			
                        dmi_table(fd, DWORD(buf+0x08), WORD(buf+0x06), WORD(buf+0x0C),
                                ((buf[0x0E]&0xF0)<<4)+(buf[0x0E]&0x0F), devmem, devmem);
                                                                                                                             
#ifndef USE_MMAP
                        /* dmi_table moved us far away */
                        lseek(fd, fp, SEEK_SET);
#endif /* USE_MMAP */
                        found++;
                }
        }
#endif /* USE_EFI */
                                                                                                                             
        if(close(fd)==-1)
        {
                perror(devmem);
                exit(1);
        }
                                                                                                                             
        if(!found) printf("# No SMBIOS nor DMI entry point found, sorry.\n");

	/***********************************************************
	 * Store the SMBIOS version if it was found in dmidecode.c *
         ***********************************************************/

	dmi->smbios_version = smbios_version ;

	/**********************************************
	 * This is were we setup the Bios Information *
	 **********************************************/
	hv_store (bios_information_hash, "vendor",  6,  newSVpv(vendor,  0), 0);
	hv_store (bios_information_hash, "version", 7,  newSVpv(version, 0), 0);
	hv_store (bios_information_hash, "release", 7,  newSVpv(release, 0), 0);
	hv_store (bios_information_hash, "runtime", 7,  newSVpv(runtime, 0), 0);
	hv_store (bios_information_hash, "romsize", 7,  newSVpv(romsize, 0), 0);

	for (i=0; i<=31; i++) {
 	 if (char_array[i] != NULL) {
	     av_push(av_bios, newSVpvf("%s", char_array[i]));
	 }
        }

	for (i=0; i<=6; i++){
	 if (char_array_x1[i] != NULL){
             av_push(av_bios, newSVpvf("%s", char_array_x1[i]));
	 }
	}

	for (i=0; i<=1; i++){
         if (char_array_x2[i] != NULL){
             av_push(av_bios, newSVpvf("%s", char_array_x2[i]));
         }
        }

        hv_store(bios_information_hash, "characteristics", 15, newRV_noinc((SV *) av_bios), 0);

	dmi->bios_information_hash = bios_information_hash;

	/************************************************
	 * This is were we setup the System Information *
	 ************************************************/
	hv_store (system_information_hash, "uuid",  4,  newSVpv(system_uuid,  0), 0);
	hv_store (system_information_hash, "name",  4,  newSVpv(system_name,  0), 0);
	hv_store (system_information_hash, "serial",  6,  newSVpv(system_serial,  0), 0);
	hv_store (system_information_hash, "wakeup",  6,  newSVpv(system_wakeup,  0), 0);
	hv_store (system_information_hash, "version",  7,  newSVpv(system_version,  0), 0);
	hv_store (system_information_hash, "manufacturer",  12,  newSVpv(system_manufacturer,  0), 0);
	
	/* Add here....*/

	if(uname(&uts) >= 0) {
	char *os_release  = uts.release;
	char *os_sysname  = uts.sysname;
	char *os_version  = uts.version;
	char *os_hardware = uts.machine;
	char *os_nodename = uts.nodename;

	hv_store (os_information_hash, "name",  4,  newSVpv(os_sysname,  0), 0);
	hv_store (os_information_hash, "release",  7,  newSVpv(os_release,  0), 0);
	hv_store (os_information_hash, "version",  7,  newSVpv(os_version,  0), 0);
	hv_store (os_information_hash, "nodename",  8,  newSVpv(os_nodename,  0), 0);
	hv_store (os_information_hash, "hardware",  8,  newSVpv(os_hardware,  0), 0);
	
	dmi->os_information_hash = os_information_hash;

	}

	dmi->system_information_hash = system_information_hash;
	
	/******************************************************
	 * This is were we setup the Mother Board Information *
	 *****************************************************/
	hv_store (base_board_information_hash, "name",  4,  newSVpv(system_board_name,  0), 0);
	hv_store (base_board_information_hash, "serial",  6,  newSVpv(system_board_serial,  0), 0);
	hv_store (base_board_information_hash, "version",  7,  newSVpv(system_board_version,  0), 0);
	hv_store (base_board_information_hash, "asset_tag",  9,  newSVpv(system_board_asset_tag,  0), 0);
	hv_store (base_board_information_hash, "manufacturer",  12,  newSVpv(system_board_manufacturer,  0), 0);

	dmi->base_board_information_hash = base_board_information_hash;
	
	/***************************************************
	 * This is were we setup the Processor Information *
	 ***************************************************/
	hv_store (processor_information_hash, "type",  4,  newSVpv(processor_type,  0), 0);
	hv_store (processor_information_hash, "family",  6,  newSVpv(processor_family,  0), 0);
	hv_store (processor_information_hash, "socket",  6,  newSVpv(processor_socket,  0), 0);
	hv_store (processor_information_hash, "version",  7,  newSVpv(processor_version,  0), 0);
	hv_store (processor_information_hash, "manufacturer",  12,  newSVpv(processor_manufacturer,  0), 0);

	dmi->processor_information_hash = processor_information_hash;



	/* Interger example...*/
	/*hv_store (bios_information_hash, "numbers", 7, newSViv(123456789), 0);*/

	sv_setiv(obj, (IV)dmi);
        SvREADONLY_on(obj);
        return obj_ref;
}


char* get_smbios_version (SV* obj) {
	return ((DMI*)SvIV(SvRV(obj)))->smbios_version;
}

HV* get_os_information(SV* obj) {
      return ((DMI*)SvIV(SvRV(obj)))->os_information_hash;
}

HV* get_bios_information(SV* obj) {
      return ((DMI*)SvIV(SvRV(obj)))->bios_information_hash;
}

HV* get_system_information(SV* obj) {
      return ((DMI*)SvIV(SvRV(obj)))->system_information_hash;
}

HV* get_base_board_information(SV* obj) {
      return ((DMI*)SvIV(SvRV(obj)))->base_board_information_hash;
}
   
HV* get_processor_information(SV* obj) {
      return ((DMI*)SvIV(SvRV(obj)))->processor_information_hash;
}
