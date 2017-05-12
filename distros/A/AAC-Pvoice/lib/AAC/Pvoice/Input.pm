package AAC::Pvoice::Input;
use strict;
use warnings;

use Wx qw(:everything);
use Wx::Perl::Carp;
BEGIN
{
    use Device::ParallelPort;
    if ($^O eq 'MSWin32')
    {
        require Device::ParallelPort::drv::win32;
    }
    else
    {
        require Device::ParallelPort::drv::parport;
    }
}
use Wx::Event qw(   EVT_TIMER
                    EVT_CHAR
                    EVT_MOUSE_EVENTS);
our $VERSION     = sprintf("%d.%02d", q$Revision: 1.12 $=~/(\d+)\.(\d+)/);

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{window} = shift;

    # We get the configuration from the Windows registry
    # If it's not initialized, we provide some defaults
    $self->{window}->{config} = Wx::ConfigBase::Get || croak "Can't get Config";

    # Get the input-device
    # icon   = mouse left/right buttons
    # adremo = electric wheelchair adremo
    # keys   = keystrokes
    $self->{window}->{Device} = $self->{window}->{config}->Read('Device',    'icon');

    $self->{window}->{Interval}          = $self->{window}->{config}->ReadInt('Interval', 10);
    $self->{window}->{Buttons}           = $self->{window}->{config}->ReadInt('Buttons',   2);
    $self->{window}->{OneButtonInterval} = $self->{window}->{config}->ReadInt('OneButtonInterval',    2000);

    $self->_initmonitor if $self->{window}->{Device} eq 'adremo';
    $self->_initautoscan if $self->{window}->{config}->ReadInt('Buttons') == 1;
    $self->_initkeys;
    $self->_initicon;

    $self->StartMonitor if $self->{window}->{Device} eq 'adremo';
    $self->StartAutoscan if $self->{window}->{config}->ReadInt('Buttons') == 1;

    return $self;
}

sub newchild
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{window} = shift;

    # We get the configuration from the Windows registry
    # If it's not initialized, we provide some defaults
    $self->{window}->{config} = Wx::ConfigBase::Get || croak "Can't get Config";

    # Get the input-device
    # icon   = mouse left/right buttons
    # adremo = electric wheelchair adremo
    # keys   = keystrokes
    $self->{window}->{Device} = $self->{window}->{config}->Read('Device',    'icon');

    $self->_initkeys;
    $self->_initicon;

    return $self;
}

sub _initkeys
{
    my $self = shift;
    EVT_CHAR($self->{window}, \&_keycontrol)
        if $self->{window}->{config}->Read('Device') eq 'keys';
}

sub _initicon
{
    my $self = shift;
    EVT_MOUSE_EVENTS($self->{window}, \&_iconcontrol)
        if $self->{window}->{config}->Read('Device') eq 'icon';
}

sub _initmonitor
{
    my $self = shift;
    # The event for the adremo device
    $self->{window}->{adremotimer} = Wx::Timer->new($self->{window},my $tid = Wx::NewId());
    EVT_TIMER($self->{window}, $tid, \&_monitorport);
}

sub _initautoscan
{
    my $self = shift;
    $self->{window}->{onebuttontimer} = Wx::Timer->new($self->{window},my $obtid = Wx::NewId());
    EVT_TIMER($self->{window}, $obtid, sub{my $self = shift; $self->{input}->{next}->() if $self->{input}->{next}});
}

sub StartMonitor
{
    my $self = shift;
    $self->{window}->{adremotimer}->Start($self->{window}->{Interval}, 0) # 0 is continuous
                                                if $self->{window}->{adremotimer};
}

sub QuitMonitor
{
    my $self = shift;
    # stop the timer for the port monitor
    $self->{window}->{adremotimer}->Stop() if  $self->{window}->{adremotimer} && $self->{window}->{adremotimer}->IsRunning;
}

sub StartAutoscan
{
    my $self = shift;
    $self->{window}->{onebuttontimer}->Start($self->{window}->{OneButtonInterval}, 0)  # 0 is continuous
                                                if $self->{window}->{onebuttontimer};
}

sub QuitAutoscan
{
    my $self = shift;
    $self->{window}->{onebuttontimer}->Stop() if  $self->{window}->{onebuttontimer} && $self->{window}->{onebuttontimer}->IsRunning;
}

sub PauseMonitor
{
    my $self = shift;
    my $bool = shift;
    return unless $self->{window}->{config}->Read('Device') eq 'adremo';
    $self->QuitMonitor if $bool;
    $self->StartMonitor unless $bool;
}

sub PauseAutoscan
{
    my $self = shift;
    my $bool = shift;
    return unless $self->{window}->{config}->ReadInt('Buttons') == 1;
    $self->QuitAutoscan if $bool;
    $self->StartAutoscan unless $bool;
}

sub Pause
{
    my $self = shift;
    $self->{pause} = shift;
}

sub GetDevice
{
    my $self = shift;
    return $self->{window}->{config}->Read('Device');
}

sub SetupMouse
{
    my $self = shift;
    my ($window, $subgetfocus, $subup, $sublosefocus) = @_;

    if ($self->{window}->{config}->Read('Device') eq 'mouse')
    {
        EVT_MOUSE_EVENTS($window, sub { my ($self, $event) = @_;
                                        &$subup         if $event->LeftUp;
                                        &$sublosefocus  if $event->Leaving;
                                        &$subgetfocus   if $event->Entering;
                                      });
    }


}

sub Next
{
    my $self = shift;
    my $sub = shift;
    $self->{next} = $sub;
}

sub Select
{
    my $self = shift;
    my $sub = shift;
    $self->{select} = $sub;
}

sub _keycontrol
{
    # BEWARE: $self is the window object this event belongs to
    my ($self, $event) = @_;
    return if $self->{pause};
    $self->{input}->{select}->() if ($event->GetKeyCode == $self->{config}->ReadInt('SelectKey', WXK_RETURN)) || (uc(chr($event->GetKeyCode)) eq uc(chr($self->{config}->ReadInt('SelectKey'))));
    $self->{input}->{next}->()   if (( ($event->GetKeyCode == $self->{config}->ReadInt('NextKey', WXK_SPACE)) ||
                                       (uc(chr($event->GetKeyCode)) eq uc(chr($self->{config}->ReadInt('NextKey'))))) and
                                     (not $self->{config}->ReadInt('Buttons') == 1));
}

sub _iconcontrol
{
    # BEWARE: $self is the window object this event belongs to
    my ($self, $event) = @_;
    return if $self->{pause};
    $self->{input}->{select}->() if $event->LeftUp;
    $self->{input}->{next}->()   if $event->RightUp &&
                                    not $self->{config}->ReadInt('Buttons') == 1;
}

#----------------------------------------------------------------------
# This sub is used to monitor the parallel port for the adremo device
sub _monitorport
{
    # BEWARE: $self is the wxWindow subclass the timer
    # belongs to!
    my ($self, $event) = @_;
    # do nothing if the device is not adremo or
    # if we're already running
    return if ($self->{monitorrun}                           || 
               (not $self->{input}->{next})                  || 
               (not $self->{input}->{select})                ||
               $self->{pause});
    # set the flag that we're checking the port
    $self->{monitorrun} = 1;
    $self->{pp} = Device::ParallelPort->new() if not $self->{pp};
    my $curvalue = $self->{pp}->get_status();
    if (not defined $curvalue)
    {
        # clear the flag that we're checking the port and return
        $self->{monitorrun} = 0;
        return
    }
    $self->{lastvalue} = 0 if not exists $self->{lastvalue};
    # if we detect a change...
    if ($curvalue != $self->{lastvalue})
    {
        unless ($curvalue & 0x40)
        {
            # if bit 6 is off it's a headmove to the right
            # which will indicate a Next() event unless we're in
            # one button mode
            $self->{input}->{next}->() unless $self->{config}->ReadInt('Buttons') == 1;
        }
        if ($curvalue & 0x80)
        {
            # if bit 7 is on (this bit is inverted), it's a headmove to the left
            # which will indicate a Select() event.
            $self->{input}->{select}->();
        }
    }
    # the current value becomes the last value
    $self->{lastvalue} = $curvalue if $curvalue;

    # clear the flag that we're checking the port
    $self->{monitorrun} = 0;
}


1;

__END__

=head1 NAME

AAC::Pvoice::Input - A class that handles the input that controls a pVoice-like application

=head1 SYNOPSIS

  # this module will normally not be called directly. It's called from
  # AAC::Pvoice::Panel by default


=head1 DESCRIPTION

AAC::Pvoice::Input allows one or two button operation of an AAC::Pvoice based
application.
The module uses Device::ParallelPort, so it should be able to run
on Win32 as well as Linux platforms.

=head1 USAGE

=head2 new($window)

This constructor takes the window (AAC::Pvoice::Panel typically) on which
the events and timer will be called as a parameter.
If the configuration (read using Wx::ConfigBase::Get) has a key called
'Device' (which can be set to 'icon', 'keys' , 'mouse' or 'adremo') is set to 'adremo', it
will start polling the parallel port every x milliseconds, where x is the
value of the configuration key 'Interval'. This setting is only useful if you connect
an "Adremo" electrical wheelchair to the parallel port of your PC (for more
information see http://www.adremo.nl).
If the key 'Device' is set to 'icon' it will respond to the left and right
mouse button, and if it's set to 'keys' it will respond to the configuration
keys 'SelectKey' and 'NextKey' (which are the keyboard codes for the 'select'
and 'next' events respectively.

AAC::Pvoice::Input has the ability to operate with either one or two buttons.
If you want to use only one button, you need to set the configuration key "Buttons"
to 1, and it will automatically invoke the subroutine you pass to Next() 
at an interval of the value set in the configuration key OneButtonInterval (set in milliseconds).

The default for is to operate in two button mode, and if OneButtonInterval is not 
set, it will use a default of 2000 milliseconds if "Buttons"  is set to 1.

=head2 newchild($window)

This semi-constructor takes the window (usually a child of the panel you
passed to the new() constructor, on which the events will be called as a parameter.
It doesn't start the timers for polling the parallel port and automatic
invocation of the Next() subroutine, because those timers otherwise would
be started multiple times.
Apart from starting those timers, this method works exactly like the new()

=head2 Next(sub)

This method takes a coderef as parameter. This coderef will be invoked when
the 'Next' event happens.

If the Device (see 'new') is set to 'icon', and a right mousebutton is
clicked, a 'Next' event is generated.
If the Device is set to 'adremo' and the headsupport of the wheelchair
is moved to the right, that will also generate a 'Next' event.
If the Device is set to 'keys' and a key is pressed that corresponds with the 
keycode set in the 'NextKey', this will generate a 'Next' event too.

=head2 Select(sub)

This method takes a coderef as parameter. This coderef will be invoked when
the 'Select' event happens.

If the Device (see 'new') is set to 'icon', and a left mousebutton is
clicked, a 'Select' event is generated.
If the Device is set to 'adremo' and the headsupport of the wheelchair
is moved to the left, that will also generate a 'Select' event.
If the Device is set to 'keys' and a key is pressed that corresponds with the 
keycode set in the 'SelectKey', this will generate a 'Select' event too.

=head2 GetDevice

This method will return the value of the configuration key called 'Device'

=head2 SetupMouse($window, $subgetfocus, $subup, $sublosefocus)

This method is used to setup a button for normal mouse input (when
configuration key 'Device' is set to 'mouse'). It takes the wxWindow
(typically a Wx::BitmapButton) that should respond to this way of
input as the first parameter.
$subgetfocus is the coderef that should be invoked when the mousecursor
hovers over this $window (EVT_ENTER).
$subup is the coderef that should be invoked when the left mousebutton
is released (EVT_LEFT_UP).
$sublosefocus is the coderef that should be invoked when the $window
loses focus (EVT_LEAVE).

=head2 StartMonitor

This method will start polling the the parallel port for input of the Adremo
Electrical Wheelchair.

=head2 QuitMonitor

This method will stop the timer that monitors the parallel port.

=head2 PauseMonitor($bool)

This method will pause ($bool is set to 1) or restart ($bool is set to 0)
the timer that monitors the parallel port.

=head2 StartAutoscan

This method will start the timer that invokes the Next() event every n milliseconds.

=head2 QuitAutoscan

This method will stop the timer that invokes the Next() method.

=head2 PauseAutoscan($bool)

This method will pause ($bool is set to 1) or restart ($bool is set to 0)
the timer that invokes the Next() method.



=head1 BUGS

probably a lot, patches welcome!


=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx

