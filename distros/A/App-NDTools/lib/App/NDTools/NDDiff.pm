package App::NDTools::NDDiff;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDTool';

use Algorithm::Diff qw(compact_diff);
use JSON qw();
use App::NDTools::Slurp qw(s_dump);
use Log::Log4Cli 0.18;
use Struct::Diff 0.96 qw();
use Struct::Path 0.80 qw(path path_delta);
use Struct::Path::PerlStyle 0.80 qw(str2path path2str);
use Term::ANSIColor qw(color);

our $VERSION = '0.53';

my $JSON = JSON->new->canonical->allow_nonref;
my %COLOR;

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'A!' => \$self->{OPTS}->{diff}->{A},
        'N!' => \$self->{OPTS}->{diff}->{N},
        'O!' => \$self->{OPTS}->{diff}->{O},
        'R!' => \$self->{OPTS}->{diff}->{R},
        'U!' => \$self->{OPTS}->{diff}->{U},
        'brief' => sub { $self->{OPTS}->{ofmt} = $_[0] },
        'colors!' => \$self->{OPTS}->{colors},
        'ctx-text=i' => \$self->{OPTS}->{'ctx-text'},
        'full-headers' => \$self->{OPTS}->{'full-headers'}, # deprecated since 17 May 2018
        'grep=s@' => \$self->{OPTS}->{grep},
        'json' => sub { $self->{OPTS}->{ofmt} = $_[0] },
        'ignore=s@' => \$self->{OPTS}->{ignore},
        'rules' => sub { $self->{OPTS}->{ofmt} = $_[0] },
        'quiet|q' => \$self->{OPTS}->{quiet},
        'show' => \$self->{OPTS}->{show},
    )
}

sub check_args {
    my $self = shift;

    if ($self->{OPTS}->{show}) {
        die_fatal "At least one argument expected when --show used", 1
            unless (@_);
    } elsif (@_ < 2) {
        die_fatal "At least two arguments expected for diff", 1;
    }

    return $self;
}

sub configure {
    my $self = shift;

    $self->SUPER::configure();

    if ($self->{OPTS}->{'full-headers'}) {
        log_alert {
            '--full-headers opt is deprecated and will be removed soon. ' .
            '--nopretty should be used instead'
        };
        $self->{OPTS}->{pretty} = 0;
    }

    $self->{OPTS}->{colors} = $self->{TTY}
        unless (defined $self->{OPTS}->{colors});

    # resolve colors
    while (my ($k, $v) = each %{$self->{OPTS}->{term}->{line}}) {
        if ($self->{OPTS}->{colors}) {
            $COLOR{$k} = color($v);
            $COLOR{"B$k"} = color("bold $v");
        } else {
            $COLOR{$k} = $COLOR{"B$k"} = '';
        }
    }

    $COLOR{head} = $self->{OPTS}->{colors}
        ? color($self->{OPTS}->{term}->{head}) : "";
    $COLOR{reset} = $self->{OPTS}->{colors} ? color('reset') : "";

    # resolve paths
    for (@{$self->{OPTS}->{grep}}, @{$self->{OPTS}->{ignore}}) {
        my $tmp = eval { str2path($_) };
        die_fatal "Failed to parse '$_'", 4 if ($@);
        $_ = $tmp;
    }

    return $self;
}

sub defaults {
    my $self = shift;

    my $out = {
        %{$self->SUPER::defaults()},
        'ctx-text' => 3,
        'diff' => {
            'A' => 1,
            'N' => 1,
            'O' => 1,
            'R' => 1,
            'U' => 0,
        },
        'ofmt' => 'term',
        'term' => {
            'head' => 'yellow',
            'indt' => '  ',
            'line' => {
                'A' => 'green',
                'D' => 'yellow',
                'N' => 'green',
                'O' => 'red',
                'U' => 'white',
                'R' => 'red',
                '@' => 'magenta',
            },
            'sign' => {
                'A' => '+ ',
                'D' => '! ',
                'N' => '+ ',
                'O' => '- ',
                'U' => '  ',
                'R' => '- ',
                '@' => '  ',
            },
        },
    };

    return $out;
}

sub diff {
    my ($self, $old, $new) = @_;

    log_debug { "Calculating diff for structure" };
    my $diff = Struct::Diff::diff(
        $old, $new,
        map { ("no$_" => 1) } grep { !$self->{OPTS}->{diff}->{$_} }
            keys %{$self->{OPTS}->{diff}},
    );

    # retrieve result from wrapper (see load() for more info)
    if (exists $diff->{D}) {
        $diff = $diff->{D}->[0];
    } elsif (exists $diff->{U}) {
        $diff->{U} = $diff->{U}->[0];
    }

    $self->diff_term($diff) if ($self->{OPTS}->{ofmt} eq 'term');

    return $diff;
}

sub diff_term {
    my ($self, $diff) = @_;

    log_debug { "Calculating diffs for text values" };

    my $dref; # ref to diff
    my @list = Struct::Diff::list_diff($diff);

    while (@list) {
        (undef, $dref) = splice @list, 0, 2;

        next unless (exists ${$dref}->{N});
        next unless (defined ${$dref}->{O} and defined ${$dref}->{N});
        next if (ref ${$dref}->{O} or ref ${$dref}->{N});

        my @old = split($/, ${$dref}->{O}, -1);
        my @new = split($/, ${$dref}->{N}, -1);

        if (@old > 1 or @new > 1) {
            delete ${$dref}->{O};
            delete ${$dref}->{N};

            if ($old[-1] eq '' and $new[-1] eq '') {
                pop @old; # because split by newline and -1 for LIMIT
                pop @new; # -"-
            }

            my @cdiff = compact_diff(\@old, \@new);
            my ($match, $header);

            while (@cdiff > 2) {
                my @del = @old[$cdiff[0] .. $cdiff[2] - 1];
                my @add = @new[$cdiff[1] .. $cdiff[3] - 1];

                if ($match = !$match) {
                    # trailing context
                    if ($header) {
                        my @tail = splice @del, 0, $self->{OPTS}->{'ctx-text'};
                        push @{${$dref}->{T}}, 'U', \@tail;

                        $header->[1] += @tail;
                        $header->[3] += @tail;
                    }

                    # leading context
                    if (@cdiff > 4) {
                        my @rest = splice @del, 0, $self->{OPTS}->{'ctx-text'}
                            ? $self->{OPTS}->{'ctx-text'} * -1 : scalar @del;

                        if (@rest or !$header) {
                            push @{${$dref}->{T}}, '@', $header = [
                                $cdiff[2] - @del + 1, 0,
                                $cdiff[3] - @del + 1, 0,
                            ];
                        }

                        if (@del) {
                            push @{${$dref}->{T}}, 'U', \@del;
                            $header->[1] += @del;
                            $header->[3] += @del;
                        }
                    }
                } else {
                    if (@del) {
                        push @{${$dref}->{T}}, 'R', \@del;
                        $header->[1] += @del;
                    }

                    if (@add) {
                        push @{${$dref}->{T}}, 'A', \@add;
                        $header->[3] += @add;
                    }
                }

                splice @cdiff, 0, 2;
            }
        }
    }

    return $self;
}

sub dump {
    my ($self, $diff) = @_;

    log_debug { "Dumping results" };

    if ($self->{OPTS}->{ofmt} eq 'term') {
        $self->dump_term($diff);
    } elsif ($self->{OPTS}->{ofmt} eq 'brief') {
        $self->dump_brief($diff);
    } elsif ($self->{OPTS}->{ofmt} eq 'rules') {
        $self->dump_rules($diff);
    } else {
        s_dump(\*STDOUT, $self->{OPTS}->{ofmt},
            {pretty => $self->{OPTS}->{pretty}}, $diff);
    }

    return $self;
}

sub dump_brief {
    my ($self, $diff) = @_;

    my ($path, $dref, $tag);
    my @list = Struct::Diff::list_diff($diff, sort => 1);

    while (@list) {
        ($path, $dref) = splice @list, 0, 2;
        for $tag (qw{R N A}) {
            $self->print_brief_block($path, $tag)
                if (exists ${$dref}->{$tag});
        }
    }
}

sub dump_rules {
    my ($self, $diff) = @_;

    my ($path, $dref, $item, @out);
    my @list = Struct::Diff::list_diff($diff, sort => 1);

    while (@list) {
        ($path, $dref) = splice @list, 0, 2;
        for (qw{R N A}) {
            next unless (exists ${$dref}->{$_});
            unshift @out, {
                modname => $_ eq "R" ? "Remove" : "Insert",
                path => $self->dump_rules_path($path),
                value => ${$dref}->{$_}
            };
        }
    }

    s_dump(\*STDOUT, 'JSON', {pretty => $self->{OPTS}->{pretty}}, \@out);
}

sub dump_rules_path { # to be able to override
    return path2str($_[1]);
}

sub dump_term {
    my ($self, $diff) = @_;

    my ($path, $dref, $tag);
    my @list = Struct::Diff::list_diff($diff, sort => 1);

    while (@list) {
        ($path, $dref) = splice @list, 0, 2;
        for $tag (qw{R O N A T U}) {
            $self->print_term_block(${$dref}->{$tag}, $path, $tag)
                if (exists ${$dref}->{$tag});
        }
    }
}

sub exec {
    my $self = shift;
    my (@diffs, @files);

    for (@{$self->{ARGV}}) {
        push @files, { data => $self->load($_), name => $_ };

        if ($self->{OPTS}->{show}) {
            if (ref $files[0]->{data}->[0] eq 'ARRAY') { # ndproc's blame
                for (@{$files[0]->{data}->[0]}) {
                    push @diffs, $_->{diff},
                        [ $files[0]->{name} . ', rule #' . $_->{rule_id} ];
                }
            } else { # regular diff dump
                push @diffs, $files[0]->{data}->[0], [ $files[0]->{name} ];
            }
        } else { # one of the files to diff
            next unless (@files > 1);
            push @diffs, $self->diff($files[0]->{data}, $files[1]->{data});
            push @diffs, [ $files[0]->{name}, $files[1]->{name} ];
        }

        shift @files;

        while (@diffs) {
            my ($diff, $hdrs) = splice @diffs, 0, 2;

            $self->print_term_header(@{$hdrs});

            if (
                $self->{OPTS}->{show} and
                my @errs = Struct::Diff::valid_diff($diff)
            ) {
                while (@errs) {
                    my ($path, $type) = splice @errs, 0, 2;
                    log_error { "$type " . path2str($path) };
                }

                die_fatal "Diff validation failed", 1;
            }

            $self->dump($diff) unless ($self->{OPTS}->{quiet});
            $self->{status} = 8
                unless (not keys %{$diff} or exists $diff->{U});
        }
    }

    die_info "All done, no difference found", 0 unless ($self->{status});
    die_info "Difference found", 8;
}

sub load {
    my $self = shift;

    my @data = $self->load_struct($_[0], $self->{OPTS}->{ifmt});

    # array used to indicate absent value for grep result
    @data = $self->grep($self->{OPTS}->{grep}, $data[0])
        if (@{$self->{OPTS}->{grep}});

    if (@data and ref $data[0]) {
        map { path($data[0], $_, delete => 1) } @{$self->{OPTS}->{ignore}}
    }

    return \@data;
}

sub print_brief_block {
    my ($self, $path, $status) = @_;

    $status = 'D' if ($status eq 'N');

    print $self->{OPTS}->{term}->{sign}->{$status} . $COLOR{U} .
        path2str([splice @{$path}, 0, -1]) . $COLOR{reset} .
        $COLOR{"B$status"} . path2str($path) . $COLOR{reset} . "\n";
}

sub print_term_block {
    my ($self, $value, $path, $status) = @_;

    log_trace { "'" . path2str($path) . "' ($status)" };

    my @lines;
    my $dsign = $self->{OPTS}->{term}->{sign}->{$status};
    my $indent = $self->{OPTS}->{term}->{indt};

    # diff for path
    if (@{$path} and my @delta = path_delta($self->{'hdr_path'}, $path)) {
        $self->{'hdr_path'} = [@{$path}];
        my $s = $self->{OPTS}->{pretty} ? @{$path} - @delta : 0;

        while ($s < @{$path}) {
            my $line = $indent x $s . path2str([$path->[$s]]);

            if (($status eq 'A' or $status eq 'R') and $s == $#{$path}) {
                $line = $COLOR{"B$status"} . $dsign . $line . $COLOR{reset};
            } else {
                substr($line, 0, 0, $indent);
            }

            push @lines, $line;
            $s++;
        }
    }

    # diff for value
    push @lines, $self->term_value_diff($value, $status, $indent x @{$path});

    print join("\n", @lines) . "\n";
}

sub print_term_header {
    my ($self, @names) = @_;

    if ($self->{TTY} and not $self->{OPTS}->{quiet}) {
        print $COLOR{head} .
            (@names == 1 ? "!!! $names[0]" : "--- $names[0]\n+++ $names[1]") .
            $COLOR{reset}. "\n";
    }
}

sub term_value_diff {
    my ($self, $value, $status, $indent) = @_;

    return $self->term_value_diff_text($value, $indent)
        if ($status eq 'T');

    return $self->term_value_diff_default($value, $status, $indent);
}

sub term_value_diff_default {
    my ($self, $value, $status, $indent) = @_;
    my @out;

    $value = $JSON->pretty($self->{OPTS}->{pretty})->encode($value)
        if (ref $value or not defined $value);

    for my $line (split($/, $value)) {
        substr($line, 0, 0, $self->{OPTS}->{term}->{sign}->{$status} . $indent);
        push @out, $COLOR{$status} . $line . $COLOR{reset};
    }

    return @out;
}

sub term_value_diff_text {
    my ($self, $diff, $indent) = @_;
    my (@hdr, $lines, @out, $pfx, $sfx, $status);

    $sfx = $COLOR{reset};

    while (@{$diff}) {
        ($status, $lines) = splice @{$diff}, 0, 2;

        $pfx = $COLOR{$status} . $self->{OPTS}->{term}->{sign}->{$status} .
            $indent;

        if ($status eq '@') {
            @hdr = splice @{$lines};
            $lines->[0] = "@@ -$hdr[0]" . ($hdr[1] > 1 ? ",$hdr[1] " : "") .
                " +$hdr[2]" . ($hdr[3] > 1 ? ",$hdr[3] @@" : " @@");
        }

        map { substr($_ , 0, 0, $pfx); $_ .= $sfx; push @out, $_ } @{$lines};
    }

    return @out;
}

1; # End of App::NDTools::NDDiff
