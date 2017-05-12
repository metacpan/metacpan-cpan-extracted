package AI::MegaHAL;

require DynaLoader;
require Exporter;

use AutoLoader;
use Carp;

use strict;

use vars qw(@EXPORT @ISA $VERSION $AUTOLOAD);

@EXPORT = qw(megahal_setnoprompt
	     megahal_setnowrap
	     megahal_setnobanner
	     megahal_seterrorfile
	     megahal_setstatusfile
	     megahal_initialize
	     megahal_initial_greeting
	     megahal_command
	     megahal_do_reply
	     megahal_learn
	     megahal_output
	     megahal_input
	     megahal_cleanup);

@ISA = qw(Exporter DynaLoader);
$VERSION = '0.08';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined AI::MegaHAL macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

sub new {
    my ($class,%args) = @_;
    my $self;

    # Bless ourselves into the AI::MegaHAL class.
    $self = bless({ },$class);

    # Make sure that we can find a brain or a training file somewhere
    # else die with an error.
    my $path = $args{'Path'} || ".";
    if(-e "$path/megahal.brn" || -e "$path/megahal.trn") {
	chdir($path) || die("Error: chdir: $!\n");
    } else {
	die("Error: unable to locate megahal.brn or megahal.trn\n");
    }

    # Set some of the options that may have been passed to us.
    megahal_setnobanner() if(! $args{'Banner'});
    megahal_setnowrap()   if(! $args{'Wrap'});
    megahal_setnoprompt() if(! $args{'Prompt'});

    # This flag indicates whether or not we should automatically save
    # our brain when the object goes out of scope.
    $self->{'AutoSave'} = $args{'AutoSave'};

    # Initialize ourselves.
    $self->_initialize();

    return $self;
}

sub initial_greeting {
    my $self = shift;

    return megahal_initial_greeting();
}

sub do_reply {
    my ($self,$text) = @_;

    return megahal_do_reply($text,0);
}

sub learn {
    my ($self,$text) = @_;

    return megahal_learn($text,0);
}

sub _initialize {
    my $self = shift;

    megahal_initialize();
    return;
}

sub _cleanup {
    my $self = shift;

    megahal_cleanup();
    return;
}

sub DESTROY {
    my $self = shift;

    $self->_cleanup() if($self->{'AutoSave'});
    return;
}

bootstrap AI::MegaHAL $VERSION;
1;

__END__

=head1 NAME

AI::MegaHAL - Perl interface to the MegaHAL natural language conversation simulator.

=head1 SYNOPSIS

use AI::MegaHAL;

my $megahal = AI::MegaHAL->new('Path'     => './',
                           'Banner'   => 0,
                           'Prompt'   => 0,
                           'Wrap'     => 0,
                           'AutoSave' => 0);

my $text = $megahal->initial_greeting();

$text = $megahal->do_reply($message);

$megahal->learn($message);

=head1 DESCRIPTION

Conversation simulators are computer programs which give the appearance of conversing with a user in natural language.  Such programs are effective because they exploit the fact that human beings tend to read much more meaning into what is said than is actually there; we are fooled into reading structure into chaos, and we  interpret non-sequitur as valid conversation.

This package provides a Perl interface to the MegaHAL conversation simulator written by Jason Hutchens.

=head1 CONSTRUCTOR

$megahal = AI::MegaHAL->new('Path'     => './',
                           'Banner'   => 0,
                           'Prompt'   => 0,
                           'Wrap'     => 0,
                           'AutoSave' => 0);

Creates a new AI::MegaHAL object.  The object constructor can optionaly receive the following named parameters:

=over 4

=item B<Path> - The path to MegaHALs brain or training file (megahal.brn and megahal.trn respectively).  If 'Path' is not specified the current working directory is assumed.

=item B<Banner> - A flag which enables/disables the banner which is displayed when MegaHAL starts up.  The default is to disable the banner.

=item B<Prompt> - A flag which enables/disables the prompt. This flag is only useful when MegaHAL is run interactively and is disabled by default.

=item B<Wrap> - A flag which enables/disables word wrapping of MegaHALs responses when the lines exceed 80 characters in length.  The default is to disable word wrapping.

=back

=head1 METHODS

=head2 initial_greeting

$text = $megahal->initial_greeting();

Returns a string containing the initial greeting which is created by MegaHAL at startup.

=head2 do_reply

$text = $megahal->do_reply($message);

Generates reply $text to a given message $message.

=head2 learn

$megahal->learn($message);

Learns from $message without generating a response

=head1 BUGS

None known at this time.

=head1 SEE ALSO

POE::Component::AI::MegaHAL - IRC bot,

L<http://teaandbiscuits.org.uk/drupal/node/65> - Irssi IRC bot,

L<Hailo> - A pluggable Markov engine analogous to MegaHAL

=head1 AUTHOR

The Perl AI::MegaHAL interface was written by Cory Spencer <cspencer[at]sprocket.org>.

Now maintained by Alexandr Ciornii <alexchorny[at]gmail.com>.

MegaHAL was originally written by and is copyright Jason Hutchens <hutch[at]ciips.ee.uwa.edu.au>

=cut
