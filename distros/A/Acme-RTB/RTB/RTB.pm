package Acme::RTB;

use 5.008;
use strict;
use warnings;
use IO::Select;
use IO::Handle;

our $VERSION = '0.01';


=head1 NAME

Acme::RTB - Perl extension for building realtimebattle bots

=head1 SYNOPSIS

  use Acme::RTB;
  my $robot = Acme::RTB->new({  Name    => 'Anarion PerlBot 1.0',
                                Colour  => 'ff0000 ff0000',
                                Log     => '/home/anarion/perl/rtb/robot.log'} );

  $robot->Start;

=head1 DESCRIPTION

This module will allow you to create bots for battling with realtimebattle.
L<http://realtimebattle.sourceforge.net/>

=head1 METHODS

=over 4

=head2 new

=back

First create an object, you should pass a hashref with the Name, Colour and if you
will the logfile.

  my $robot = Acme::RTB->new({  Name    => 'Anarion PerlBot 1.0',
                                Colour  => 'ff0000 ff0000',
                                Log     => '/home/anarion/perl/rtb/robot.log'} );


=over 4

=head2 modify_action

=back

With this method you can change all the actions that your bot do when it recieves
a msg from the server, the possible actions are:

                Initialize
                YourName
                YourColour
                GameOption
                GameStarts
                Radar
                Info
                RobotInfo
                RotationReached
                Energy
                RobotsLeft
                Collision
                Warning
                Dead
                GameFinishes
                Unknown


$robot->modify_action(  Radar           => \&my_radar    );

$robot->modify_action(  GameStarts      => \&my_gamestart);

$robot->modify_action(  Collision       => \&my_collision);

Here are the parameters that you recieve from the server:


=head3 Initialize [first? (int)]


This is the very first message the robot will get. If the argument is one, it is the first sequence in the tournament and it should send Name and Colour to the server, otherwise it should wait for YourName and YourColour messages (see below).

=head3 YourName [name (string)]

Current name of the robot, don't change it if you don't have very good reasons.

=head3 YourColour [colour (hex)]

Current colour of the robot, change it if you find it ugly.

=head3 GameOption [optionnr (int)] [value (double)]

At the beginning of each game the robots will be sent a number of settings, which can be useful for the robot. For a complete list of these, look in the file Messagetypes.h for the game_option_type enum. In the options chapter you can get more detailed information on each option. The debug level is also sent as a game option even though it is not in the options list.

=head3 GameStarts

This message is sent when the game starts (surprise!)

=head3 Radar [distance (double)] [observed object type (int)] [radar angle (double)]

This message gives information from the radar each turn. Remember that the radar-angle is relative to the robot front; it is given in radians.

=head3 Info [time (double)] [speed (double)] [cannon angle (double)]

The Info message does always follow the Radar message. It gives more general information on the state of the robot. The time is the game-time elapsed since the start of the game. This is not necessarily the same as the real time elapsed, due to time scale and max timestep.

=head3 Coordinates [x (double)] [y (double)] [angle (double)]

Tells you the current robot position. It is only sent if the option Send robot coordinates is 1 or 2. If it is 1 the coordinates are sent relative the starting position, which has the effect that the robot doesn't know where it is starting, but only where it has moved since.

=head3 RobotInfo [energy level (double)] [teammate? (int)]

If you detect a robot with your radar, this message will follow, giving some information on the robot. The opponents energy level will be given in the same manner as your own energy (see below). The second argument is only interesting in team-mode (which current isn't implemented), 1 means a teammate and 0 an enemy.

=head3 RotationReached [what has reached(int)]

When the robot option SEND_ROTATION_REACHED is set appropriately, this message is sent when a rotation (with RotateTo or RotateAmount) has finished or the direction has changed (when sweeping). The argument corresponds to 'what to rotate' in e.g. Rotate.

=head3 Energy [energy level(double)]

The end of each round the robot will get to know its energy level. It will not, however, get the exact energy, instead it is discretized into a number of energy levels.

=head3 RobotsLeft [number of robots (int)]

At the beginning of the game and when a robot is killed the number of remaining robots is broadcasted to all living robots.

=head3 Collision [colliding object type (int)] [angle relative robot (double)]

When a robot hits (or is hit by) something it gets this message. In the file Messagetypes.h you can find a list of the object types. You get the angle from where the collision occurred (the angle relative the robot) and the type of object hitting you, but not how severe the collision was. This can, however, be determined indirectly (approximately) by the loss of energy.

=head3 Warning [warning type (int)] [message (string)]

A warning message can be sent when robot has to be notified on different problems which have occured. Currently seven different warning messages can be sent, namely

UNKNOWN_MESSAGE: The server received a message it couldn't recognize.

PROCESS_TIME_LOW: The CPU usage has reached the CPU warning percentage. Only in competition-mode.

MESSAGE_SENT_IN_ILLEGAL_STATE: The message received couldn't be handled in this state of the program. For example Rotate is sent before the game has started.

UNKNOWN_OPTION: The robot sent a robot option with either illegal option name or illegal argument to that option.

OBSOLETE_KEYWORD: The keyword sent is obsolete and should not be used any more, see the ChangeLog file for information on what to use instead.

NAME_NOT_GIVEN: The robot has not sent its name before the game begins. This happens if the robot startup time is too short or the robot does not send its name early enough.

COLOUR_NOT_GIVEN: The robot has not sent its colour before the game begins.

=head3 Dead

Robot died. Do not try to send more messages to the server until the end of the game, the server doesn't read them.

=head3 GameFinishes

Current game is finished, get prepared for the next!

=head3 ExitRobot

Exit from the program immediately! Otherwise it will be killed forcefully.

=over 4

=head2 process_lines

=back

This is the method that reads (if it can) from the server and execute
the apropiate method. You can manage yourself, or let the module to
do it itself.

while(1)
{
        # Read stdin
        $robot->parse_lines;
        # do other stuff here

}

=over 4

=head2 Rotate [what to rotate (int)] [angular velocity (double)]

=back

Set the angular velocity for the robot, its cannon and/or its radar. Set 'what to rotate' to 1 for robot, 2 for cannon, 4 for radar or to a sum of these to rotate more objects at the same time. The angular velocity is given in radians per second and is limited by Robot (cannon/radar) max rotate speed.

=over 4

=head2 RotateTo [what to rotate (int)] [angular velocity (double)] [end angle (double)]

=back

As Rotate, but will rotate to a given angle. Note that radar and cannon angles are relative to the robot angle. You cannot use this command to rotate the robot itself, use RotateAmount instead!

=over 4

=head2 RotateAmount [what to rotate (int)] [angular velocity (double)] [angle (double)]

=back

As Rotate, but will rotate relative to the current angle.

=over 4

=head2 Sweep [what to rotate (int)] [angular velocity (dbl)] [left angle (dbl)] [right angle (dbl)]

=back

As rotate, but sets the radar and/or the cannon (not available for the robot itself) in a sweep mode.


=over 4

=head2 Accelerate [value (double)]

=back

Set the robot acceleration. Value is bounded by Robot max/min acceleration.


=over 4

=head2 Brake [portion (double)]

=back

Set the brake. Full brake (portion = 1.0) means that the friction in the robot direction is equal to Slide friction.


=over 4

=head2 Shoot [shot energy (double)]

=back

Shoot with the given energy. The shot options give more information.


=over 4

=head2 Print [message (string)]

=back

Print message on the message window.


=over 4

=head2 Debug [message (string)]

=back

Print message on the message window if in debug-mode.


=over 4

=head2 DebugLine [angle1 (double)] [radius1 (double)] [angle2 (double)] [radius2 (double)]

=back

Draw a line direct to the arena. This is only allowed in the highest debug level(5), otherwise a warning message is sent. The arguments are the start and end point of the line given in polar coordinates relative to the robot.


=over 4

=head2 DebugCircle [center angle (double)] [center radius (double)] [circle radius (double)]

=back

Similar to DebugLine above, but draws a circle. The first two arguments are the angle and radius of the central point of the circle relative to the robot. The third argument gives the radius of the circle.

=head1 EXAMPLES

My hello botworld:

  use Acme::RTB;
  my $robot = Acme::RTB->new({  Name    => 'Anarion PerlBot 1.0',
                                Colour  => 'ff0000 ff0000',
                                Log     => '/home/anarion/perl/rtb/robot.log'} );

  $robot->Start;


Example two:

#!/usr/bin/perl

use strict;
use warnings;
use lib "/home/anarion/perl/rtb";

use Acme::RTB;

my $robot = Acme::RTB->new({    Name    => 'Killer Montses',
                                Colour  => 'ff0000 ff0000',
                                Log     => '/home/anarion/perl/rtb/anarion.log'} );


$robot->modify_action(  Radar           => \&my_radar    );

$robot->modify_action(  GameStarts      => \&my_gamestart);

$robot->modify_action(  Collision       => \&my_collision);

$robot->Start;

sub my_radar
{
        my ($self, $dist, $obj, $angle) = @_;
        for($obj)
        {
                /0/ && do { robot($dist,$angle) };
                /1/ && do { dodge($dist,$angle) };
                /2/ && do { turn($dist,$angle)  };
                /3/ && do { cookie($dist,$angle) };
                /4/ && do { mine($dist,$angle) };
        }
}


sub my_gamestart
{
        my $self = shift;
        my $speed = rand(1)+1;
        my $angle = rand(0.4)-0.8;
        $self->Accelerate($speed);
        $self->RotateAmount(7,rand(2),rand(5));
}


sub my_collision
{
        my ($self, $object_type, $angle) = @_;
        $robot->RotateAmount(7,rand(2),rand(5)-2.5);
}


sub robot
{
        my ($dist, $angle) = @_;
        $robot->RotateTo(7,2,$angle-0.2);
        $robot->Shoot(10);
}


sub dodge
{
        $robot->RotateAmount(7,2,1);
}


sub turn
{
        my ($dist, $angle) = @_;
        if($dist < 10)
        {
                $robot->RotateAmount(7,2,rand(5)-2.5);
        }
}


sub cookie
{
        my ($dist, $angle) = @_;
        $robot->RotateAmount(7,2,$angle);
}


sub mine
{
        my ($dist, $angle) = @_;
        $robot->RotateTo(7,2,$angle);
        $robot->Shoot(1);
}

=head1 AUTHOR

Debian User, E<lt>anarion@7a69ezine.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Anarion

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


STDOUT->autoflush(1);
STDERR->autoflush(1);
my $select = IO::Select->new();
$select->add(*STDIN);

my %actions = ( Initialize      => \&initialize,
                YourName        => \&your_name,
                YourColour      => \&your_color,
                GameOption      => \&game_option,
                GameStarts      => \&game_starts,
                Radar           => \&radar,
                Info            => \&info,
                RobotInfo       => \&robot_info,
                RotationReached => \&rotation_reached,
                Energy          => \&energy,
                RobotsLeft      => \&robots_left,
                Collision       => \&collision,
                Warning         => \&warning,
                Dead            => \&dead,
                GameFinishes    => \&game_finish,
                Unknown         => \&unknown, );

my %options;
local *LOG;

sub new
{
        my ($class, $options) = @_;
        my $self = {    Name    => $options->{Name} || "RTB v$VERSION",
                        Colour  => $options->{Colour} || 'ff0000 ff0000',
                        Log     => $options->{Log} };
        if($options->{Log})
        {
                open(LOG,">$options->{Log}")
                        or die "Cant write to logfile: $options->{Log}: $!";
                LOG->autoflush(1);
        }

        my $obj = bless $self,$class;
        $obj->RobotOption(3,1); # Use Select
        $obj->RobotOption(1,1); # Rotation reached
        return $obj
}

###
sub modify_action
{
        my ($self, $key , $code) = @_;
        if(exists $actions{$key} and ref($code) eq "CODE")
        {
                $actions{$key} = $code;
        }
}

###
sub process_lines
{
        my $self = shift;
        while(my @l = $select->can_read(0.1))
        {
                my $hd = $l[0];
                my $msg = <$hd>;
                chomp($msg);
                print LOG "<--- $msg\n" if $self->{Log};
                my ($cmd, @options) = split' ',$msg;
                $cmd = 'Unknown' unless exists $actions{ $cmd };
                $actions{ $cmd }->($self, @options)
        }
}

###
sub initialize
{
        my ($self, $num) = @_;
        if ($num == 1)
        {
                $self->Name;
                $self->Colour;
        }
}

###
sub your_name
{
        my ($self, $name) = @_;
        $self->{Name} = $name;
}

###
sub your_colour
{
        my ($self, $name) = @_;
        $self->{Colour} = $name;
}

###
sub game_option
{
        my $self = shift;
        %options = split' ',shift;
}

###
sub game_starts
{


}

###
sub radar
{
        # Objects: Robot=0, Shot=1, Wall=2, Cookie=3, Mine=4, LAST=5
        my ($self, $dist, $obj, $angle) = @_;

}

###
sub info
{
        my ($self, $time, $speed, $cannon_angle) = @_;
}

###
sub robot_info
{
        my ($self, $energy, $teammate) = @_;
        $self->{Energy} = $energy;
}

###
sub rotation_reached
{
        my ($self, $what) = @_;
}

###
sub energy
{
        my ($self, $energy) = @_;
        $self->{Energy} = $energy;
}

###
sub robots_left
{
        my ($self, $robotsleft) = @_;
}

###
sub collision
{
        my ($self, $object_type, $angle) = @_;
}

###
sub warning
{
        my ($self, $warning_type, $msg) = @_;
}

###
sub dead
{

}

###
sub game_finish
{

}

###
sub unknown
{
        # Put here som sample code
        my $self = shift;
        print LOG "Unknown command: @_\n" if $self->{Log};
}

#### METHODS #####
sub RobotOption
{
        my ($self, $nr, $value) = @_;
        print "RobotOption $nr $value\n";
        print LOG "--> RobotOption $nr $value\n" if $self->{Log};
}

sub Name
{
        my $self = shift;
        print "Name $self->{Name}\n";
        print LOG "--> Name $self->{Name}\n" if $self->{Log};
}

sub Colour
{
        my $self = shift;
        print "Colour $self->{Colour}\n";
        print LOG "--> Colour $self->{Colour}\n" if $self->{Log};
}

sub Rotate
{
        # 1 - robot, 2 - cannon, 4 - radar
        my ($self, $what, $velocity) = @_;
        print "Rotate $what $velocity\n";
        print LOG "--> Rotate $what $velocity\n" if $self->{Log};

}

sub RotateTo
{
        my ($self, $what, $velocity, $end) = @_;
        print "RotateTo $what $velocity $end\n";
        print LOG "--> RotateTo $what $velocity $end\n" if $self->{Log};
}

sub RotateAmount
{
        my ($self, $what, $velocity, $angl) = @_;
        print "RotateAmount $what $velocity $angl\n";
        print LOG "--> RotateAmount $what $velocity $angl\n" if $self->{Log};
}

sub Sweep
{
        my ($self, $what, $velocity, $la, $ra) = @_;
        print "Sweep $what $velocity $la $ra\n";
        print LOG "--> Sweep $what $velocity $la $ra\n" if $self->{Log};
}

sub Accelerate
{
        my ($self, $value) = @_;
        print "Accelerate $value\n";
        print LOG "--> Accelerate $value\n" if $self->{Log};
}

sub Brake
{
        my ($self, $portion) = @_;
        print "Brake $portion\n";
        print LOG "Brake $portion\n" if $self->{Log};
}

sub Shoot
{
        my ($self, $energy) = shift;
        print "Shoot $energy\n";
        print LOG "Shoot $energy\n" if $self->{Log};
}

sub Print
{
        my ($self, $txt) = @_;
        print "Print $txt\n";
        print LOG "Print $txt\n" if $self->{Log};
}

sub Debug
{
        my ($self,$txt) = @_;
        print "Debug $txt\n";
        print LOG "Debug $txt\n" if $self->{Log};
}

sub DebugLine
{
        my ($self, $a1, $r1, $a2, $r2) = @_;
        print "DebugLine $a1 $r1 $a2 $r2\n";
        print LOG "DebugLine $a1 $r1 $a2 $r2\n" if $self->{Log};
}

sub DebugCircle
{
        my ($self, $a,$r1,$r2) = @_;
        print "DebugCircle $a $r1 $r2\n";
        print LOG "DebugCircle $a $r1 $r2\n" if $self->{Log};
}

sub Start
{
        my $self = shift;
        while(1)
        {
                $self->process_lines;
                sleep 1;
        }
}

sub Log
{
        my ($self, $msg) = @_;
        print LOG "$msg\n" if $self->{Log};
}

1;
