package App::Nag;
BEGIN {
  $App::Nag::VERSION = '0.002';
}

# ABSTRACT: send yourself a reminder


use Modern::Perl;
use Getopt::Long::Descriptive qw(describe_options prog_name);

# some icon specs
use constant PHRASE    => [qw(psst hey HEY !!!)];
use constant STROKE    => [qw(0000ff 0000ff ff0000 ff0000)];
use constant FILL      => [qw(ffffff ffffff ffffff ffff00)];
use constant OPACITY   => [ 0, 1, 1, 1 ];
use constant FONT_SIZE => [ 20, 25, 28, 32 ];
use constant XY        => [ [ 8, 40 ], [ 9, 40 ], [ 7, 41 ], [ 3, 43 ] ];


sub validate_args {
    my $name = prog_name;
    my ( $opt, $usage ) = describe_options(
        "$name %o <time> <text>+",
        [],
        ['Send yourself a reminder.'],
        [],
        [
            'urgency' => hidden => {
                one_of => [
                    [ 'nudge|n', 'low key reminder' ],
                    [
                        'poke|p',
                        'reminder with no particular urgency (default)'
                    ],
                    [ 'shake|s', 'urgent reminder' ],
                    [ 'slap',    'do this!!!' ],
                ]
            }
        ],
        [],
        [ 'help', "print usage message and exit" ],
    );

    print( $usage->text ), exit if $opt->help;
    given ( scalar @ARGV ) {
        when (0) {
            $usage->die(
                {
                    pre_text => "ERROR: No time or message.\n\n"
                }
              )
        }
        when (1) {
            $usage->die(
                {
                    pre_text => "ERROR: No message.\n\n"
                }
              )
        }
    }
    return ( $opt, $usage, $name );
}


sub validate_time {
    my ( undef, $opt, $usage, $time, @args ) = @_;
    require DateTime;
    require DateTime::TimeZone;

    # parse time
    $usage->die(
        {
            pre_text => "ERROR: could not understand time expression: $time\n\n"
        }
    ) unless my %props = _parse_time($time);
    my $tz = DateTime::TimeZone->new( name => 'local' );
    my $now = DateTime->now( time_zone => $tz );
    my $then = $now->clone;

    if ( $props{unit} ) {
        my $unit = $props{unit};
        given ($unit) {
            when ('h') { $unit = 'hours' }
            when ('m') { $unit = 'minutes' }
            when ('s') { $unit = 'seconds' }
        }
        $then->add( $unit => $props{time} );
    }
    else {
        my ( $hour, $minute ) = @props{qw(hour minute)};
        $usage->die( { pre_text => "ERROR: impossible time\n\n" } )
          unless $hour < 25 && $minute < 60;
        my $suffix = $props{suffix};
        $usage->die( { pre_text => "ERROR: impossible time\n\n" } )
          if $hour > 12 && $suffix eq 'a';
        $then->set( hour => $hour, minute => $minute, second => 0 );
        if ( $hour < 13 ) {
            $then->add( hours => 12 ) while $then < $now;
            given ($suffix) {
                when ('a') { $then->add( hours => 12 ) if $then->hour >= 12 }
                when ('p') { $then->add( hours => 12 ) if $then->hour < 12 }
            }
        }
        else {
            $then->add( days => 1 ) if $then < $now;
        }
    }
    my $seconds = $then->epoch - $now->epoch;
    $seconds = 0 if $seconds < 0;    # same moment

    # set verbosity level
    my $verbosity;
    given ( $opt->urgency ) {
        when ('nudge') { $verbosity = 0 }
        when ('poke')  { $verbosity = 1 }
        when ('shake') { $verbosity = 2 }
        when ('slap')  { $verbosity = 3 }
        default        { $verbosity = 1 }
    };

    # generate message text and synopsis
    my $text = join ' ', @args;
    $text =~ s/^\s++|\s++$//g;
    $text =~ s/\s++/ /g;
    ( my $synopsis = $text ) =~ s/^(\S++(?: \S++){0,3}).*/$1/;
    $synopsis .= ' ...' if length($text) - length($synopsis) > 4;
    return ( $verbosity, $text, $synopsis, $seconds );
}

# extract useful bits out of a time expression
# tried to do this with a more readable recursive regex and callbacks but got
# OOM errors at unpredictable intervals so I gave up
sub _parse_time {
    my %props;
    given ( $_[0] ) {
        when (/^(\d++)([hms])$/i) { @props{qw(time unit)} = ( $1, lc $2 ) }
        when (/^(\d{1,2})(?::(\d{2}))?(?:([ap])(\.?)m\4)?$/i) {
            @props{qw(hour minute suffix)} = ( $1, $2 || 0, lc( $3 || '' ) )
        }
    }
    return %props;
}


sub run {
    my ( undef, $name, $seconds, $text, $synopsis, $verbosity ) = @_;
    unless (fork) {
        require Gtk2::Notify;
        Gtk2::Notify->init($name);

        sleep $seconds;

        my $icon = _icon( $name, $verbosity );
        if ( $verbosity == 3 ) {
            require App::Nag::Slap;
            App::Nag::Slap->run( $synopsis, $text, $icon );
        }
        else {
            Gtk2::Notify->new( $synopsis, $text, $icon )->show;
        }
        unlink $icon;
    }
}

# make a somewhat eye-catching icon
sub _icon {
    my ( $name, $verbosity ) = @_;
    require File::Temp;

    my $phrase    = PHRASE->[$verbosity];
    my $fill      = FILL->[$verbosity];
    my $stroke    = STROKE->[$verbosity];
    my $font_size = FONT_SIZE->[$verbosity];
    my ( $x, $y ) = @{ XY->[$verbosity] };
    my $text = <<END;
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<!-- 
Created by $name with some help from Inkscape (http://www.inkscape.org/) 
-->
<svg xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:cc="http://creativecommons.org/ns#"
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns="http://www.w3.org/2000/svg" width="64px" height="64px"
version="1.1">
  <g id="layer1">
    <rect style="fill:#$fill;fill-rule:evenodd;stroke:#$stroke;stroke-width:3px;stroke-linecap:butt;stroke-linejoin:round;stroke-opacity:1"
    id="rect2993" width="62" height="62" x="1" y="1" />
    <text xml:space="preserve"
    style="font-size:${font_size}px;font-style:normal;font-weight:bold;line-height:125%;letter-spacing:0px;word-spacing:0px;fill:#$stroke;fill-opacity:1;stroke:none;font-family:Monospace;opacity:1"
x="12.525171" y="28.595528" id="text3763">
<tspan id="tspan3765" x="$x" y="$y">$phrase</tspan>
</text>
  </g>
</svg>
END
    my ( $fh, $filename ) =
      File::Temp::tempfile( TEMPLATE => 'nagXXXXXX', SUFFIX => '.svg' );
    print $fh $text;
    $fh->close;
    return $filename;
}

1;

__END__
=pod

=head1 NAME

App::Nag - send yourself a reminder

=head1 VERSION

version 0.002

=head1 DESCRIPTION

C<App::Nag> does some heavier argument validation after the initial validation
performed by the initial script. If all looks good, it sets a daemon process
going that will wait the appointed time and then pop up a notification.

This module is written only to serve C<nag>. Use outside of this application at your
own risk.

=head1 METHODS

=head2 validate_args

C<validate_args> does your basic argument validation. If all goes well
it returns C<$opt> and C<$usage> arguments as per L<Getopt::Long::Descriptive> and 
a C<$name> argument as per C<Getopt::Long::Descriptive::prog_name>.

=head2 validate_time

C<validate_time> confirms the validity of the time expression. If all goes well
it generates a numeric verbosity level, title and body text, for whatever
widget is to pop up, and a number of seconds to wait before making and
displaying the widget.

=head2 run

C<run> spawns a daemon process which will wait until the appointed time
and then pop up the notification widget. It takes the program name, seconds
to wait, body and title text, and verbosity level. It returns nothing.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

