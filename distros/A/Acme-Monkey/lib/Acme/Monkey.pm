package Acme::Monkey;

=head1 NAME

Acme::Monkey - Monkeys here, monkeys there, MONKEYS everywhere!

=head1 ISOPONYS

  use Acme::Monkey;
  
  my $conway = Acme::Monkey->new();
  my $wall   = Acme::Monkey->new();
  
  $wall->groom( $conway );
  $conway->dump();

I so ponys, I so ponys.

=head1 DESCRIPTION

This module is a collaborative effort of several ValueClick Media
employees.  We developed this module to coincide with the
YAPC::NA 2007 conference in Houston, TX.  In the conference SWAG
bag we distributed about 275 monkey balls with the ValueClick logo
and a reference to this module.

This module is better than sliced gravy.

Make sure you check out the supporting scripts - monkey_life.pl
and monkey_ship.pl.

=cut

use strict;
use warnings;
use Time::HiRes qw(usleep);
use File::Find;

$SIG{__WARN__} = sub{ print STDERR "grrrr\n"; };
$SIG{__DIE__}  = sub{ print STDERR shift()."! eeek eeek!\n"; exit 1; };

our $VERSION = 4.99;

# Need...all other platforms
our %os_clrscr_commands = (
    'linux'   => 'clear',
    'MSWin32' => 'cls',
);

our $CLEAR_COMMAND = $os_clrscr_commands{$^O};

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{hunger}    = 80;
    $self->{happiness} = 50;
    $self->{drunkness} = 0;
    $self->{sub}       = undef;
    return $self;
}

sub monkey {
    print "Monkey!\n";
}

=head2 bastardize

  $monkey->bastardize( $object );

Add some useful features to any object.

=cut
#sub bastardize {
#    $self    =      splice(     @_,   0   ,1    );
#    {  #      Retrieve arguments    of  parameter.
#    no          strict;   $object    =       shift
#    ;my      @classes   =         $_[     0 ]    ;
#    $class=$classes->[1     -             1    ] ;
#    }     #Then    finsh  for        more   stuff.
#    no strict 'refs';*{$class.'::monkey' }=\$self;
#    *{ $class . '::DESTROY' } = sub{$monkey->slap}
#    ;  return 'SUPERCALIFRAJULISTICEXPIALIDOTIOUS'
#}

sub bastardize {
    return 'SUPERCALIFRAJULISTICEXPIALIDOTIOUS'
}

=head2 slap

Poor monkey...

=cut

sub slap {
    grrrr('Ouch!');
    $_[0]->_happiness( -1 );
}

sub fondle {
    die('pervert');
}

sub _happiness {
    $_[0]->{happiness} += $_[1];
    die('cry') if $_[0]->{happiness} <1;
}

sub groom {
    my $self   = shift;
    my $target = shift;
    if (ref($target) eq 'Acme::Monkey') {
        $target->_happiness(+1);
    }
    else {
        die "Target is not a monkey!\n";
    }
}

sub dump {
    my $self = shift;
    use Data::Dumper;
    print Dumper($self);
    return;
}

=head2 see

Allows the monkey to see a function. See do

sub shoot {
    print "Bang!\n";
}
$monkey = Acme::Monkey->new();
$monkey->see(\&shoot);
$monkey->do();
$monkey->do();

=cut

sub see {
    my $self = shift;
    my $sub  = shift;
    $self->{sub} = $sub;
}

=head2 do

Does what the monkey see()s

=cut

sub do {
    my $self = shift;
    return $self->{sub}->() if defined $self->{sub};
}


sub _hologram {
    print '  _   ######   _'."\n";
    print ' / \ #(*)(*)# / \\'."\n";
    print ' | {<#/ {} \#>} |'."\n";          
    print ' \_/#|      |#\_/'."\n";
    print '    #\======/#'."\n";
    print '     ########'."\n";          
    print '       ####'."\n";
}

=head2 swing

    $monkey->swing("/bin"); # Well, it sounds like vine. :)

    $monkey->swing(qw(/bin /var));

Monkey seeks out bananas in given directory trees.

=cut

sub swing {
    my $self            = shift;
    my @directory_trees = @_;

    our @bunch_o_nanas;

    $self->_hologram();
    print "\nSearching for bananas...\n\n";
    find(\&while_im_swinging_in, @directory_trees);

    # Bananas call back. Bananas find Monkey...
    sub while_im_swinging_in {
        if ($File::Find::name =~ m/.*banana.*/i) {
            push @bunch_o_nanas, $File::Find::dir.$File::Find::name;
        }
    }

    # Report on my swinging
    if (@bunch_o_nanas) {
        print "NO, we found bananas at...\n";
        print join("\n", @bunch_o_nanas);
        print "\n";
    }
    else {
        print "YES, we have no bananas.\n";
        print "How about dropping some!\n";
    }    
}

=head2 fling

A verb.

    $monkey->fling();

=cut

sub fling {
    my $fling_buffer = Acme::Monkey::FrameBuffer->new(W => 40, H => 10);

    system($CLEAR_COMMAND);
    for my $seq(@{$Acme::Monkey::FlingFrames::sequence}) {
        system($CLEAR_COMMAND);
        $fling_buffer->clear();
        $fling_buffer->put(@{$Acme::Monkey::FlingFrames::frames}[$seq], 2, 2);
        $fling_buffer->put([__PACKAGE__], 1, 1);
        $fling_buffer->draw();
        usleep(120000);
    }
}


use Exporter qw( import );
our @EXPORT = qw(grrrr bannana grubs wine beer vodka swing fling);

=head1 SUBROUTINES

Exporter is used to these on you.

  grrrr($stuff); # Like warn().
  bannana();     # For feeding.

=head2 CONSUMEABLES

  wine()      # For happy monkeys.
  grubs()     # Yummy.
  beer()     # Have anything stronger?
  vodka()        # Ya baby!
  bannana()   # The usual fare.

=cut

sub grrrr   { print STDERR join(' grrr ',@_)." GRRRR\n"; }
sub banana  { return 'food',  1; }
sub grubs   { return 'food',  2; }
sub wine    { return 'drunk', 2; }
sub beer    { return 'drunk', 1; }
sub vodka   { return 'drunk', 5; }

# Hmmm, Appears to be a Java inner class :)
{
    package Acme::Monkey::FrameBuffer;

    use Carp qw(croak);

    # TODO: put all OO boilerplate...

    sub new {
	    my $class  = shift;
	    my %params = @_;
	    my $self   = {};
	
	    $self->{WIDTH}  = $params{'width'}  || $params{'W'} || undef;
	    $self->{HEIGHT} = $params{'height'} || $params{'H'} || undef;

        # TODO: Should we just default X,Y instead?
	    croak "Width required\n"  if !defined($self->{WIDTH});
	    croak "Height required\n" if !defined($self->{HEIGHT});

	    $self->{BUF_SIZE} = $self->{WIDTH} * $self->{HEIGHT};
	    $self->{BUFFER}   = '';

	    bless($self, $class);
    }

    sub width {
	    my ($self) = shift;
	    return $self->{WIDTH};
    }

    sub height {
	    my ($self) = shift;
	    return $self->{HEIGHT};
    }

    sub get_buffer {
	    my $self = shift;
	    return $self->{BUFFER};
    }

    sub clear {
	    my $self = shift;
	    $self->{BUFFER} = ' ' x $self->{BUF_SIZE};
    }

    sub put {
	    my $self = shift;
	    my ($what, $xcoord, $ycoord) = @_;

	    $xcoord -= 1; 
	    $ycoord -= 1;
	
	    my $location = ($ycoord * $self->{WIDTH}) + $xcoord;
	
	    for my $line(@$what) {
		    substr($self->{BUFFER}, $location, length($line), $line);
		    $location += $self->{WIDTH};
	    }
    }

    sub draw {
	    my $self = shift;

	    for my $row(0..($self->{HEIGHT}-1)) {
		    my $line = substr($self->{BUFFER}, $row * $self->{WIDTH}, $self->{WIDTH});
		    print "$line\n";
	    }
    }

    !(!(!0));
}

{
    package Acme::Monkey::FlingFrames;

    use strict;
    use warnings;

    BEGIN {
        use Exporter();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
        $VERSION   = 0.01;
        @ISA       = qw(Exporter);
        @EXPORT_OK = qw($sequence $frames);
    }
    our @EXPORT_OK;

    our $sequence = [0,0,0,1,2,3,2,1,4,5,6,7,8,9];

    our $frames = [
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----*',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         * ',
		'   o@o  / ',
		'----|--- ',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '        * ',
		'   o@o  | ',
		'----|--- ',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----  *',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----     *',
		'    |    ',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |              *',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |                  *',
		'   ===   ',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |    ',
		'   ===                      *',
		'  |   |  ',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |    ',
		'   ===   ',
		'  |   |                          *',
	],
    [
	    '         ',
		'   o@o   ',
		'----|----',
		'    |    ',
		'   ===   ',
		'  |   |                          *',
    ],
];

    !(!(!0));
}

{
    package Acme::Monkey::ScreenBuffer;

    sub new {
        my ($class, $width, $height) = @_;
        my $self = bless {}, $class;
        $self->{width}  = $width;
        $self->{height} = $height;
        $self->clear_screen();
        $self->clear_buffer();
        return $self;
    }

    sub clear_screen {
        system( $CLEAR_COMMAND );
    }

    sub put {
        my ($self, $x, $y, $char) = @_;
        $self->{buffer}->[$x]->[$y] = $char;
        
    }

    sub get {
        my ($self, $x, $y) = @_;
        return $self->{buffer}->[$x]->[$y];
    }

    sub display {
        my ($self) = @_;

        my $out = '';
        foreach my $y (1..$self->{height}) {
            foreach my $x (1..$self->{width}) {
                $out .= $self->{buffer}->[$x]->[$y];
            }
            $out .= "\n";
        }
        $self->clear_screen();
        print $out;
    }

    sub flush {
        my ($self) = @_;
        $self->display();
        $self->clear_buffer();
    }

    sub clear_buffer {
        my ($self) = @_;
        my $buffer = [];
        foreach my $x (1..$self->{width}) {
            $buffer->[$x] = [];
            foreach my $y (1..$self->{height}) {
                $buffer->[$x]->[$y] = ' ';
            }
        }
        $self->{buffer} = $buffer;
    }

    sub scroll_left {
        my ($self) = @_;
        foreach my $x (2..$self->{width}) {
            foreach my $y (1..$self->{height}) {
                $self->{buffer}->[$x-1]->[$y] = $self->{buffer}->[$x]->[$y];
            }
        }
    }
}

1;

__END__

=head1 AUTHORS

Aran Deltac (L<adeltac@valueclick.com>)

Todd Presta (L<tpresta@valueclick.com>)

Mayukh Bose (L<mbose@valueclick.com>)

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=head1 COPYRIGHT

  Copyright (c) 2007 ValueClick, Inc.
  All Rights Reservered

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO
THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE
SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE
THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR
DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING
BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR
LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO
OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut
