package App::PerlTidy::Tk;
use strict;
use warnings;
use 5.008;

use Browser::Open qw(open_browser open_browser_cmd);
use Cwd qw(getcwd);
use Cpanel::JSON::XS qw(encode_json decode_json);
use Data::Dumper qw(Dumper);
use File::HomeDir ();
use File::Spec ();
use Path::Tiny qw(path);
use Getopt::Long qw(GetOptions);
use Perl::Tidy;

use Tk;
use Tk::Dialog;
use Tk::FileSelect;
use Tk::HyperText;
use Tk::Table;

our $VERSION = '0.02';

my $zoom = 3;
my %skip = map { $_ => 1 } qw(nocheck-syntax perl-syntax-check-flags);
my $home = File::HomeDir->my_home;
my $config_file = File::Spec->catfile($home, '.perltidy-tk.json');
my @options = ('indent-columns', 'paren-tightness', 'brace-tightness', 'block-brace-tightness');

sub usage {
    die "Usage: $0 [--help] [--perl somefile.pl]\n";
}

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    my $perlfile;
    my $help;
    GetOptions(
        'perl=s' => \$perlfile,
        'help'   => \$help,
    ) or usage();
    usage() if $help;

    my $config = {};
    if (-e $config_file) {
        $config = decode_json(path($config_file)->slurp_utf8);
    }

    $self->{autotidy} = 0;

    $self->load_default_configuration;

    $self->{top} = MainWindow->new();
    if (exists $config->{geometry}) {
        $self->{top}->geometry($config->{geometry});
    }

    $self->{top}->bind("<Control-Shift-plus>", sub { $self->zoom($zoom) });
    $self->{top}->bind("<Control-minus>", sub { $self->zoom(-$zoom) });
    $self->{top}->bind("<Control-q>", sub { $self->exit_app(); });

    $self->create_menu;
    $self->create_text_widget;
    $self->create_config_panel;

    if ($perlfile) {
        $self->load_perl_file($perlfile);
    }

    return $self;
}

sub run {
    my ($self) = @_;
    MainLoop;
}

sub load_default_configuration {
    my ($self) = @_;

    my ($option_string, $defaults, $expansion, $category, $option_range) = Perl::Tidy::generate_options();
    #print Dumper $option_range;
    $option_range->{'indent-columns'} ||= [1, 8];
    $self->{range} = $option_range;
    #$self->{defaults} = $defaults;
    $self->{config} = {}; # options that have a value
    $self->{flags} = {}; # options that only have presence
    $self->{widgets} = {};
    #print Dumper $option_string;
    for my $def (sort @$defaults) {
        my ($name, $value) = split /=/, $def;
        #print "$name\n";
        next if $skip{$name};
        if (defined $value) {
            #print "   $value\n";
            $self->{config}{$name} = $value;
        } else {
            $self->{flags}{$name} = 1;
        }
    }
}


sub create_menu {
    my ($self) = @_;

    my $main_menu = $self->{top}->Menu();

    my $file_menu = $main_menu->cascade(-label => 'File', -underline => 0);
    $file_menu->command(-label => 'Open Perl File', -command => sub { $self->show_open(); }, -underline => 0);
    #$file_menu->command(-label => 'Load Config', -command => sub { $self->load_config(); }, -underline => 0);
    $file_menu->command(-label => 'Save Config', -command => sub { $self->save_config(); }, -underline => 0);
    $file_menu->command(-label => 'Quit (Ctrl-q)', -command => sub { $self->exit_app(); }, -underline => 0);

    my $action_menu = $main_menu->cascade(-label => 'Action', -underline => 0);
    $action_menu->command(-label => 'Tidy', -command => sub { $self->run_tidy; });
    $action_menu->command(-label => 'Zoom in (Ctrl-Shift-+)', -command => sub { $self->zoom($zoom); });
    $action_menu->command(-label => 'Zoom Out (Ctrl--)', -command => sub { $self->zoom(-$zoom); });
    $action_menu->checkbutton(-label => 'Autotidy', -variable => \$self->{autotidy});

    my $about_menu = $main_menu->cascade(-label => 'Help', -underline => 0);
    $about_menu->command(-label => 'About', -command => sub { $self->show_about; }, -underline => 0);

    $self->{top}->configure(-menu => $main_menu);
}

sub save_config {
    my ($self) = @_;

    my $start_dir = getcwd();
    my $file_selector = $self->{top}->FileSelect(-directory => $start_dir);
    my $filename = $file_selector->Show;
    if (-e $filename) {
        my $dialog = $self->{top}->Dialog(
            -title   => 'Overwrite?',
            -text    => "The file $filename already exists. Overwrite?",
            -popover => $self->{top},
            -buttons => ['Yes', 'No'],
        );
        my $res = $dialog->Show;
        return if $res ne 'Yes';
    }
    my $rc = $self->get_rc();
    if (open my $fh, '>', $filename) {
        my $localtime = scalar localtime;
        print $fh "# Saved by App::PerlTidy::Tk on $localtime\n\n";
        print $fh $rc;
    } else {
        my $dialog = $self->{top}->Dialog(
            -title   => 'Error',
            -text    => "Could not write to file. $!",
            -popover => $self->{top},
            -buttons => ['OK'],
        );
    }
}

sub load_config {
    my ($self) = @_;
}

sub zoom {
    my ($self, $number) = @_;
    my $font_info = $self->{text}->configure('-font');
    #print "${$font_info->[4]}\n";  # 'fixed 20';
    my ($font, $size) = split / /, ${$font_info->[4]};
    $size += $number;
    $self->{text}->configure(-font => ['fixed', $size]);
}

sub create_config_panel {
    my ($self) = @_;

    $self->{table}  = $self->{top}->Table(-columns => 2, -rows => 1, -fixedrows => 1, -scrollbars => '');
    $self->{table}->pack(-expand=> 1, -fill => 'both');

    my $row = -1;

    #my $name = 'line-up-parentheses';
    #print $self->{flags}{$name}, "\n";
    #my $cb = $self->{top}->Checkbutton(
    #    -text     => $name,
    #    -variable => \$self->{flags}{$name},
    #    -font     => ['fixed', 10]
    #);
    #$cb->pack(-side => 'left');

    for my $name (@options) {
        $row++;
        my $label = $self->{table}->Label(
            -text     => $name,
        );
        $self->{table}->put($row, 0, $label);

        my $cb = $self->{table}->Optionmenu(
            -variable => \$self->{config}{$name},
            -options  => [$self->{range}{$name}[0] .. $self->{range}{$name}[1]],
            -command => sub { $self->config_changed },
        );
        $self->{table}->put($row, 1, $cb);
        $self->{widgets}{$name} = $cb;
    }
}

sub config_changed {
    my ($self) = @_;

    if ($self->{autotidy}) {
        $self->run_tidy;
    }
}


sub update_config {
    my ($self) = @_;
    #my $name = 'indent-columns';
    #$self->{config}{$name} = $self->{widgets}{$name}->get;
}

sub create_text_widget {
    my ($self) = @_;

    $self->{text} = $self->{top}->Text(
        -state => 'normal',
        -font => ['fixed', 12],
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

sub get_rc {
    my ($self) = @_;

    $self->update_config;

    my $rc = '';
    while (my ($name, $value) = each %{$self->{config}}) {
        $rc .= "--$name=$value\n";
    }
    for my $name (keys %{$self->{flags}}) {
        $rc .= "--$name\n";
    }
    #print $rc;
    return $rc;
}

sub run_tidy {
    my ($self) = @_;
    #print Dumper \%skip;
    #
    my $rc = $self->get_rc();

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

    # Save current window size so we can start the same size next time.
    my %config = (
        'geometry' => $self->{top}->geometry,
    );
    path($config_file)->spew(encode_json(\%config));

    print("TODO: save changes before exit? Same when user click on x\n");
    exit;
}

1;

=head1 NAME

App::PerlTidy::Tk - Tk based GUI to experiment with PerlTidy configuration options

=head1 SYNOPSIS

    perltidy-tk
    perltidy-tk --perl path/to/some.pl

=head1 DESCRIPTION

This is a GUI program. There are some videos on L<Perl Maven Tk|https://perlmaven.com/tk> explaining
how does this work and how was this built.

When the application exits we save the current window size in the config file and next time we use that size to open the application.

    ~/.perltidy-tk.json

=head1 SEE ALSO

L<Perl::Tidy>

L<Tk>

L<Tk::HyperText>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by L<Gabor Szabo|https://szabgab.com/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

