package App::finddo;

our $DATE = '2017-08-16'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Fcntl ':mode';

our %SPEC;

sub _get_ext_re_from_mime_types_file {
    my $type_re = shift;

    my %exts;
    open my $fh, "<", "/etc/mime.types"
        or die "finddo: Can't open /etc/mime.types: $!\n";
    while (<$fh>) {
        next unless /\S/;
        next if /^\s*#/;
        my ($type, $exts) = m!(\S+)\s+(\w.*)! or next;
        next unless $type =~ $type_re;
        while ($exts =~ /(\w+)/g) { $exts{$1}++ }
    }
    close $fh;
    my $re = join("|", sort keys %exts);
    qr/\.(?:$re)\z/i;
}

$SPEC{finddo} = {
    v => 1.1,
    summary => 'Search for files and run command',
    'description.alt.env.cmdline' => <<'_',

*EARLY RELEASE, MANY FEATURES ARE NOT YET IMPLEMENTED OR DEFINED.*

The *finddo* utility is a convenient alternative for the Unix *find* command,
for the more specific purpose of running a command with the matching files as
arguments. It provides convenience options such as `--largest`, `--newest`, or
`--media`, `--audio`, `--video`, or `-n`. So to play the 3 newest songs, instead
of doing:

    ls --sort=t *.mp3 *.m4a *.flac *.ogg 2>/dev/null | head -n3 | xargs mpv --

and still be tripped by quoting of problematic filenames, you can just say:

    finddo --newest --audio -n3 -- mpv --

_
    'description.alt.env.perl' => <<'_',

Aside from used on the command-line, *finddo* can also be used as a function
from Perl. For example:

    my @files = finddo(newest=>1, audio=>1, max_result=>3);

    finddo(newest=>1, audio=>1, max_result=>3, command=>["mpv", "--"]);

_
    args => {
        command => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
        },

        exists => {
            schema => 'bool*',
        },

        files => {
            schema => 'bool*',
            cmdline_aliases => {
                f => {summary => 'Shortcut for --files'   , code=>sub {$_[0]{files} = 1}},
                F => {summary => 'Shortcut for --no-files', code=>sub {$_[0]{files} = 0}},
            },
        },
        dirs => {
            schema => 'bool*',
            cmdline_aliases => {
                d => {summary => 'Shortcut for --dirs'   , code=>sub {$_[0]{dirs} = 1}},
                D => {summary => 'Shortcut for --no-dirs', code=>sub {$_[0]{dirs} = 0}},
            },
        },

        smallest => {
            schema => 'bool*',
        },
        largest => {
            schema => 'bool*',
        },
        oldest => {
            schema => 'bool*',
        },
        newest => {
            schema => 'bool*',
        },
        sort => {
            schema => ['str*', in=>[qw/mtime -mtime size -size name -name/]],
        },

        max_result => {
            schema => 'int*',
            cmdline_aliases => {n=>{}},
        },

        media => {
            schema => 'bool*',
        },
        audio => {
            schema => 'bool*',
        },
        video => {
            schema => 'bool*',
        },
        image => {
            schema => 'bool*',
        },
        # XXX add arg: doc/ebook, backup, compressed, archive

        # XXX add arg: recursive (-r)
        # XXX add arg: max_depth
        # XXX add arg: (mtime, ctime) (min, max)
        # XXX add arg: size (min, max)
    },
    args_rels => {
        'choose_one&' => [
            [qw/sort newest oldest smallest largest/],
            [qw/files dirs/],
            [qw/media audio video image/],
        ],
    },
    result_naked => 1,
    links => [
        {url=>'prog:find', summary => 'Unix command'},
    ],
};
sub finddo {
    my %args = @_;

    my $max_result = $args{max_result};
    if ($args{newest} || $args{oldest} || $args{largest} || $args{smallest}) {
        $max_result = 1 unless defined $max_result;
    }
    $max_result = -1 unless defined $max_result;

    my $re_ext;
    my $ext_cond;
    if (defined $args{media}) {
        $ext_cond = $args{media};
        $re_ext = _get_ext_re_from_mime_types_file(qr!^(?:audio|video|image)/!);
    } elsif (defined $args{audio}) {
        $ext_cond = $args{audio};
        $re_ext = _get_ext_re_from_mime_types_file(qr!^(?:audio)/!);
    } elsif (defined $args{video}) {
        $ext_cond = $args{video};
        $re_ext = _get_ext_re_from_mime_types_file(qr!^(?:video)/!);
    } elsif (defined $args{image}) {
        $ext_cond = $args{image};
        $re_ext = _get_ext_re_from_mime_types_file(qr!^(?:image)/!);
    }

    my @res;
  FIND:
    {
        opendir my $dh, "." or do {
            warn "finddo: Can't opendir: $!\n";
            last FIND;
        };
        my @entries = readdir $dh;
        closedir $dh;

      ENTRY:
        for my $entry (@entries) {
            next if $entry eq '.' || $entry eq '..';
            my @lst = lstat $entry;
            my @st  = $lst[2] & S_IFLNK ? stat($entry) : @lst;

            if (defined $args{exists}) {
                next ENTRY if $args{exists} xor @st;
            }
            if (defined $args{files}) {
                next ENTRY unless @st;
                next ENTRY if $st[2] & S_IFREG xor $args{files};
            }
            if (defined $args{dirs}) {
                next ENTRY unless @st;
                next ENTRY if $st[2] & S_IFDIR xor $args{dirs};
            }
            if ($re_ext) {
                my $match = $entry =~ $re_ext;
                $match = !$match unless $ext_cond;
                next ENTRY unless $match;
            }
            push @res, {name=>$entry, stat=>\@st};
        }

      SORT:
        {
            my $sort = $args{sort};
            if    ($sort)           { }
            elsif ($args{newest})   { $sort = "-mtime" }
            elsif ($args{oldest})   { $sort =  "mtime" }
            elsif ($args{largest})  { $sort = "-size"  }
            elsif ($args{smallest}) { $sort =  "size"  }
            last unless $sort;

            my $sortsub;
            if    ($sort eq   'name') { $sortsub = sub { $a->{name} cmp $b->{name} } }
            elsif ($sort eq  '-name') { $sortsub = sub { $b->{name} cmp $a->{name} } }
            elsif ($sort eq  'mtime') { $sortsub = sub { ($a->{stat}[9]||0) <=> ($b->{stat}[9]||0) } }
            elsif ($sort eq '-mtime') { $sortsub = sub { ($b->{stat}[9]||0) <=> ($a->{stat}[9]||0) } }
            elsif ($sort eq   'size') { $sortsub = sub { ($a->{stat}[7]||0) <=> ($b->{stat}[7]||0) } }
            elsif ($sort eq  '-size') { $sortsub = sub { ($b->{stat}[7]||0) <=> ($a->{stat}[7]||0) } }

            @res = sort $sortsub @res;
        }

        @res = map {$_->{name}} @res;

      LIMIT:
        {
            last unless $max_result >= 0;
            if (@res > $max_result) {
                splice @res, $max_result;
            }
        }

    }

    if ($args{command} && @{$args{command}}) {
        if (@res) {
            system {$args{command}[0]} @{$args{command}}, @res;
            exit $?;
        } else {
            warn "finddo: No matching files\n";
            exit 1;
        }
    } else {
        return \@res;
    }
}

1;
# ABSTRACT: Search for files and run command

__END__

=pod

=encoding UTF-8

=head1 NAME

App::finddo - Search for files and run command

=head1 VERSION

This document describes version 0.002 of App::finddo (from Perl distribution App-finddo), released on 2017-08-16.

=head1 DESCRIPTION

See included script L<finddo>.

=head1 FUNCTIONS


=head2 finddo

Usage:

 finddo(%args) -> any

Search for files and run command.

Aside from used on the command-line, I<finddo> can also be used as a function
from Perl. For example:

 my @files = finddo(newest=>1, audio=>1, max_result=>3);
 
 finddo(newest=>1, audio=>1, max_result=>3, command=>["mpv", "--"]);

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<audio> => I<bool>

=item * B<command> => I<array[str]>

=item * B<dirs> => I<bool>

=item * B<exists> => I<bool>

=item * B<files> => I<bool>

=item * B<image> => I<bool>

=item * B<largest> => I<bool>

=item * B<max_result> => I<int>

=item * B<media> => I<bool>

=item * B<newest> => I<bool>

=item * B<oldest> => I<bool>

=item * B<smallest> => I<bool>

=item * B<sort> => I<str>

=item * B<video> => I<bool>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-finddo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-finddo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-finddo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<find>. Unix command.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
