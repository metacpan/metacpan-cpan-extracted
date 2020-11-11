package App::Tk::Deparse;
use strict;
use warnings;
use 5.008;

use Browser::Open qw(open_browser open_browser_cmd);
use Path::Tiny qw(path);
use Capture::Tiny qw(capture);

use Tk;
use Tk::Dialog;
use Tk::HyperText;
use Tk::BrowseEntry;

our $VERSION = '0.02';

# TODO: make fonts more readable
# TODO: Clear the output when we change the input (or maybe rerun the deparse process?)
# TODO: use nice temporary filename as we can see the name of the file with the -l flags
# TODO: Save window size upon exit; restore window size upon start
# TODO: If there is a syntax error in the code B::Deparse will fail. We sould display this.


my $sample = q{
# Paste your code in the top window and click the Deparse button to see what B::Deparse thinks about it
for (my $j=0, $j<3, ++$j) {
    print $j;
}

my $pi = 3.14;      # -d changes this to a string
my $answer = "42";  # single quote or no quote?

my @planets = ('Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn');

my %h = (
name => "Foo Bar",
age => 42,
fruits => qw(Apple Banana Peach),
);


my $gentlemen = "Some names";
my $me = 'Perl';

print "Hello, $pi, @ladies, \u$gentlemen\E, \u\L$me!";

# Trying to show -P without success
sub foo (\@) { 1 } foo @x
};

my $s = q{
};

# Removed l for now showing the temporary filename does not do much good.
my @flags = ('d', 'p', 'q', 'P');

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    $self->{top} = MainWindow->new(
        -title => 'B::Deparse',
    );
    $self->create_menu;
    $self->create_app;
    $self->{incode}->insert("0.0", $sample);
    $self->deparse;

    return $self;
}

sub create_menu {
    my ($self) = @_;

    my $main_menu = $self->{top}->Menu();

    my $file_menu = $main_menu->cascade(-label => 'File', -underline => 0);
    #$file_menu->command(-label => 'Open Perl File', -command => sub { $self->show_open(); }, -underline => 0);
    $file_menu->command(-label => 'Quit (Ctrl-q)', -command => sub { $self->exit_app(); }, -underline => 0);

    my $about_menu = $main_menu->cascade(-label => 'Help', -underline => 0);
    $about_menu->command(-label => 'About', -command => sub { $self->show_about; }, -underline => 0);

    $self->{top}->configure(-menu => $main_menu);
}

sub show_about {
    my ($self) = @_;

    my $dialog = $self->{top}->DialogBox(
        -title   => 'About App::Deparse::Tk',
        -popover => $self->{top},
        -buttons => ['OK'],
    );

    my $html = $dialog->HyperText();
    $html->pack;
    $html->setHandler (Resource => \&onResource);
    $html->loadString(qq{<html>
      <head>
      <title>About App::Deparse::Tk</title>
      </head>
      <body>
         Version: $VERSION<br>
         &nbsp;<a href="https://metacpan.org/pod/Tk">Perl Tk</a>: $Tk::VERSION<br>
         <a href="https://metacpan.org/pod/B::Deparse">B::Deparse</a><br>
         Perl $]<br>
         <p>
         Create by Gabor Szabo<br>
         Source code on <a href="https://github.com/szabgab/App-Tk-Deparse">GitHub</a><br>
         Thanks to my <a href="https://www.patreon.com/szabgab">Patreon</a> supporters<br>

<h2>Supporters</h2>
<ul>
<li><a href="https://www.activestate.com/">ActiveState</a></li>
<li><a href="https://www.chatterjee.net/">Anirvan Chatterjee</a></li>
<li>Brian Gaboury</li>
<li><a href="https://www.linkedin.com/in/chan-wilson-b867b3/">Chan Wilson</a></li>
<li><a href="https://www.linkedin.com/in/fins0ck/">Csaba Gaspar</a></li>
<li><a href="https://www.linkedin.com/in/dihnen/">David Ihnen</a></li>
<li><a href="https://www.preshweb.co.uk/about/">David Precious</a></li>
<li>Frank Kropp</li>
<li>John Andersen</li>
<li>Magnus Enger</li>
<li><a href="https://www.linkedin.com/in/mjgardner/">Mark Gardner</a></li>
<li>Markus Hechenberger</li>
<li>Matthew Mitchell</li>
<li>Matthew Persico</li>
<li>Meir Guttman</li>
<li>Mike Small</li>
<li><a href="https://www.linkedin.com/in/n8dgr8/">Nathan Schlehlein</a></li>
<li><a href="https://www.linkedin.com/in/pfmabry/">Paul Mabry</a></li>
<li><a href="https://perl.careers/">Perl Careers</a></li>
<li>Richard Leach</li>
<li>Robert Coursen</li>
<li><a href="https://www.linkedin.com/in/shajiindia/">Shaji Kalidasan</a></li>
<li><a href="https://www.linkedin.com/in/shanta-mcbain-7b644437/">Shanta McBain</a></li>
<li><a href="https://www.linkedin.com/in/slobodanmiskovic/">Slobodan Mišković</a></li>
<li><a href="https://www.linkedin.com/in/stephen-jarjoura-a684401/">Stephen A. Jarjoura</a></li>
<li>Tony Edwardson</li>
<li><a href="https://www.linkedin.com/in/tori-hunter-00009639/">Tori Hunter</a></li>
<li><a href="https://bruck.co.il/">Uri Bruck</a></li>
<li>Victor Moral</li>
<li>Wolfgang Odendahl</li>
<li>Yes2Crypto</li>
<li>... + many others</li>
</ul>

      </body>
      </html>
    });

    $dialog->Show;
}

sub onResource {
    my ($html, %info) = @_;
    my $url = $info{href};
    #print $url, "\n";
    #open_browser($url); # https://rt.cpan.org/Public/Bug/Display.html?id=133315
    #print "done\n";
    my $cmd = open_browser_cmd($url);
    # TODO: verify that the URL is well formatted before passing it to system
    if ($^O eq 'MSWin32') {
        system("$cmd $url");
    } else {
        system("$cmd $url &");
    }
}

sub changed {
    my ($self, $event) = @_;
    # TODO can we delay this and only run the deparse process if there were no changes for some time (e.g. 1 sec)
    $self->deparse;
    #print("changed\n");
}

sub create_app {
    my ($self) = @_;
    $self->{incode} = $self->{top}->Text(
        -state => 'normal',
        -font  => ['fixed', 12],
        -bg    => 'white',
    );
    $self->{incode}->bindtags([$self->{incode}, 'Tk::Text', $self->{top}, 'all']);
    #$self->{incode}->bind('<<Modified>>' => sub { I could not get this working
    $self->{incode}->bind('<Any-KeyPress>' => sub { $self->changed(shift); });
    $self->{incode}->pack(-fill => 'both', -expand => 1);

    $self->{flags} = $self->{top}->Frame();
    $self->{flags}->pack(-side => 'top');

    for my $flag (@flags) {
        $self->{"${flag}_flag"} = 0;

        $self->{"${flag}_flag_checkbox"} = $self->{flags}->Checkbutton(
        -text     => "-$flag",
        -variable => \$self->{"${flag}_flag"},
        -font     => ['fixed', 10],
        -command  => sub { $self->deparse },
        );
        $self->{"${flag}_flag_checkbox"}->pack(-side => 'left');
    }
    # $self->{"s_flag"} = '';
    # my @s_values = qw(C i T);
    # $self->{"s_flag_widget"} = $self->{flags}->BrowseEntry(
    #     -label => "-s",
    #     -width => 3,
    #     -variable => \$self->{"s_flag"},
    # );
    # for my $s (@s_values) {
    #     $self->{"s_flag_widget"}->insert("end", $s);
    # }
    # $self->{"s_flag_widget"}->pack;

    $self->{outcode} = $self->{top}->Text(
        -state => 'disabled',
        -font => ['fixed', 12],
    );
    $self->{outcode}->pack(-fill => 'both', -expand => 1);


    $self->{deparse} = $self->{top}->Button(
        -text    => 'Deparse',
        -command => sub { $self->deparse },
    );
    $self->{deparse}->pack()

}

sub deparse {
    my ($self) = @_;

    my $code = $self->{incode}->get("0.0", 'end');
    my $temp = Path::Tiny->tempfile;
    path($temp)->spew($code);
        
    my $cmd = 'perl -MO=Deparse';
    for my $flag (@flags) {
        if ($self->{"${flag}_flag"}) {
            $cmd .= ",-$flag";
        }
    }
    if ($self->{s_flag}) {
        $cmd .= ",-s$self->{s_flag}"
    }

    my ($stdout, $stderr, $exit) = capture { system("$cmd $temp"); };
    $self->{outcode}->configure('state' => 'normal');
    $self->{outcode}->delete("0.0", 'end');
    if ($exit) {
        $self->{outcode}->configure('fg' => 'red');
        $self->{outcode}->insert("0.0", $stderr);
    } else {
        $self->{outcode}->configure('fg' => 'black');
        $self->{outcode}->insert("0.0", $stdout);
    }
    $self->{outcode}->configure('state' => 'disabled');
}

sub run {
    my ($self) = @_;
    MainLoop;
}

sub exit_app {
    my ($self) = @_;

    # TODO: Save flags when exiting
    # TODO: Save content of the input window when exiting
    # TODO: Save current window size so we can start the same size next time.
    # my %config = (
    #     'geometry' => $self->{top}->geometry,
    # );
    # path($config_file)->spew(encode_json(\%config));

    exit;
}

1;

=head1 NAME

App::Tk::Deparse - Tk based GUI to experiment with B::Deparse

=head1 SYNOPSIS

    perl-deparse

=head1 DESCRIPTION

This is a GUI program. There are some videos on L<Perl Maven Tk|https://perlmaven.com/tk> explaining
how does this work and how was this built.

When the application exits we save the current window size in the config file and next time we use that size to open the application.

    ~/.perl-tk-deparse.json

=head1 SEE ALSO

L<B::Deparse>

L<Tk>

L<Tk::HyperText>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by L<Gabor Szabo|https://szabgab.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

