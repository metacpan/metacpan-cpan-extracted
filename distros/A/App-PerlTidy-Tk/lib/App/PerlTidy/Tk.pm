package App::PerlTidy::Tk;
use strict;
use warnings;
use 5.008;

use Cwd qw(getcwd);
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);
use Perl::Tidy;

use Tk;
use Tk::Dialog;
use Tk::FileSelect;
use Tk::HyperText;
use Browser::Open qw(open_browser open_browser_cmd);

our $VERSION = '0.01';

#my %config = (
#    '--entab-leading-whitespace' => undef,
#    '--indent-columns' => 4,
#    '--maximum-line-length' => 80,
#    '--variable-maximum-line-length' => undef,
#    '--whitespace-cycle' => 0,
#    '--preserve-line-endings' => undef,
#    '--line-up-parentheses' => undef,
#);


sub run {
    my ($class) = @_;
    my $self = bless {}, $class;

    my $perlfile;
    GetOptions('perl=s' => \$perlfile) or die "Usage: $0 --perl somefile.pl\n";

    $self->{top} = MainWindow->new;
    $self->create_menu;
    $self->create_text_widget;

    if ($perlfile) {
        $self->load_perl_file($perlfile);
    }

    my ($option_string, $defaults, $expansion, $category, $option_range) = Perl::Tidy::generate_options();
    $self->{defaults} = $defaults;
    #print Dumper $option_string;
    #print Dumper $defaults;

    MainLoop;
}


sub create_menu {
    my ($self) = @_;

    my $main_menu = $self->{top}->Menu();

    my $file_menu = $main_menu->cascade(-label => 'File', -underline => 0);
    $file_menu->command(-label => 'Open', -command => sub { $self->show_open(); }, -underline => 0);
    $file_menu->command(-label => 'Quit', -command => sub { $self->exit_app(); }, -underline => 0);

    my $action_menu = $main_menu->cascade(-label => 'Action', -underline => 0);
    $action_menu->command(-label => 'Tidy', -command => sub { $self->run_tidy; });

    my $about_menu = $main_menu->cascade(-label => 'Help', -underline => 0);
    $about_menu->command(-label => 'About', -command => sub { $self->show_about; }, -underline => 0);

    $self->{top}->configure(-menu => $main_menu);
}

sub create_text_widget {
    my ($self) = @_;

    $self->{text} = $self->{top}->Text(
        -state => 'normal'
    );
    $self->{text}->pack(-fill => 'both', -expand => 1);
}

sub show_open {
    my ($self) = @_;

    my $start_dir = getcwd();
    my $file_selector = $self->{top}->FileSelect(-directory => $start_dir);
    my $filename = $file_selector->Show;
    $self->load_perl_file($filename);
}

sub load_perl_file {
    my ($self, $filename) = @_;

    if ($filename and -f $filename) {
        if (open my $fh, '<', $filename) {
            local $/ = undef;
            my $content = <$fh>;
            $self->{text}->delete("0.0", 'end');
            $self->{text}->insert("0.0", $content);
        } else {
            print "TODO: Report error $! for '$filename'\n";
        }
    }
}


sub run_tidy {
    my ($self) = @_;
    my %skip = map { $_ => 1 } qw(nocheck-syntax perl-syntax-check-flags);
    print Dumper \%skip;

    my $rc = '';
    for my $entry (@{$self->{defaults}}) {
        my ($name, $value) = split /=/, $entry;
        next if $skip{$name};
        $rc .= "--$entry\n";
    }
    print $rc;
    #for my $field (sort keys %config) {
    #    if (defined $config{$field}) {
    #        $rc .= "$field=$config{$field}\n";
    #    } else {
    #        $rc .= "$field\n";
    #    }
    #}

    my $code = $self->{text}->get("0.0", 'end');
    my $clean;
    my $stderr;

    my $error = Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$clean,
        stderr      => \$stderr,
        perltidyrc  => \$rc,
    );
    $self->{text}->delete("0.0", 'end');
    $self->{text}->insert("0.0", $clean);
}

sub show_about {
    my ($self) = @_;

    my $dialog = $self->{top}->DialogBox(
        -title   => 'About App::PerlTidy::Tk',
        -popover => $self->{top},
        -buttons => ['OK'],
    );

    my $html = $dialog->HyperText();
    $html->pack;
    $html->setHandler (Resource => \&onResource);
    $html->loadString(qq{<html>
      <head>
      <title>About App::PerlTidy::Tk</title>
      </head>
      <body>
         Version: $VERSION<br>
         &nbsp;<a href="https://metacpan.org/pod/Tk">Perl Tk</a>: $Tk::VERSION<br>
         <a href="https://metacpan.org/pod/Perl::Tidy">Perl::Tidy</a>: $Perl::Tidy::VERSION<br>
         Perl $]<br>
         <p>
         Create by Gabor Szabo<br>
         Source code on <a href="https://github.com/szabgab/App-PerlTidy-Tk">GitHub</a><br>
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

sub exit_app {
    my ($self) = @_;

    print("TODO: save changes before exit? Same when user click on x\n");
    exit;
}

1;
