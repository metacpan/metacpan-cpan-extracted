package App::rmhere;

our $DATE = '2017-07-07'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;
#use experimental 'smartmatch';
use Log::ger;

use File::chdir;

# for testing
use Time::HiRes qw(sleep);

#require Exporter;
#our @ISA       = qw(Exporter);
#our @EXPORT_OK = qw(rmhere);

our %SPEC;

$SPEC{rmhere} = {
    v             => 1.1,
    summary       => 'Delete files in current directory',
    args          => {
        estimate => {
            summary => 'Count files first before start deleting',
            schema  => 'bool*',
            description => <<'_',

With this opotion, the program will do an `opendir` and list the directory
first. This can take several minutes if the directory is large, so the program
will not start deleting after several minutes. But with this option, we know how
many files we want to delete, so the progress report will know when to reach
100%.

_
        },
        here => {
            summary => 'Override current directory',
            schema  => 'str*',
        },
        interactive => {
            summary => 'Whether to ask first before deleting each file',
            schema  => [bool => default=>1],
            cmdline_aliases => {
                i => {},
                force => {
                    summary => 'Equivalent to --nointeractive',
                    code => sub { shift->{interactive} = 0 },
                },
                f => {
                    summary => 'Equivalent to --nointeractive',
                    code => sub { shift->{interactive} = 0 },
                },
            },
        },
        progress => {
            summary => 'Show progress report',
            schema  => 'bool*',
            cmdline_aliases => {
                p => {},
                P => {
                    summary => 'Equivalent to --progress --estimate',
                    code => sub {
                        my $args = shift;
                        $args->{progress} = 1;
                        $args->{estimate} = 1;
                    },
                },
            },
        },
        # TODO: match option
        # TODO: dir option
        # TODO: recursive option
    },
    features => {
        progress => 1,
        dry_run  => 1,
    },
};
sub rmhere {
    my %args = @_;

    my $progress    = $args{-progress};
    my $dry_run     = $args{-dry_run};
    my $interactive = $args{interactive};

    # avoid output becomes too crowded/jumbled
    undef($progress) if $interactive;

    # by default we don't show progress, for performance
    undef($progress) unless $args{progress};

    local $CWD = $args{here} if defined $args{here};

    opendir my($dh), "." or return [500, "Can't opendir: $!"];
    my $get_next_file = sub {
        while (defined(my $e = readdir($dh))) {
            next if $e eq '.' || $e eq '..';
            next if (-d $e);
            return $e;
        }
        return undef;
    };
    my $files;
    my $num_files;

    $progress->pos(0) if $progress;
    if ($args{estimate}) {
        $files = [];
        while (defined(my $e = $get_next_file->())) {
            push @$files, $e;
        }
        $num_files = @$files;
        $progress->target($num_files) if $progress;
    } else {
        $progress->target(undef) if $progress;
    }

    my $i = 0;
  ENTRY:
    while (defined(my $e = $files ? shift(@$files) : $get_next_file->())) {
        $i++;
        if ($interactive) {
            while (1) {
                print "Delete $e (y/n)? ";
                my $ans = <STDIN>;
                if ($ans =~ /^[Nn]$/) {
                    next ENTRY;
                } elsif ($ans =~ /^[Yy]$/) {
                    last;
                } else {
                    print "Invalid answer. ";
                }
            }
        }
        if ($dry_run) {
            log_info("DRY_RUN: Deleting $e ...");
            next;
        } else {
            unlink($e);
        }

        if ($progress) {
            $progress->update(
                message => "Deleted $i files".
                    ($files ? " (out of $num_files)" : ""));
        }
    }
    $progress->finish if $progress;
    [200, "OK"];
}

1;
# ABSTRACT: Delete files in current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::rmhere - Delete files in current directory

=head1 VERSION

This document describes version 0.08 of App::rmhere (from Perl distribution App-rmhere), released on 2017-07-07.

=head1 SYNOPSIS

See L<rmhere> script.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 rmhere

Usage:

 rmhere(%args) -> [status, msg, result, meta]

Delete files in current directory.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<estimate> => I<bool>

Count files first before start deleting.

With this opotion, the program will do an C<opendir> and list the directory
first. This can take several minutes if the directory is large, so the program
will not start deleting after several minutes. But with this option, we know how
many files we want to delete, so the progress report will know when to reach
100%.

=item * B<here> => I<str>

Override current directory.

=item * B<interactive> => I<bool> (default: 1)

Whether to ask first before deleting each file.

=item * B<progress> => I<bool>

Show progress report.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-rmhere>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-rmhere>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-rmhere>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
