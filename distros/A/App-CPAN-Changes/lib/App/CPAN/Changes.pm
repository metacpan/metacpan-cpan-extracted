package App::CPAN::Changes;

our $DATE = '2017-07-14'; # DATE
our $VERSION = '0.003'; # VERSION

#use 5.010001;
use strict;
use warnings;

use Fcntl qw(:DEFAULT);
use POSIX qw(strftime);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI for CPAN::Changes',
};

sub _parse {
    my ($file) = @_;

    if (!$file) {
	for (qw/Changes CHANGES ChangeLog CHANGELOG/) {
	    do { $file = $_; last } if -f $_;
	}
    }
    die "Please specify file ".
        "(or run in directory where Changes file exists)"
        unless $file;

    require CPAN::Changes;
    ($file, CPAN::Changes->load($file));
}

my %common_args = (
    file => {
        schema => 'str*', # XXX filename
        summary => 'If not specified, will look for file called '.
            'Changes/CHANGELOG/etc in current directory',
        cmdline_aliases => {f=>{}},
        tags => ['common'],
    },
);

$SPEC{check} = {
    v => 1.1,
    summary => 'Check for parsing errors in Changes file',
    args => {
        %common_args,
    },
};
sub check {
    my %args = @_;

    my ($file, $ch) = _parse($args{file});
    my @rels = $ch->releases;
    return [400, "No releases found"] unless @rels;

    [200, "OK"];
}

$SPEC{dump} = {
    v => 1.1,
    summary => 'Dump Changes as JSON structure',
    args => {
        %common_args,
    },
};
sub dump {
    my %args = @_;

    my ($file, $ch) = _parse($args{file});

    [200, "OK", $ch];
}

sub _serialize {
    my ($ch, $reverse) = @_;

    $ch->serialize(reverse => $reverse);
}

sub _write {
    my ($file, $ch, $reverse) = @_;

    my $tempfile = sprintf("%s.%05d.tmp", $file, rand()*65536);
    sysopen my($fh), $tempfile, O_WRONLY|O_CREAT|O_EXCL
        or die "Can't open temp file '$tempfile': $!";
    print $fh _serialize($ch, $reverse);
    rename $file, "$file.bak"
        or die "Can't move '$file' to '$file.bak': $!";
    rename $tempfile, $file
        or die "Can't move '$tempfile' to '$file': $!";
}

$SPEC{preamble} = {
    v => 1.1,
    summary => 'Get/set preamble',
    tags => ['write'],
    args => {
        %common_args,
        preamble => {
            summary => 'Set new preamble',
            schema => 'str*',
            pos => 0,
        },
    },
};
sub preamble {
    my %args = @_;

    my ($file, $ch) = _parse($args{file});

    if (defined $args{preamble}) {
        $ch->preamble($args{preamble});
        _write($file, $ch);
        [200, "OK"];
    } else {
        [200, "OK", $ch->preamble];
    }
}

$SPEC{release} = {
    v => 1.1,
    summary => 'Return information (JSON object dump) of a specific release',
    args => {
        %common_args,
        version => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub release {
    my %args = @_;

    my ($file, $ch) = _parse($args{file});

    my $rel = $ch->release($args{version});

    [200, "OK", $rel];
}

$SPEC{add_release} = {
    v => 1.1,
    summary => 'Add a new release',
    tags => ['write'],
    args => {
        %common_args,
        version => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_aliases => {V=>{}},
        },
        date => {
            schema => 'date*',
            req => 1,
            pos => 1,
        },
        changes => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*', min_len=>1],
            req => 1,
            pos => 2,
            greedy => 1,
        },
        note => {
            schema => 'str*',
        },
    },
    features => {
        dry_run => 1,
    },
};
sub add_release {
    my %args = @_;

    my ($file, $ch) = _parse($args{file});

    # format to YYYY-MM-DD
    my $date = strftime("%Y-%m-%d",
                        localtime $args{date});

    my $rel = CPAN::Changes::Release->new(
        version => $args{version},
        date    => $date,
    );
    $rel->note($args{note}) if $args{note};
    my @c;
    for my $c (@{ $args{changes} }) {
        if ($c =~ /\A\[(.+)\]\z/) {
            push @c, {group => $1};
        } else {
            push @c, $c;
        }
    }
    $rel->add_changes(@c);

    $ch->add_release($rel);

    if ($args{-dry_run}) {
        return [304, "Not modified", _serialize($ch)];
    } else {
        _write($file, $ch);
        return [200, "OK"];
    }
}

1;
# ABSTRACT: CLI for CPAN::Changes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPAN::Changes - CLI for CPAN::Changes

=head1 VERSION

This document describes version 0.003 of App::CPAN::Changes (from Perl distribution App-CPAN-Changes), released on 2017-07-14.

=head1 SYNOPSIS

See included script L<cpan-changes>.

=head1 FUNCTIONS


=head2 add_release

Usage:

 add_release(%args) -> [status, msg, result, meta]

Add a new release.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<changes>* => I<array[str]>

=item * B<date>* => I<date>

=item * B<file> => I<str>

If not specified, will look for file called Changes/CHANGELOG/etc in current directory.

=item * B<note> => I<str>

=item * B<version>* => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 check

Usage:

 check(%args) -> [status, msg, result, meta]

Check for parsing errors in Changes file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

If not specified, will look for file called Changes/CHANGELOG/etc in current directory.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 dump

Usage:

 dump(%args) -> [status, msg, result, meta]

Dump Changes as JSON structure.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

If not specified, will look for file called Changes/CHANGELOG/etc in current directory.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 preamble

Usage:

 preamble(%args) -> [status, msg, result, meta]

Get/set preamble.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

If not specified, will look for file called Changes/CHANGELOG/etc in current directory.

=item * B<preamble> => I<str>

Set new preamble.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 release

Usage:

 release(%args) -> [status, msg, result, meta]

Return information (JSON object dump) of a specific release.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

If not specified, will look for file called Changes/CHANGELOG/etc in current directory.

=item * B<version>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CPAN-Changes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPAN-Changes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPAN-Changes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Changes>

L<parse-cpan-changes> (from L<App::ParseCPANChanges>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
