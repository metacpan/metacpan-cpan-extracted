package App::RoboBot::Plugin::Fun::Figlet;
$App::RoboBot::Plugin::Fun::Figlet::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 fun.figlet

Provides functions to interact with the external figlet program for generating
ASCII-art style text banners.

=cut

has '+name' => (
    default => 'Fun::Figlet',
);

has '+description' => (
    default => 'Provides functions to interact with the external figlet program for generating ASCII-art style text banners.',
);

=head2 figlet

=head3 Description

Given a font name and a string, returns a multi-line string containing the
generated figlet.

=head3 Usage

<font name> <string>

=head3 Examples

    :emphasize-lines: 2-6

    (figlet small robobot)
             _         _         _
     _ _ ___| |__  ___| |__  ___| |_
    | '_/ _ \ '_ \/ _ \ '_ \/ _ \  _|
    |_| \___/_.__/\___/_.__/\___/\__|

=head2 figlet-fonts

=head3 Description

Returns a list of the figlet fonts available.

=cut

has '+commands' => (
    default => sub {{
        'figlet' => { method      => 'figlet_convert',
                      description => 'Given a font name and a string, returns a multi-line string containing the generated figlet.',
                      usage       => '<font name> <string>', },

        'figlet-fonts' => { method      => 'figlet_fonts',
                            description => 'Returns a list of the figlet fonts available.', },
    }},
);

sub figlet_convert {
    my ($self, $message, $command, $rpl, $font, @args) = @_;

    unless (defined $font) {
        $message->response->raise('Must supply a valid font name. See (figlet-fonts) for the available fonts.');
        return;
    }

    my $string = join(' ', @args);

    unless (defined $string && length($string) > 0) {
        $message->response->raise('Must supply a string to figlet-ize.');
        return;
    }

    my @figlet;
    my $shortest_ws = 1_000;

    open(my $fh, '-|', '/usr/bin/figlet', '-l', '-w', 120, '-f', $font, $string) or return;
    while (my $ln = <$fh>) {
        chomp($ln);
        if ($ln =~ m{^(\s*)}) {
            $shortest_ws = length($1) if defined $1 && length($1) < $shortest_ws;
        }
        push(@figlet, $ln);
    }
    close($fh);

    @figlet = grep { $_ =~ m{\S+} } @figlet;

    if (@figlet > 6) {
        $message->response->raise('Generated figlet contains too many lines. Please try a shorter string or a different font.');
        return;
    }

    if ($shortest_ws > 0) {
        @figlet = map { substr($_, $shortest_ws) } @figlet;
    }

    if (grep { length($_) > 100 } @figlet) {
        $message->response->raise('Generated figlet is too wide. Please try a shorter string or a different font.');
        return;
    }

    return join("\n", @figlet);
}

sub figlet_fonts {
    my ($self, $message, $command, $rpl) = @_;

    my @fonts;

    opendir(my $dirh, '/usr/share/figlet') or return;
    while (my $fn = readdir($dirh)) {
        if ($fn =~ m{^(.+)\.flf}) {
            push(@fonts, $1);
        }
    }
    closedir($dirh);

    return sort { $a cmp $b } @fonts;
}

__PACKAGE__->meta->make_immutable;

1;
