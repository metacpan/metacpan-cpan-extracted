package App::CLI::Command::Help;
use strict;
use warnings;
use base qw/App::CLI::Command/;
use File::Find qw(find);
use Locale::Maketext::Simple;
use Pod::Simple::Text;

=head1 NAME

App::CLI::Command::Help

=head1 SYNOPSIS

    package MyApp::Help;
    use base qw(App::CLI::Command::Help);

    sub run {
        my ($self, @args) = @_;
        # preprocess
        $self->SUPER(@_);       # App::CLI::Command::Help would output PODs of each command
    }

=head1 DESCRIPTION

Your command class should be capitalized.

To add help message , you just add pod in command class:

    package YourApp::Command::Foo;


    =head1 NAME

    YourApp::Command::Foo - execute foo

    =head1 DESCRIPTION

    blah blah

    =head1 USAGE

    ....

    =cut

=cut

sub run {
    my $self = shift;
    my @topics = @_;

    push @topics, 'commands' unless (@topics);

    foreach my $topic (@topics) {
        if ($topic eq 'commands') {
            $self->brief_usage ($_) for $self->app->files;
        }
        elsif (my $cmd = eval { $self->app->get_cmd ($topic) }) {
            $cmd->usage(1);
        }
        elsif (my $file = $self->_find_topic($topic)) {
            open my $fh, '<:utf8', $file or die $!;
            require Pod::Simple::Text;
            my $parser = Pod::Simple::Text->new;
            my $buf;
            $parser->output_string(\$buf);
            $parser->parse_file($fh);

            $buf =~ s/^NAME\s+(.*?)::Help::\S+ - (.+)\s+DESCRIPTION/    $2:/;
            print $self->loc_text($buf);
        }
        else {
            die loc("Cannot find help topic '%1'.\n", $topic);
        }
    }
    return;
}

sub help_base {
    my $self = shift;
    return $self->app."::Help";
}

my ($inc, @prefix);
sub _find_topic {
    my ($self, $topic) = @_;

    if (!$inc) {
        my $pkg = __PACKAGE__;
        $pkg =~ s{::}{/};
        $inc = substr( __FILE__, 0, -length("$pkg.pm") );

        my $base = $self->help_base;
        @prefix = (loc($base));
        $prefix[0] =~ s{::}{/}g;
        $base =~ s{::}{/}g;
        push @prefix, $base if $prefix[0] ne $base;
    }

    foreach my $dir ($inc, @INC) {
        foreach my $prefix (@prefix) {
            foreach my $basename (ucfirst(lc($topic)), uc($topic)) {
                foreach my $ext ('pod', 'pm') {
                    my $file = "$dir/$prefix/$basename.$ext";
                    return $file if -f $file;
                }
            }
        }
    }

    return;
}

1;
