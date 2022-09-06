package App::tldr;
use strict;
use warnings;
use Encode ();
use File::Spec;
use File::Which ();
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use HTTP::Tiny;
use IO::Handle;
use IO::Socket::SSL;
use Pod::Usage 1.33 ();
use Term::ReadKey ();
use Text::Fold ();

use constant DEBUG => $ENV{TLDR_DEBUG};
use constant REPOSITORY => $ENV{TLDR_REPOSITORY};

our $VERSION = '0.13';

my $URL = "https://raw.githubusercontent.com/tldr-pages/tldr/main/pages%s/%s/%s.md";

sub new {
    my ($class, %option) = @_;
    my $http = HTTP::Tiny->new;
    bless { http => $http, %option }, $class;
}

sub parse_options {
    my ($self, @argv) = @_;
    local @ARGV = @argv;
    $self->{platform} = [];

    $self->{unicode} = ($ENV{LANG} || "") =~ /UTF-8/i ? 1 : 0;
    GetOptions
        "h|help"       => sub { print $self->_help; exit },
        "l|language=s" => \my $language,
        "o|os=s@"      => \($self->{platform}),
        "v|version"    => sub { printf "%s %s\n", ref $self, $self->VERSION; exit },
        "pager=s"      => \my $pager,
        "no-pager"     => \my $no_pager,
        "unicode!"     => \$self->{unicode},
    or exit(2);
    $self->{argv} = \@ARGV;
    if ($language) {
        $language = $language =~ /^\./ ? $language : ".$language";
    }
    $self->{language} = $language || '';
    if (!$no_pager and -t STDOUT and my $guess = $self->_guess_pager($pager)) {
        $self->{pager} = $guess;
    }
    push @{$self->{platform}}, $self->_guess_platform, "common";
    $self;
}

sub _guess_pager {
    my $self = shift;

    my $cmd;
    for my $try (grep $_, @_, $ENV{PAGER}, "less", "more") {
        if (my $found = File::Which::which($try)) {
            $cmd = $found, last;
        }
    }
    return if !$cmd;
    [$cmd, $cmd =~ /\bless$/ ? "-R" : ()];
}

sub _help {
    my ($self, $exit) = @_;
    open my $fh, '>', \my $out;
    Pod::Usage::pod2usage
        exitval => 'noexit',
        input => $0,
        output => $fh,
        sections => 'SYNOPSIS',
        verbose => 99,
    ;
    $out =~ s/^Usage:\n//;
    $out =~ s/^[ ]{6}//mg;
    $out =~ s/\n$//;
    $out;
}


# XXX
sub _guess_platform {
    $^O =~ /darwin/i ? "osx"   :
    $^O =~ /linux/i  ? "linux" :
    $^O =~ /sunos/i  ? "sunos" : ();
}

sub _get {
    my $self = shift;
    if (REPOSITORY) {
        $self->_local_get(@_);
    } else {
        $self->_http_get(@_);
    }
}

sub _http_get {
    my ($self, $query, $platform) = @_;
    my $url = sprintf $URL, $self->{language}, $platform, $query;
    my $res = $self->{http}->get($url);
    if ($res->{success}) {
        (Encode::decode_utf8($res->{content}), undef);
    } else {
        (undef, "$url: $res->{status} $res->{reason}");
    }
}

sub _local_get {
    my ($self, $query, $platform) = @_;
    my $file = File::Spec->catfile(REPOSITORY, "pages$self->{language}", $platform, "$query.md");
    if (-f $file) {
        open my $fh, "<:utf8", $file or die "$file: $!";
        local $/;
        (<$fh>, undef);
    } else {
        (undef, "Missing $file");
    }
}

sub run {
    my $self = shift;
    my $arg  = shift @{$self->{argv}} or die $self->_help(1);
    my $content;
    for my $platform (@{ $self->{platform} }) {
        ($content, my $err) = $self->_get($arg, $platform);
        if ($content) {
            last;
        } elsif (DEBUG) {
            warn "-> $err\n";
        }
    }
    die "Couldn't find tldr for '$arg'\n" unless $content;
    $self->_render($content, $arg);
}

my $CHECK = "\N{U+2713}";
my $SUSHI = "\N{U+1F363}";

sub _render {
    my ($self, $content, $query) = @_;

    my ($check, $prompt) = $self->{unicode} ? ($CHECK, $SUSHI) : ('*', '$');

    my $width = $ENV{COLUMNS} || (Term::ReadKey::GetTerminalSize())[0];
    $width -= 4;

    my @line = split /\n/, $content;

    my $out;
    if ($self->{pager}) {
        open $out, "|-", @{$self->{pager}} or die "failed to exec @{$self->{pager}}: $!";
    } else {
        $out = \*STDOUT;
    }
    binmode $out, ":utf8";

    while (defined(my $line = shift @line)) {
        if ($line =~ /^#/) {
            # skip
        } elsif ($line =~ s/^\>\s*//) {
            my $description = $line;
            while (1) {
                my $next = shift @line;
                if ($next eq "") {
                    next;
                } elsif ($next =~ s/^\>\s*//) {
                    $description .= "\n$next";
                } else {
                    unshift @line, $next;
                    last;
                }
            }
            my $fold = Text::Fold::fold_text($description, $width);
            $out->print("\n");
            $out->print("  \e[32m$_\e[m\n") for split /\n/, $fold;
            $out->print("\n");
        } elsif ($line =~ s/^[*-]\s*//) {
            my $fold = Text::Fold::fold_text($line, $width - 2);
            my ($first, @rest) = split /\n/, $fold;
            $out->print("  \e[1m$check \e[4m$first\e[m\n");
            $out->print("    \e[1m\e[4m$_\e[m\n") for @rest;
            $out->print("\n");
        } elsif ($line =~ /`([^`]+)`/) {
            my $code = $1;
            $code =~ s/\b$query\b/
              "\e[32m$query\e[m"
            /eg;
            $out->print("    $prompt $code\n\n");
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::tldr - a perl client for https://tldr.sh/

=head1 SYNOPSIS

  $ tldr tar

=head1 DESCRIPTION

App::tldr is a client for L<https://tldr.sh/>.

=head1 SEE ALSO

L<https://github.com/tldr-pages/tldr>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
