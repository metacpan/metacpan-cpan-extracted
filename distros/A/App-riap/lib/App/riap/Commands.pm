package App::riap::Commands;

our $DATE = '2020-01-28'; # DATE
our $VERSION = '0.381'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Path::Naive qw(is_abs_path normalize_path concat_path_n);
#use Perinci::Sub::Util qw(err);

# like Path::Naive's concat_path_n, but adds "/" at the end when it thinks the
# final path is a directory (package). it also doesn't die if $p2 is empty.
sub _concat_path_ns {
    my ($p1, $p2) = @_;
    return $p1 unless defined($p2) && length($p2);
    my $res = concat_path_n($p1, $p2);
    $res .= "/" if $p2 =~ m!\A\.\.?\z|/\z!;
    $res;
}

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'riap shell commands',
};

my $_complete_dir_or_file = sub {
    my $which = shift;

    my %args = @_;
    my $shell = $args{-shell};

    my $word0 = $args{word};
    my ($dir, $word) = $word0 =~ m!(.*/)?(.*)!;
    $dir //= "";

    my $pwd = $shell->state("pwd");
    my $uri = length($dir) ? Path::Naive::concat_path_n($pwd, $dir) : $pwd;
    $uri .= "/" unless $uri =~ m!/\z!;
    my $extra = {};
    $extra->{type} = 'package' if $which eq 'dir';
    $extra->{type} = 'function' if $which eq 'executable';
    my $res = $shell->riap_request(list => $uri, $extra);
    return [] unless $res->[0] == 200;
    my @res = ();
    push @res, "../" unless $uri eq '/';
    for (@{ $res->[2] }) {
        s/\A\Q$uri\E//;
        push @res, "$dir$_";
    }
    \@res;
};

my $complete_dir = sub {
    $_complete_dir_or_file->('dir', @_);
};

my $complete_file_or_dir = sub {
    $_complete_dir_or_file->('file_or_dir', @_);
};

my $complete_executable = sub {
    $_complete_dir_or_file->('executable', @_);
};

my $complete_setting_name = sub {
    my %args = @_;
    my $shell = $args{-shell};

    [keys %{ $shell->known_settings }];
};

# format of summary: <shell-ish description> (<equivalent in terms of Riap>)
#
# for format of description, we follow Term::Shell style: no first-letter cap,
# verb in 3rd person present tense.

$SPEC{ls} = {
    v => 1.1,
    summary => 'lists contents of packages (Riap list request)',
    args => {
        long => {
            summary => 'Long mode (detail=1)',
            description => <<'_',

This will cause the command to request `child_metas` action to the server
instead of `list`, to get more details.

_
            schema => ['bool'],
            cmdline_aliases => { l => {} },
        },
        # completion acts a bit weird, so we use single path atm
        #paths => {
        #    summary    => 'Path(s) (URIs) to list',
        #    schema     => ['array*' => 'of' => 'str*'],
        #    req        => 0,
        #    pos        => 0,
        #    greedy     => 1,
        #    element_completion => $complete_file_or_dir,
        #},
        path => {
            summary    => 'Path (URI) to list',
            schema     => ['str*'],
            req        => 0,
            pos        => 0,
            completion => $complete_file_or_dir,
        },
        all => {
            summary     => 'Does nothing, added only to let you type ls -la',
            schema      => ['bool'],
            description => <<'_',

Some of you might type `ls -la` or `ls -al` by muscle memory. So the -a option
is added just to allow this to not produce an error :-).

_
            cmdline_aliases => { a=>{} },
        },
    },
    "x.app.riap.aliases" => ["list"],
};
sub ls {
    my %args = @_;
    my $shell = $args{-shell};

    my $pwd = $shell->state("pwd");
    my $uri;
    my ($dir, $leaf);
    my $resmeta = {};

    my @allres;
    #for my $path (@{ $args{paths} // [undef] }) {
    for my $path ($args{path}) {
        $uri = $pwd . ($pwd =~ m!/\z! ? "" : "/");
        if (defined $path) {
            $uri = _concat_path_ns($pwd, $path);
        }

        my $res;
        if ($args{long}) {
            $res = $shell->riap_request(child_metas => $uri);
            return $res unless $res->[0] == 200;
            for my $u (sort keys %{ $res->[2] }) {
                my $m = $res->[2]{$u};
                next if defined($leaf) && length($leaf) && $u ne $leaf;
                my $type; # XXX duplicate code somewhere
                if ($u =~ m!/\z!) {
                    $type = 'package';
                } elsif ($u =~ /\A\$/) {
                    $type = 'variable';
                } elsif ($u =~ /\A\w+\z/) {
                    $type = 'function';
                }
                push @allres, {
                    uri         => $u,
                    type        => $type,
                    summary     => $m->{summary},
                    date        => $m->{entity_date},
                    v           => $m->{entity_v},
                };
            }
            my $ff = [qw/type uri v date summary/];
            my $rfo = {

            };
            $resmeta = {
                "table.fields"   => $ff,
            };
        } else {
            $res = $shell->riap_request(list => $uri);
            return $res unless $res->[0] == 200;

            for (@{ $res->[2] }) {
                next if defined($leaf) && length($leaf) && $_ ne $leaf;
                push @allres, $_;
            }
        }

        if (!@allres && defined($leaf) && length($leaf)) {
            return [404, "No such file (Riap entity): $path"];
        }

    }
    [200, "OK", \@allres, $resmeta];
}

$SPEC{pwd} = {
    v => 1.1,
    summary => 'shows current directory',
    args => {
    },
};
sub pwd {
    my %args = @_;
    my $shell = $args{-shell};

    [200, "OK", $shell->{_state}{pwd}];
}

$SPEC{cd} = {
    v => 1.1,
    summary => "changes directory",
    args => {
        dir => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            completion => $complete_dir,
        },
    },
};
sub cd {
    my %args = @_;
    my $dir = $args{dir};
    my $shell = $args{-shell};

    my $opwd = $shell->state("pwd");
    my $npwd;
    if (!defined($dir)) {
        # back to start pwd
        $npwd = $shell->state("start_pwd");
    } elsif ($dir eq '-') {
        if (defined $shell->state("old_pwd")) {
            $npwd = $shell->state("old_pwd");
        } else {
            warn "No old pwd set\n";
            return [200, "Nothing done"];
        }
    } else {
        if (is_abs_path($dir)) {
            $npwd = normalize_path($dir);
        } else {
            $npwd = concat_path_n($opwd, $dir);
        }
    }
    # check if path actually exists
    my $uri = $npwd . ($npwd =~ m!/\z! ? "" : "/");
    my $res = $shell->riap_request(info => $uri);
    if ($res->[0] == 404) {
        return [404, "No such directory (Riap package)"];
    } elsif ($res->[0] != 200) {
        return $res;
    }
    #return [403, "Not a directory (package)"]
    #    unless $res->[2]{type} eq 'package';

    log_trace("Setting npwd=%s, opwd=%s", $npwd, $opwd);
    $shell->state(pwd     => $npwd);
    $shell->state(old_pwd => $opwd);
    [200, "OK"];
}

$SPEC{set} = {
    v => 1.1,
    summary => "lists or sets setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            pos        => 0,
            # we use custom completion because the list of known settings must
            # be retrieved through the shell object
            completion => $complete_setting_name,
        },
        value => {
            summary    => '',
            schema     => ['any'],
            pos        => 1,
            completion => sub {
                require Perinci::Sub::Complete;

                my %args = @_;
                my $shell = $args{-shell};
                my $args  = $args{args};
                return [] unless $args->{name};
                my $setting = $shell->known_settings->{ $args->{name} };
                return [] unless $setting;

                # a hack, construct a throwaway meta and using that to complete
                # setting argument as function argument
                Perinci::Sub::Complete::complete_arg_val(
                    arg=>'foo',
                    meta=>{v=>1.1, args=>{foo=>{schema=>$setting->{schema}}}},
                );
            },
        },
    },
};
sub set {
    my %args = @_;
    my $shell = $args{-shell};

    my $name  = $args{name};

    if (exists $args{value}) {
        # set setting
        return [400, "Unknown setting, use 'set' to list all known settings"]
            unless exists $shell->known_settings->{$name};
        $shell->setting($name, $args{value});
        [200, "OK"];
    } else {
        # list settings
        my $res = [];
        if (defined $name) {
            return [400,"Unknown setting, use 'set' to list all known settings"]
                unless exists $shell->known_settings->{$name};
        }
        for (sort keys %{ $shell->known_settings }) {
            next if defined($name) && $_ ne $name;
            push @$res, {
                name => $_,
                summary => $shell->known_settings->{$_}{summary},
                value   => $shell->{_settings}{$_},
                default => $shell->known_settings->{$_}{schema}[1]{default},
            };
        }
        [200, "OK", $res, {'table.fields' => [qw/name summary value default/]}];
    }
}

$SPEC{unset} = {
    v => 1.1,
    summary => "unsets a setting",
    args => {
        name => {
            summary    => '',
            schema     => ['str*'],
            req        => 1,
            pos        => 0,
            completion => $complete_setting_name,
        },
    },
};
sub unset {
    my %args = @_;
    my $shell = $args{-shell};

    my $name = $args{name};

    return [400, "Unknown setting, use 'set' to list all known settings"]
        unless exists $shell->known_settings->{$name};
    delete $shell->{_settings}{$name};
    [200, "OK"];
}

$SPEC{show} = {
    v => 1.1,
    summary => "shows various things",
    args => {
        thing => {
            summary    => 'Thing to show',
            schema     => ['str*', in => [qw/settings state/]],
            req        => 1,
            pos        => 0,
        },
    },
};
sub show {
    my %args = @_;
    my $shell = $args{-shell};

    my $thing = $args{thing};

    if ($thing eq 'settings') {
        return set(-shell=>$shell);
    } elsif ($thing eq 'state') {
        [200, "OK", $shell->{_state}];
    } else {
        [400, "Invalid argument for show"];
    }
}

$SPEC{req} = {
    v => 1.1,
    summary => 'performs action on file/dir (Riap entity)',
    args => {
        action => {
            summary => 'Action name',
            schema => ['str*'],
            req    => 1,
            pos    => 0,
            cmdline_aliases => { a => {} },
        },
        path => {
            summary    => 'Path (entity URI)',
            schema     => 'str*',
            req        => 1,
            pos        => 1,
            completion => $complete_file_or_dir,
        },
        extra => {
            summary    => 'Extra Riap request keys',
            schema     => 'hash*',
            pos        => 2,
        },
    },
};
sub req {
    my %args = @_;
    my $shell = $args{-shell};

    my $action = $args{action};
    my $pwd    = $shell->state("pwd");
    my $path   = $args{path};
    my $uri    = _concat_path_ns($pwd, $path);
    my $extra  = $args{extra} // {};

    $shell->riap_request($action => $uri, $extra);
}

$SPEC{meta} = {
    v => 1.1,
    summary => 'performs meta action on file/dir (Riap entity)',
    args => {
        path => {
            summary    => 'Path (URI)',
            schema     => 'str*',
            req        => 1,
            pos        => 0,
            completion => $complete_file_or_dir,
        },
    },
};
sub meta {
    my %args = @_;
    my $shell = $args{-shell};

    my $pwd  = $shell->state("pwd");
    my $path = $args{path};
    my $uri  = _concat_path_ns($pwd, $path);

    $shell->riap_request(meta => $uri);
}

$SPEC{info} = {
    v => 1.1,
    summary => 'performs info action on file/dir (Riap entity)',
    args => {
        path => {
            summary    => 'Path (entity URI)',
            schema     => 'str*',
            req        => 1,
            pos        => 0,
            completion => $complete_file_or_dir,
        },
    },
};
sub info {
    my %args = @_;
    my $shell = $args{-shell};

    my $pwd  = $shell->state("pwd");
    my $path = $args{path};
    my $uri  = _concat_path_ns($pwd, $path);

    $shell->riap_request(info => $uri);
}

$SPEC{call} = {
    v => 1.1,
    summary => 'performs call action on file (Riap function)',
    args => {
        path => {
            summary    => 'Path to file (Riap function)',
            schema     => 'str*',
            req        => 1,
            pos        => 0,
            completion => $complete_file_or_dir,
        },
        args => {
            summary    => 'Arguments to pass to function',
            schema     => 'hash*',
            pos        => 1,
        },
    },
};
sub call {
    my %args = @_;
    my $shell = $args{-shell};

    my $pwd  = $shell->state("pwd");
    my $path = $args{path};
    my $uri  = _concat_path_ns($pwd, $path);
    my $args = $args{args};

    $shell->riap_request(call => $uri, {args=>$args});
}

$SPEC{history} = {
    v => 1.1,
    summary => 'shows command-line history',
    args => {
        append => {
            summary    => "Append current session's history to history file",
            schema     => 'bool',
            cmdline_aliases => { a=>{} },
        },
        read => {
            summary    => '(Re-)read history from file',
            schema     => 'bool',
            cmdline_aliases => { r=>{} },
        },
        clear => {
            summary    => 'Clear history',
            schema     => 'bool',
            cmdline_aliases => { c=>{} },
        },
    },
};
sub history {
    my %args = @_;
    my $shell = $args{-shell};

    if ($args{add}) {
        $shell->save_history;
        return [200, "OK"];
    } elsif ($args{read}) {
        $shell->load_history;
        return [200, "OK"];
    } elsif ($args{clear}) {
        $shell->clear_history;
        return [200, "OK"];
    } else {
        my @history;
        if ($shell->{term}->Features->{getHistory}) {
            @history = grep { length } $shell->{term}->GetHistory;
        }
        return [200, "OK", \@history,
                {"x.app.riap.default_format"=>"text-simple"}];
    }
}

1;
# ABSTRACT: riap shell commands

__END__

=pod

=encoding UTF-8

=head1 NAME

App::riap::Commands - riap shell commands

=head1 VERSION

version 0.381

=for Pod::Coverage .+

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
