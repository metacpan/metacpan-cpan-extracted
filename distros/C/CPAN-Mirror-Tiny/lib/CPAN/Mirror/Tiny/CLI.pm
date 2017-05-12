package CPAN::Mirror::Tiny::CLI;
use strict;
use warnings;
use CPAN::Mirror::Tiny;
use File::Find ();
use File::Spec;
use File::stat ();
use Getopt::Long ();
use HTTP::Tinyish;
use POSIX ();
use Pod::Usage 1.33 ();

sub new {
    my $class = shift;
    bless {
        base => $ENV{PERL_CPAN_MIRROR_TINY_BASE} || "darkpan",
        http => HTTP::Tinyish->new(agent => "CPAN::Mirror::Tiny/$CPAN::Mirror::Tiny::VERSION"),
    }, $class;
}

sub run {
    shift->_run(@_) ? 0 : 1;
}

sub _run {
    my $self = shift->new;
    $self->parse_options(@_) or return;

    my $cmd = shift @{$self->{argv}};
    if (!$cmd) {
        warn "Missing subcommand, try `$0 --help`\n";
        return;
    }

    ( my $_cmd = $cmd ) =~ s/-/_/g;
    if (my $sub = $self->can("cmd_$_cmd")) {
        return $self->$sub(@{$self->{argv}});
    } else {
        warn "Unknown subcommand '$cmd', try `$0 --help`\n";
        return;
    }

}

sub parse_options {
    my $self = shift;
    local @ARGV = @_;
    my $parser = Getopt::Long::Parser->new(
        config => [qw(no_auto_abbrev no_ignore_case pass_through)],
    );
    $parser->getoptions(
        "h|help" => sub { $self->cmd_help; exit },
        "v|version" => sub { $self->cmd_version; exit },
        "q|quiet" => \$self->{quiet},
        "b|base=s" => \$self->{base},
        "a|author=s" => \$self->{author},
    ) or return 0;
    $self->{argv} = \@ARGV;
    return 1;
}

sub cmd_help {
    Pod::Usage::pod2usage(verbose => 99, sections => 'SYNOPSIS|OPTIONS|EXAMPLES');
    return 1;
}

sub cmd_version {
    my $klass = "CPAN::Mirror::Tiny";
    printf "%s %s\n", $klass, $klass->VERSION;
}

sub cmd_inject {
    my ($self, @argv) = @_;
    die "Missing urls, try `$0 --help`\n" unless @argv;
    my $cpan = CPAN::Mirror::Tiny->new(base => $self->{base});
    my $option = $self->{author} ? { author => $self->{author} } : +{};
    for my $argv (@argv) {
        print STDERR "Injecting $argv" unless $self->{quiet};
        if (eval { $cpan->inject($argv, $option); 1 }) {
            print STDERR " DONE\n" unless $self->{quiet};
        } else {
            print STDERR " FAIL\n" unless $self->{quiet};
            die $@;
        }
    }
    return 1;
}

sub cmd_gen_index {
    my ($self, @argv) = @_;
    my $cpan = CPAN::Mirror::Tiny->new(base => $self->{base});
    print STDERR "Generating index for $self->{base}" unless $self->{quiet};
    $cpan->write_index(compress => 1);
    print STDERR " DONE\n" unless $self->{quiet};
    return 1;
}

sub cmd_cat_index {
    my ($self, @argv) = @_;
    my $index = File::Spec->catfile($self->{base}, "modules", "02packages.details.txt.gz");
    return unless -f $index;
    return !system "gzip", "--decompress", "--stdout", $index;
}

sub cmd_list {
    my $self = shift;
    return unless -d $self->{base};
    my ($index, @dist);
    my $wanted = sub {
        my $name = $_;
        return if !-f $name or $name =~ /\.json$/;
        my $stat = File::stat::stat($name);
        if ($name =~ /02packages.details.txt.gz$/) {
            $index = {name => $name, mtime => $stat->mtime, size => $stat->size};
        } else {
            push @dist, {name => $name, mtime => $stat->mtime, size => $stat->size};
        }
    };
    File::Find::find({wanted => $wanted, no_chdir => 1}, $self->{base});

    my $print = sub {
        printf "%s %4dKB %s\n",
            POSIX::strftime("%FT%T", localtime($_[0]->{mtime})),
            $_[0]->{size} / 1024,
            $_[0]->{name};
    };
    $print->($index) if $index;
    for my $dist (sort { $a->{name} cmp $b->{name} } @dist) {
        $print->($dist);
    }
    return 1;
}

sub cmd_server {
    my $self = shift;
    if (!eval { require CPAN::Mirror::Tiny::Server }) {
        if ($@ =~ m{Can't locate Plack}) {
            die "To run server, you should install Plack first.\n";
        } else {
            die $@;
        }
    }
    CPAN::Mirror::Tiny::Server->start(@{$self->{argv}}, $self->{base});
    return 1;
}

1;
