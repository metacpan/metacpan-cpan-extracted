package Clipboard::Any;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);
use IPC::System::Options 'system', 'readpipe', 'run', -log=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-16'; # DATE
our $DIST = 'Clipboard-Any'; # DIST
our $VERSION = '0.015'; # VERSION

our $known_clipboard_managers = [qw/klipper parcellite clipit xclip/];
our $sch_clipboard_manager = ['str', in=>$known_clipboard_managers];
our %argspecopt_clipboard_manager = (
    clipboard_manager => {
        summary => 'Explicitly set clipboard manager to use',
        schema => $sch_clipboard_manager,
        description => <<'MARKDOWN',

The default, when left undef, is to detect what clipboard manager is running.

MARKDOWN
        cmdline_aliases => {m=>{}},
    },
);

our %argspec0_index = (
    index => {
        summary => 'Index of item in history (0 means the current/latest, 1 the second latest, and so on)',
        schema => 'int*',
        description => <<'MARKDOWN',

If the index exceeds the number of items in history, empty string or undef will
be returned instead.

MARKDOWN
    },
);

our %SPEC;

sub _find_qdbus {
    require File::Which;

    my @paths;
    if (my $path = File::Which::which("qdbus")) {
        log_trace "qdbus found in PATH: $path";
        push @paths, $path;
    } else {
        for my $dir ("/usr/lib/qt6/bin", "/usr/lib/qt5/bin") {
            if ((-d $dir) && (-x "$dir/qdbus")) {
                log_trace "qdbus found in $dir";
                push @paths, "$dir/qdbus";
            }
        }
    }

    @paths;
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to clipboard manager functions',
    description => <<'MARKDOWN',

This module provides common functions related to clipboard manager.

Supported clipboard manager: KDE Plasma's Klipper (`klipper`), `parcellite`,
`clipit`, `xclip`. Support for more clipboard managers, e.g. on Windows or other
Linux desktop environment is welcome.

MARKDOWN
};

$SPEC{'detect_clipboard_manager'} = {
    v => 1.1,
    summary => 'Detect which clipboard manager program is currently running',
    description => <<'MARKDOWN',

Will return a string containing name of clipboard manager program, e.g.
`klipper`. Will return undef if no known clipboard manager is detected.

MARKDOWN
    result_naked => 1,
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    #result => {
    #    schema => $sch_clipboard_manager,
    #},
};
sub detect_clipboard_manager {
    my %args = @_;

    require File::Which;

    require Proc::Find;
    no warnings 'once';
    local $Proc::Find::CACHE = 1;

    my $info = {};
  DETECT: {

      DETECT_KLIPPER:
        {
            log_trace "Checking whether clipboard manager klipper is running ...";

          METHOD1: {
                my @paths = _find_qdbus();

                unless (@paths) {
                    log_trace "qdbus not found, checking using qdbus";
                    last;
                }

                for my $path (@paths) {
                    my $out;
                    system({capture_merged=>\$out}, $path, "org.kde.klipper", "/klipper");
                    unless ($? == 0) {
                        # note, when klipper is disabled via System Tray Settings >
                        # General > Extra Items, the object path /klipper disappears.
                        log_trace "Failed listing org.kde.klipper /klipper methods (using qdus at $path)";
                        next;
                    }
                    log_trace "org.kde.klipper/klipper object active, concluding using klipper";
                    $info->{manager} = "klipper";
                    $info->{klipper_path} = $path;
                    last DETECT;
                }
          }

          # we need qdbus anyway
          #METHOD2: {
          #      my $pids = Proc::Find::find_proc(name => "dbus-daemon");
          #      if (@$pids) {
          #          log_trace "There is dbus-daemon running, assuming we are using klipper";
          #          $info->{manager} = "klipper";
          #          last DETECT;
          #  } else {
          #      log_trace "dbus-daemon process does not seem to be running, probably not using klipper";
          #  }
          #}
        } # DETECT_KLIPPER

      DETECT_PARCELLITE:
        {
            log_trace "Checking whether clipboard manager parcellite is running ...";
            my $pids = Proc::Find::find_proc(name => "parcellite");
            if (@$pids) {
                log_trace "parcellite process is running, concluding using parcellite";
                $info->{manager} = "parcellite";
                last DETECT;
            } else {
                log_trace "parcellite process does not seem to be running, probably not using parcellite";
            }
        } # DETECT_PARCELLITE

      DETECT_CLIPIT:
        {
            # basically the same as parcellite
            log_trace "Checking whether clipboard manager clipit is running ...";
            my $pids = Proc::Find::find_proc(name => "clipit");
            if (@$pids) {
                log_trace "clipit process is running, concluding using clipit";
                $info->{manager} = "parcellite";
                last DETECT;
            } else {
                log_trace "clipit process does not seem to be running, probably not using clipit";
            }
        } # DETECT_CLIPIT

      DETECT_XCLIP:
        {
            log_trace "Checking whether xclip is available ...";
            my $path = File::Which::which("xclip");
            unless ($path) {
                log_trace "xclip not found in PATH, skipping choosing xclip";
                last;
            }
            log_trace "xclip found in PATH, concluding using xclip";
            $info->{manager} = "xclip";
            $info->{xclip_path} = $path;
        } # DETECT_XCLIP

        log_trace "No known clipboard manager is detected";
    } # DETECT

    if ($args{detail}) {
        $info;
    } else {
        $info->{manager};
    }
}

$SPEC{'clear_clipboard_history'} = {
    v => 1.1,
    summary => 'Delete all clipboard items',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
    },
};
sub clear_clipboard_history {
    my %args = @_;

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my ($stdout, $stderr);
        # qdbus likes to emit an empty line
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "clearClipboardHistory");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "/klipper's clearClipboardHistory failed: $exit_code"] if $exit_code;
        return [200, "OK"];
    } elsif ($clipboard_manager eq 'parcellite') {
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'clipit') {
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'xclip') {
        # implemented by setting both primary and clipboard to empty string

        my $fh;

        open $fh, "| xclip -i -selection primary" ## no critic: InputOutput::ProhibitTwoArgOpen
            or return [500, "xclip -i -selection primary failed (1): $!"];
        print $fh '';
        close $fh
            or return [500, "xclip -i -selection primary failed (2): $!"];

        open $fh, "| xclip -i -selection clipboard" ## no critic: InputOutput::ProhibitTwoArgOpen
            or return [500, "xclip -i -selection clipboard failed (1): $!"];
        print $fh '';
        close $fh
            or return [500, "xclip -i -selection clipboard failed (2): $!"];

        return [200, "OK"];
    }

    [412, "Cannot clear clipboard history (clipboard manager=$clipboard_manager)"];
}

$SPEC{'clear_clipboard_content'} = {
    v => 1.1,
    summary => 'Delete current clipboard content',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
    },
};
sub clear_clipboard_content {
    my %args = @_;

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my ($stdout, $stderr);
        # qdbus likes to emit an empty line
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "clearClipboardContents");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "/klipper's clearClipboardContents failed: $exit_code"] if $exit_code;
        return [200, "OK"];
    } elsif ($clipboard_manager eq 'parcellite') {
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'clipit') {
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'xclip') {
        # implemented by setting primary to empty string

        open my $fh, "| xclip -i -selection primary" ## no critic: InputOutput::ProhibitTwoArgOpen
            or return [500, "xclip -i -selection primary failed (1): $!"];
        print $fh '';
        close $fh
            or return [500, "xclip -i -selection primary failed (2): $!"];

        return [200, "OK"];
    }

    [412, "Cannot clear clipboard content (clipboard manager=$clipboard_manager)"];
}

$SPEC{'get_clipboard_content'} = {
    v => 1.1,
    summary => 'Get the clipboard content (most recent, history index [0])',
    description => <<'MARKDOWN',

Caveats for klipper: Non-text item is not retrievable by getClipboardContents().
If the current item is e.g. an image, then the next text item from history will
be returned instead, or empty string if none exists.

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
    },
    examples => [
        {
            summary => 'Munge text (remove duplicate spaces) in clipboard',
            src_plang => 'bash',
            src => q{[[prog]] | perl -lpe's/ {2,}/ /g' | clipadd},
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub get_clipboard_content {
    my %args = @_;

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my ($stdout, $stderr);
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "getClipboardContents");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "/klipper's getClipboardContents failed: $exit_code"] if $exit_code;
        chomp $stdout;
        return [200, "OK", $stdout];
    } elsif ($clipboard_manager eq 'parcellite') {
        my ($stdout, $stderr);
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               "parcellite", "-p");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "parcellite command failed with exit code $exit_code"] if $exit_code;
        return [200, "OK", $stdout];
    } elsif ($clipboard_manager eq 'clipit') {
        my ($stdout, $stderr);
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               "clipit", "-p");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "clipit command failed with exit code $exit_code"] if $exit_code;
        return [200, "OK", $stdout];
    } elsif ($clipboard_manager eq 'xclip') {
        my ($stdout, $stderr);
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               "xclip", "-o", "-selection", "primary");
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "xclip -o failed with exit code $exit_code"] if $exit_code;
        return [200, "OK", $stdout];
    }

    [412, "Cannot get clipboard content (clipboard manager=$clipboard_manager)"];
}

$SPEC{'list_clipboard_history'} = {
    v => 1.1,
    summary => 'List the clipboard history',
    description => <<'MARKDOWN',

Caveats for klipper: 1) Klipper does not provide method to get the length of
history. So we retrieve history item one by one using getClipboardHistoryItem(i)
from i=0, i=1, and so on. And assume that if we get two consecutive empty
string, it means we reach the end of the clipboard history before the first
empty result.

2) Non-text items are not retrievable by getClipboardHistoryItem().

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
    },
};
sub list_clipboard_history {
    my %args = @_;

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my @rows;
        my $i = 0;
        my $got_empty;
        while (1) {
            my ($stdout, $stderr);
            system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "getClipboardHistoryItem", $i);
            my $exit_code = $? < 0 ? $? : $?>>8;
            return [500, "/klipper's getClipboardHistoryItem($i) failed: $exit_code"] if $exit_code;
            chomp $stdout;
            if ($stdout eq '') {
                log_trace "Got empty result";
                if ($got_empty++) {
                    pop @rows;
                    last;
                } else {
                    push @rows, $stdout;
                }
            } else {
                log_trace "Got result '%s'", $stdout;
                $got_empty = 0;
                push @rows, $stdout;
            }
            $i++;
        }
        return [200, "OK", \@rows];
    } elsif ($clipboard_manager eq 'parcellite') {
        # parcellite -c usually just prints the same result as -p (primary)
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'clipit') {
        # clipit -c usually just prints the same result as -p (primary)
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'xclip') {
        my ($stdout, $stderr, $exit_code);
        my @rows;

        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               "xclip", "-o", "-selection", "primary");
        $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "xclip -o (primary) failed with exit code $exit_code"] if $exit_code;
        push @rows, $stdout;

        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               "xclip", "-o", "-selection", "clipboard");
        $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "xclip -o (clipboard) failed with exit code $exit_code"] if $exit_code;
        push @rows, $stdout;

        return [200, "OK", \@rows];
    }

    [412, "Cannot list clipboard history (clipboard manager=$clipboard_manager)"];
}

$SPEC{'get_clipboard_history_item'} = {
    v => 1.1,
    summary => 'Get a clipboard history item',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
        %argspec0_index,
    },
};
sub get_clipboard_history_item {
    my %args = @_;
    my $index = $args{index};

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my ($stdout, $stderr);
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "getClipboardHistoryItem", $index);
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "/klipper's getClipboardHistoryItem($index) failed: $exit_code"] if $exit_code;
        chomp $stdout;
        return [200, "OK", $stdout];
    } elsif ($clipboard_manager eq 'parcellite') {
        # parcellite -c usually just prints the same result as -p (primary)
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'clipit') {
        # clipit -c usually just prints the same result as -p (primary)
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'xclip') {
        my ($stdout, $stderr, $exit_code);
        my @rows;

        if ($index == 0) {
            system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
                   "xclip", "-o", "-selection", "primary");
            $exit_code = $? < 0 ? $? : $?>>8;
            return [500, "xclip -o (primary) failed with exit code $exit_code"] if $exit_code;
            return [200, "OK", $stdout];
        } elsif ($index == 0) {
            system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
                   "xclip", "-o", "-selection", "clipboard");
            $exit_code = $? < 0 ? $? : $?>>8;
            return [500, "xclip -o (clipboard) failed with exit code $exit_code"] if $exit_code;
            return [200, "OK", $stdout];
        } else {
            return [200, "OK", undef];
        }
    }

    [412, "Cannot get clipboard history item (clipboard manager=$clipboard_manager)"];
}

$SPEC{'add_clipboard_content'} = {
    v => 1.1,
    summary => 'Add a new content to the clipboard',
    description => <<'MARKDOWN',

For `xclip`: when adding content, the primary selection is set. The clipboard
content is unchanged.

MARKDOWN
    args => {
        %argspecopt_clipboard_manager,
        content => {
            schema => 'str*',
            pos=>0,
            cmdline_src=>'stdin_or_args',
        },
        tee => {
            summary => 'If set to true, will output content back to STDOUT',
            schema => 'bool*',
            cmdline_aliases => {t=>{}},
        },
        chomp_newline => {
            summary => 'Remove trailing newlines before adding item to clipboard',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            summary => 'Munge text (remove duplicate spaces) in clipboard',
            src_plang => 'bash',
            src => q{clipget | perl -lpe's/ {2,}/ /g' | [[prog]]},
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub add_clipboard_content {
    my %args = @_;

    my $clipboard_manager = $args{clipboard_manager} // detect_clipboard_manager();
    return [412, "Can't detect any known clipboard manager"]
        unless $clipboard_manager;

    defined $args{content} or
        return [400, "Please specify content"];

    my $content0 = $args{content};
    my $content = $content0;
    $content =~ s/\R+\z// if $args{chomp_newline};

    if ($clipboard_manager eq 'klipper') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my ($stdout, $stderr);
        # qdbus likes to emit an empty line
        system({capture_stdout=>\$stdout, capture_stderr=>\$stderr},
               $paths[0], "org.kde.klipper", "/klipper", "setClipboardContents", $content);
        my $exit_code = $? < 0 ? $? : $?>>8;
        return [500, "/klipper's setClipboardContents failed: $exit_code"] if $exit_code;
        print $content0 if $args{tee};
        return [200, "OK"];
    } elsif ($clipboard_manager eq 'parcellite') {
        # parcellite cli copies unknown options and stdin to clipboard history
        # but not as the current one
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'clipit') {
        # clipit cli copies unknown options and stdin to clipboard history but
        # not as the current one
        return [501, "Not yet implemented"];
    } elsif ($clipboard_manager eq 'xclip') {
        open my $fh, "| xclip -i -selection primary" ## no critic: InputOutput::ProhibitTwoArgOpen
            or return [500, "xclip -i -selection primary failed (1): $!"];
        print $fh $content;
        close $fh
            or return [500, "xclip -i -selection primary failed (2): $!"];
        print $content0 if $args{tee};
        return [200, "OK"];
    }

    [412, "Cannot add clipboard content (clipboard manager=$clipboard_manager)"];
}

1;
# ABSTRACT: Common interface to clipboard manager functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Clipboard::Any - Common interface to clipboard manager functions

=head1 VERSION

This document describes version 0.015 of Clipboard::Any (from Perl distribution Clipboard-Any), released on 2025-06-16.

=head1 DESCRIPTION

This module provides a common interface to interact with clipboard.

Some terminology:

=over

=item * clipboard content

The current clipboard content. Some clipboard manager supports storing multiple
items (multiple contents). All the items are called L</clipboard history>.

=item * clipboard history

Some clipboard manager supports storing multiple items (multiple contents). All
the items are called clipboard history. It is presented as an array. The current
item/content is at index 0, the secondmost current item is at index 1, and so
on.

=back

=head2 Supported clipboard managers

=head3 Klipper

The default clipboard manager on KDE Plasma.

=head3 clipit

=head3 parcellite

=head3 xclip

This is not a "real" clipboard manager, but just an interface to the X
selections. With C<xclip>, the history is viewed as having two items. The
first/recent is the primary selection and the second one is the secondary.


This module provides common functions related to clipboard manager.

Supported clipboard manager: KDE Plasma's Klipper (C<klipper>), C<parcellite>,
C<clipit>, C<xclip>. Support for more clipboard managers, e.g. on Windows or other
Linux desktop environment is welcome.

=head1 NOTES

2021-07-15 - Tested on my system (KDE Plasma 5.12.9 on Linux).

=head1 FUNCTIONS


=head2 add_clipboard_content

Usage:

 add_clipboard_content(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add a new content to the clipboard.

For C<xclip>: when adding content, the primary selection is set. The clipboard
content is unchanged.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<chomp_newline> => I<bool>

Remove trailing newlines before adding item to clipboard.

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.

=item * B<content> => I<str>

(No description)

=item * B<tee> => I<bool>

If set to true, will output content back to STDOUT.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 clear_clipboard_content

Usage:

 clear_clipboard_content(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete current clipboard content.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 clear_clipboard_history

Usage:

 clear_clipboard_history(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete all clipboard items.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 detect_clipboard_manager

Usage:

 detect_clipboard_manager(%args) -> any

Detect which clipboard manager program is currently running.

Will return a string containing name of clipboard manager program, e.g.
C<klipper>. Will return undef if no known clipboard manager is detected.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)


=back

Return value:  (any)



=head2 get_clipboard_content

Usage:

 get_clipboard_content(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the clipboard content (most recent, history index [0]).

Caveats for klipper: Non-text item is not retrievable by getClipboardContents().
If the current item is e.g. an image, then the next text item from history will
be returned instead, or empty string if none exists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_clipboard_history_item

Usage:

 get_clipboard_history_item(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get a clipboard history item.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.

=item * B<index> => I<int>

Index of item in history (0 means the currentE<sol>latest, 1 the second latest, and so on).

If the index exceeds the number of items in history, empty string or undef will
be returned instead.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_clipboard_history

Usage:

 list_clipboard_history(%args) -> [$status_code, $reason, $payload, \%result_meta]

List the clipboard history.

Caveats for klipper: 1) Klipper does not provide method to get the length of
history. So we retrieve history item one by one using getClipboardHistoryItem(i)
from i=0, i=1, and so on. And assume that if we get two consecutive empty
string, it means we reach the end of the clipboard history before the first
empty result.

2) Non-text items are not retrievable by getClipboardHistoryItem().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Clipboard-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Clipboard-Any>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Clipboard-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
