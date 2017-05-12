package Cobalt::LCD;

use 5.006000;
use strict;
use warnings;
use Time::HiRes qw(time usleep);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub new {
    my $proto = shift;
    
    my $self = {
        '_SYSTEM_TYPE'      => '',
        
        '_PROG_GETIP'       => '/sbin/lcd-getip', 
        '_PROG_WRITE'       => '/sbin/lcd-write', 
        '_PROG_FLASH'       => '/sbin/lcd-flash', 
        '_PROG_READBUTTON'  => '/sbin/readbutton',
        '_PROC_SYSTYPE'     => '/proc/cobalt/systype',
        
        '_DEBOUNCE'         => 0,
        '_DEBOUNCE_TIMEOUT' => 0.5,
        
        '_USLEEP'           => 1000,
        
        'BUTTON_NONE'       => 0,
        'BUTTON_RESET'      => 0,
        'BUTTON_SELECT'     => 0,
        'BUTTON_EXIT'       => 0,
        'BUTTON_LEFT'       => 0,
        'BUTTON_RIGHT'      => 0,
        'BUTTON_UP'         => 0,
        'BUTTON_DOWN'       => 0,
    };
    
    bless $self, $proto;
    
    $self->lcd_init();
    
    return $self;
}

sub lcd_init ($) {
    my $self = shift;
    open(PROC,'<'.$self->{_PROC_SYSTYPE}) or die "Cannot open $self->{_PROC_SYSTYPE}!\nCheck to be sure the Cobalt drivers are installed in the kernel.";
    chomp($self->{_SYSTEM_TYPE} = lc(<PROC>));
    close (PROC);

    if ($self->{_SYSTEM_TYPE} eq 'pacifica') {
        $self->{BUTTON_NONE} = 0;
        $self->{BUTTON_RESET} =  64512;
        $self->{BUTTON_SELECT} = 32256;
        $self->{BUTTON_EXIT} =   48640;
        $self->{BUTTON_LEFT} =   64000;
        $self->{BUTTON_RIGHT} =  56832;
        $self->{BUTTON_UP} =     62976;
        $self->{BUTTON_DOWN} =   60928;
        
    } elsif ($self->{_SYSTEM_TYPE} eq 'carmel') {
        $self->{BUTTON_NONE} = 0;
        $self->{BUTTON_RESET} =  64512;
        $self->{BUTTON_SELECT} = 32256;
        $self->{BUTTON_EXIT} =   48640;
        $self->{BUTTON_LEFT} =   64000;
        $self->{BUTTON_RIGHT} =  56832;
        $self->{BUTTON_UP} =     62976;
        $self->{BUTTON_DOWN} =   60928;
        
    } elsif ($self->{_SYSTEM_TYPE} eq 'monterey') {
        $self->{BUTTON_NONE} = 0;
        $self->{BUTTON_RESET} =  64512;
        $self->{BUTTON_SELECT} = 32256;
        $self->{BUTTON_EXIT} =   48640;
        $self->{BUTTON_LEFT} =   64000;
        $self->{BUTTON_RIGHT} =  56832;
        $self->{BUTTON_UP} =     62976;
        $self->{BUTTON_DOWN} =   60928;
        
    } elsif ($self->{_SYSTEM_TYPE} eq 'alpine') {
        $self->{BUTTON_NONE} = 0;
        $self->{BUTTON_RESET} =  64512;
        $self->{BUTTON_SELECT} = 32256;
        $self->{BUTTON_EXIT} =   48640;
        $self->{BUTTON_LEFT} =   64000;
        $self->{BUTTON_RIGHT} =  56832;
        $self->{BUTTON_UP} =     62976;
        $self->{BUTTON_DOWN} =   60928;
        
    } elsif ($self->{_SYSTEM_TYPE} eq 'bigbear') {
        $self->{BUTTON_NONE} = 0;
        $self->{BUTTON_RESET} =  64512;
        $self->{BUTTON_SELECT} = 32256;
        $self->{BUTTON_EXIT} =   48640;
        $self->{BUTTON_LEFT} =   64000;
        $self->{BUTTON_RIGHT} =  56832;
        $self->{BUTTON_UP} =     62976;
        $self->{BUTTON_DOWN} =   60928;
        
    } else {
        die sprintf("Cannot determine the system type of the Cobalt.\n/proc/cobalt/systype reports %s.",$self->{_SYSTEM_TYPE});
    }
}

sub write ($$$) {
    my ($self,$line_a,$line_b) = @_;
    
    return system(sprintf('%s "%s" "%s"',$self->{_PROG_WRITE},$line_a,$line_b));
}

sub flash ($) {
    my $self = shift;
        warn "flash() is not currently supported as it locks the LCD.";    return;
        #return system(sprintf('%s',$self->{_PROG_FLASH}));
}

sub buttonstate ($) {
    my $self = shift;
    
    return system(sprintf('%s',$self->{_PROG_READBUTTON}))
}

sub waitforbutton ($$$) {
    my ($self,$timeout_time,$maxdown_time) = @_;
    my ($button,$start_time) = (0,0);
    
    while ($self->{_DEBOUNCE} > time()) {
        usleep $self->{_USLEEP};
    };
    
    $timeout_time += time();
    
    while (($button = $self->buttonstate()) == 0) {
        usleep $self->{_USLEEP};
        return ([0,0]) if ($timeout_time <= time());
    }
    $start_time = time();
    $maxdown_time = 60 if (!defined($maxdown_time));
    $maxdown_time += time();
    
    while ($self->buttonstate() != 0) {
        usleep $self->{_USLEEP};
        if ($maxdown_time <= time()) {
            $self->{_DEBOUNCE} = time() + $self->{_DEBOUNCE_TIMEOUT};
            return ([$button,time()-$start_time]);
        }
    };

    return ([$button,time()-$start_time]);
}

sub getip ($$$) {
    my ($self,$line_a,$ip) = @_;

    my $iip = `$self->{_PROG_GETIP} -1 \"$line_a\" -i $ip`;

    foreach (split(/\./,$iip,4)) {
        if (($_ < 0) || ($_ > 255)) {
            $iip = ''
        }
    }

    return $iip;
}

1;

__END__

=head1 NAME

Cobalt::LCD - Perl extension for interacting with the sys-apps/cobalt-panel-utils on Gentoo

=head1 SYNOPSIS

  use Cobalt::LCD;

  my $lcd = Cobalt::LCD->new();
  
  I'm not going to go in to detail at this time as the package is still very much in testing. If you want to play, read the source.

=head1 DESCRIPTION

Cobalt::LCD is used to work in a more friendly fashion with the Gentoo sys-apps/cobalt-panel-utils package.

=head2 EXPORT

Export? Do I have to pay taxes? I thought this sucker was duty free...

No exports, works better as an object due to certain bits of state information.

=head1 SEE ALSO

Provided you have the sys-apps/cobalt-panel-utils package installed, you can `man` the heck out of those utilities:

lcd-write
lcd-swrite
lcd-yesno
lcd-setcursor
lcd-getip
lcd-flash
readbutton
iflink
iflinkstatus

Also, checkout http://gentoo.404ster.com/ as that's where my projects are tracked.

=head1 AUTHOR

Jeff Walter <lt>jeffw@404ster.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jeff Walter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
