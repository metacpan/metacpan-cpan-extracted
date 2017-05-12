package App::perlmv;

our $DATE = '2015-11-17'; # DATE
our $VERSION = '0.50'; # VERSION

use 5.010;
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
#use Data::Dump qw(dump);
use File::Copy;
use File::Find;
use File::MoreUtil qw(l_abs_path);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(:config no_ignore_case bundling);

sub new {
    my ($class) = @_;

    # determine home
    my $homedir;

    if ( $ENV{'TESTING_HOME'} ) {
        $homedir = $ENV{'TESTING_HOME'};
    } else {
        eval {
            require File::HomeDir;
            $homedir = File::HomeDir->my_home;
        };

        $homedir //= $ENV{'HOME'};

        die "FATAL: Can't determine home directory\n" unless $homedir;
    }

    my $self = {
        codes           => [],
        dry_run         => 0,
        homedir         => $homedir,
        sort_mode       => 1, # 1=sort ascibetically, -1=reverse, 0=no sort
        overwrite       => 0,
        process_dir     => 1,
        process_symlink => 1,
        recursive       => 0,
        verbose         => 0,
    };

    bless $self, $class;

    return $self;
}


sub parse_opts {
    my $self = shift;

    GetOptions(
        'c|check'         => \$self->{ 'check'         },
        'D|delete=s'      => \$self->{ 'delete'        },
        'd|dry-run'       => \$self->{ 'dry_run'       },
        'e|eval=s'        =>  $self->{ 'codes'         },
        'h|help'          => sub { $self->print_help() },
        'l|list'          => \$self->{ 'list'          },
        'M|mode=s'        => \$self->{ 'mode'          },
        'o|overwrite'     => \$self->{ 'overwrite'     },
        'p|parents'       => \$self->{ 'parents'       },
        'R|recursive'     => \$self->{ 'recursive'     },
        'r|reverse'       => sub { $self->{sort_mode} = -1 },
        's|show=s'        => \$self->{ 'show'          },
        'T|no-sort'       => sub { $self->{sort_mode} =  0 },
        'v|verbose'       => \$self->{ 'verbose'       },
        'w|write=s'       => \$self->{ 'write'         },
        'f|files'         => sub { $self->{ 'process_dir'    } = 0 },
        'S|no-symlinks'   => sub { $self->{ 'process_symlink'} = 0 },
        'V|version'       => sub { $self->print_version()          },
        # we use \scalar to differentiate between -x and -e
        'x|execute=s'     => sub { push @{$self->{'codes'}}, \$_[1]},
        '<>'              => sub { $self->parse_extra_opts(@_)     },
    ) or $self->print_help();
}

sub parse_extra_opts {
    my ( $self, $arg ) = @_;

    # do our own globbing in windows, this is convenient
    if ( $^O =~ /win32/i ) {
        if ( $arg =~ /[*?{}\[\]]/ ) { push @{ $self->{'items'} }, glob "$arg" }
        else { push @{ $self->{'items'} }, "$arg" }
    } else {
        push @{ $self->{'items'} }, "$arg";
    }
}

sub run {
    my $self = shift;

    $self->parse_opts();

    # -m is reserved for file mode
    my $default_mode =
        $0 =~ /perlcp/     ? 'copy'    :
        $0 =~ /perlln_s/   ? 'symlink' :
        $0 =~ /perlln/     ? 'link'    :
        $0 =~ /perlmv/     ? 'move'    :
        'rename';

    $self->{'dry_run'} and $self->{'verbose'}++;
    $self->{'mode'} //= $default_mode;

    if ( $self->{'list'} ) {
        $self->load_scriptlets();
        foreach my $key ( sort keys %{ $self->{'scriptlets'} } ) {
            print $self->{'verbose'}                        ?
                $self->format_scriptlet_source($key) . "\n" :
                "$key\n";
        }

        exit 0;
    }

    if ( $self->{'show'} ) {
        print $self->format_scriptlet_source( $self->{'show'} );
        exit 0;
    }

    if ( $self->{'write'} ) {
        die "Please specify code of scriptlet" unless @{ $self->{'codes'} }
            && !ref( $self->{'codes'}[0] );
        $self->store_scriptlet( $self->{'write'}, $self->{'codes'}[0] );
        exit 0;
    }

    if ( $self->{'delete'} ) {
        $self->delete_user_scriptlet( $self->{'delete'} );
        exit 0;
    }

    unless (@{ $self->{'codes'} }) {
        die 'FATAL: Must specify code (-e) or scriptlet name (-x/first argument)'
            unless $self->{'items'};
        push @{ $self->{'codes'} }, \( scalar shift @{ $self->{'items'} } );
    }
    # convert all scriptlet names into their code
    for (@{ $self->{'codes'} }) {
        $_ = $self->load_scriptlet($$_) if ref($_);
    }

    die "FATAL: Please specify some files in arguments\n"
        unless $self->{'items'};

    $self->rename();
}

sub print_version {
    print "perlmv version $App::perlmv::VERSION\n";
    exit 0;
}

sub print_help {
    my $self = shift;
    print <<'USAGE';
Rename files using Perl code.

Usage:

 # Show help
 perlmv -h

 # Execute a single scriptlet
 perlmv [options] <scriptlet> <file...>

 # Execute code from command line
 perlmv [options] -e <code> <file...>

 # Execute multiple scriptlets/command-line codes
 perlmv [options] [ -x <scriptlet> | -e <code> ]+ <file...>

 # Create a new scriptlet
 perlmv -e <code> -w <name>

 # List available scriptlets
 perlmv -l

 # Show source code of a scriptlet
 perlmv -s <name>

 # Delete scriptlet
 perlmv -d <name>

Options:

 -c  (--compile) Only test compile code, do not run it on the arguments
 -D <NAME> (--delete) Delete scriptlet
 -d  (--dry-run) Dry-run (implies -v)
 -e <CODE> (--execute) Specify Perl code to rename file (\$_). Can be specified
     multiple times.
 -f  (--files) Only process files, do not process directories
 -h  (--help) Show this help
 -l  (--list) list all scriptlets
 -M <MODE> (--mode) Specify mode, default is 'mv' (or 'm'). Use 'rename' or 'r'
     for rename (the same as mv but won't do cross devices), 'copy' or 'c' to
     copy instead of rename, 'symlink' or 's' to create a symbolic link, and
     'link' or 'l' to create a (hard) link.
 -o  (--overwrite) Overwrite (by default, ".1", ".2", and so on will be appended
     to avoid overwriting existing files)
 -p  (--parents) Create intermediate directories
 -R  (--recursive) Recursive
 -r  (--reverse) reverse order of processing (by default asciibetically)
 -S  (--no-symlinks) Do not process symlinks
 -s <NAME> (--show) Show source code for scriptlet
 -T  (--no-sort) do not sort files (default is sort ascibetically)
 -V  (--version) Print version and exit
 -v  (--verbose) Verbose
 -w <NAME> (--write) Write code specified in -e as scriptlet
 -x <NAME> Execute a scriptlet. Can be specified multiple times. -x is optional
     if there is only one scriptlet to execute, and scriptlet name is specified
     as the first argument, and there is no -e specified.

USAGE

    exit 0;
}

sub load_scriptlet {
    my ( $self, $name ) = @_;
    $self->load_scriptlets();
    die "FATAL: Can't find scriptlet `$name`"
        unless $self->{'scriptlets'}{$name};
    return $self->{'scriptlets'}{$name}{'code'};
}

sub load_scriptlets {
    my ($self) = @_;
    $self->{'scriptlets'} //= $self->find_scriptlets();
}

sub find_scriptlets {
    my ($self) = @_;
    my $res    = {};

    eval { require App::perlmv::scriptlets::std };
    if (%App::perlmv::scriptlets::std::scriptlets) {
        $res->{$_} = { code => $App::perlmv::scriptlets::std::scriptlets{$_},
                       from => "App::perlmv::scriptlets::std" }
            for keys %App::perlmv::scriptlets::std::scriptlets;
    }

    eval { require App::perlmv::scriptlets };
    if (%App::perlmv::scriptlets::scriptlets) {
        $res->{$_} = { code => $App::perlmv::scriptlets::scriptlets{$_},
                       from => "App::perlmv::scriptlets" }
            for keys %App::perlmv::scriptlets::scriptlets;
    }

    if (-d "/usr/share/perlmv/scriptlets") {
        local $/;
        for (glob "/usr/share/perlmv/scriptlets/*") {
            my $name = $_; $name =~ s!.+/!!;
            open my($fh), $_;
            my $code = <$fh>;
            $res->{$name} = { code => $code, from => $_ }
                if $code;
        }
    }

    if (-d "$self->{homedir}/.perlmv/scriptlets") {
        local $/;
        for (glob "$self->{homedir}/.perlmv/scriptlets/*") {
            my $name = $_; $name =~ s!.+/!!;
            open my($fh), $_;
            my $code = <$fh>;
            ($code) = $code =~ /(.*)/s; # untaint
            $res->{$name} = { code => $code, from => $_ }
                if $code;
        }
    }

    $res;
}

sub valid_scriptlet_name {
    my ($self, $name) = @_;
    $name =~ m/^[A-Za-z_][0-9A-Za-z_-]*$/;
}

sub store_scriptlet {
    my ($self, $name, $code) = @_;
    die "FATAL: Invalid scriptlet name `$name`\n"
        unless $self->valid_scriptlet_name($name);
    die "FATAL: Code not specified\n" unless $code;
    my $path = "$self->{homedir}/.perlmv";
    unless (-d $path) {
        mkdir $path or die "FATAL: Can't mkdir `$path`: $!\n";
    }
    $path .= "/scriptlets";
    unless (-d $path) {
        mkdir $path or die "FATAL: Can't mkdir `$path: $!\n";
    }
    $path .= "/$name";
    if ((-e $path) && !$self->{'overwrite'}) {
        die "FATAL: Can't overwrite `$path (use -o)\n";
    } else {
        open my($fh), ">", $path;
        print $fh $code;
        close $fh or die "FATAL: Can't write to $path: $!\n";
    }
}

sub delete_user_scriptlet {
    my ($self, $name) = @_;
    unlink "$self->{homedir}/.perlmv/scriptlets/$name";
}

sub compile_code {
    my ($self, $code) = @_;
    no strict;
    no warnings;
    local $_ = "-TEST";
    local $App::perlmv::code::TESTING = 1;
    local $App::perlmv::code::COMPILING = 1;
    eval "package App::perlmv::code; $code";
    die "FATAL: Code doesn't compile: code=$code, errmsg=$@\n" if $@;
}

sub run_code_for_cleaning {
    my ($self, $code) = @_;
    no strict;
    no warnings;
    local $_ = "-CLEAN";
    local $App::perlmv::code::CLEANING = 1;
    eval "package App::perlmv::code; $code";
    die "FATAL: Code doesn't run (cleaning): code=$code, errmsg=$@\n" if $@;
}

sub run_code {
    my ($self, $code) = @_;
    no strict;
    no warnings;
    my $orig_ = $_;
    local $App::perlmv::code::TESTING = 0;
    local $App::perlmv::code::COMPILING = 0;
    # It does need a package declaration to run it in App::perlmv::code
    my $res = eval "package App::perlmv::code; $code";
    die "FATAL: Code doesn't compile: code=$code, errmsg=$@\n" if $@;
    if (defined($res) && length($res) && $_ eq $orig_) { $_ = $res }
}

sub _sort {
    my $self = shift;
    $self->{sort_mode} == -1 ? (reverse sort @_) :
        $self->{sort_mode} == 1 ? (sort @_) :
            @_;
}

sub process_items {
    my ($self, $code, $code_is_final, $items) = @_;
    my $i = 0;
    while ($i < @$items) {
        my $item = $items->[$i];
        $i++;
        if ($item->{cwd}) {
            chdir $item->{cwd} or die "Can't chdir to `$item->{cwd}`: $!";
        }
        next if !$self->{'process_symlink'} && (-l $item->{real_name});
        if (-d $item->{real_name}) {
            next unless $self->{'process_dir'};
            if ($self->{'recursive'}) {
                my $cwd = getcwd();
                if (chdir $item->{real_name}) {
                    print "INFO: chdir `$cwd/$item->{real_name}` ...\n"
                        if $self->{'verbose'};
                    local *D;
                    opendir D, ".";
                    my @subitems =
                        $self->_sort(
                            map { {name_for_script => $_, real_name => $_} }
                            grep { $_ ne '.' && $_ ne '..' }
                                readdir D
                            );
                    closedir D;
                    $self->process_items($code, $code_is_final, \@subitems);
                    splice @$items, $i-1, 0, @subitems;
                    $i += scalar(@subitems);
                    $subitems[0]{cwd} = "$cwd/$item->{real_name}";
                    chdir $cwd or die "FATAL: Can't go back to `$cwd`: $!\n";
                } else {
                    warn "WARN: Can't chdir to `$cwd/$item->{real_name}`, ".
                        "skipped\n";
                }
            }
        }
        $self->process_item($code, $code_is_final, $item, $items);
    }
}

sub process_item {
    my ($self, $code, $code_is_final, $item, $items) = @_;

    local $App::perlmv::code::FILES =
        [map {ref($_) ? $_->{name_for_script} : $_} @$items];
    local $_ = $item->{name_for_script};

    my $old = $item->{real_name};
    my $aold = l_abs_path($old);
    die "Invalid path $old" unless defined($aold);
    my ($oldvol,$olddir,$oldfile)=File::Spec->splitpath($aold);
    my ($olddirvol,$olddirdir,$olddirfile) = File::Spec->splitpath(
        l_abs_path($olddir));
    my $aolddir = File::Spec->catpath($olddirvol, $olddirdir, '');
    local $App::perlmv::code::DIR    = $olddir;
    local $App::perlmv::code::FILE   = $oldfile;
    local $App::perlmv::code::PARENT = $olddirfile;

    $self->run_code($code);

    my $new = $_;
    # we use rel2abs instead of l_abs_path because path might not exist (yet)
    # and we don't want to check for actual existence
    my $anew = File::Spec->rel2abs($new);

    $self->{_exists}{$aold}++ if (-e $aold);
    return if $aold eq $anew;

    $item->{name_for_script} = $new;
    unless ($code_is_final) {
        push @{ $item->{intermediates} }, $new;
        return;
    }

    my $action;
    if (!defined($self->{mode}) || $self->{mode} =~ /^(rename|r)$/) {
        $action = "rename";
    } elsif ($self->{mode} =~ /^(move|mv|m)$/) {
        $action = "move";
    } elsif ($self->{mode} =~ /^(copy|cp|c)$/) {
        $action = "copy";
    } elsif ($self->{mode} =~ /^(symlink|sym|s)$/) {
        $action = "symlink";
    } elsif ($self->{mode} =~ /^(hardlink|h|link|l)$/) {
        $action = "link";
    } else {
        die "Unknown mode $self->{mode}, please use one of: ".
            "move (m), rename (r), copy (c), symlink (s), or link (l).";
    }

    my $orig_new = $new;
    unless ($self->{'overwrite'}) {
        my $i = 1;
        while (1) {
            if ((-e $new) || defined($anew) && exists $self->{_exists}{$anew}) {
                $new = "$orig_new.$i";
                $anew = l_abs_path($new);
                $i++;
            } else {
                last;
            }
        }
    }
    $self->{_exists}{$anew}++;
    delete $self->{_exists}{$aold} if $action eq 'rename' || $action eq 'move';
    print "DRYRUN: " if $self->{dry_run};
    print "$action " . join(" -> ",
        map {"`$_`"} $old, @{ $item->{intermediates} // []}, $new)."\n"
            if $self->{verbose};
    unless ($self->{dry_run}) {
        my $res;

        if ($self->{'parents'}) {
            my ($vol, $dir, $file) = File::Spec->splitpath($new);
            unless (-e $dir) {
                make_path($dir, {error => \my $err});
                for (@$err) {
                    my ($file, $message) = %$_;
                    warn "ERROR: Can't mkdir `$dir`: $message" .
                        ($file eq '' ? '' : " ($file)") . "\n";
                }
                return if @$err;
            }
        }

        my $err = "";
        if ($action eq 'move') {
            $res = File::Copy::move($old, $new);
            $err = $! unless $res;
        } elsif ($action eq 'rename') {
            $res = rename $old, $new;
            $err = $! unless $res;
        } elsif ($action eq 'copy') {
            $res = copy $old, $new;
            $err = $! unless $res;
            # XXX copy mtime, ctime, etc
        } elsif ($action eq 'symlink') {
            $res = symlink $old, $new;
            $err = $! unless $res;
        } elsif ($action eq 'link') {
            $res = link $old, $new;
            $err = $! unless $res;
        }
        warn "ERROR: $action failed `$old` -> `$new`: $err\n" unless $res;
    }
}

sub format_scriptlet_source {
    my ($self, $name) = @_;
    $self->load_scriptlets();
    die "FATAL: Scriptlet `$name` not found\n"
        unless $self->{scriptlets}{$name};
    "### Name: $name (from ", $self->{scriptlets}{$name}{from}, ")\n" .
    $self->{scriptlets}{$name}{code} .
    ($self->{scriptlets}{$name}{code} =~ /\n\z/ ? "" : "\n");
}

sub rename {
    my ($self, @args) = @_;
    my @items;
    if (@args) {
        @items = @args;
    } else {
        @items  = @{ $self->{'items'} // [] };
    }

    @items = map { {real_name=>$_, name_for_script=>$_} } $self->_sort(@items);

    if ($self->{_compiled}) {
        # another run, clean first
        $self->run_code_for_cleaning($_) for @{ $self->{'codes'} };
    }
    $self->{_exists} = {};
    local $self->{'recursive'} = $self->{'recursive'};
    for (my $i=0; $i < @{ $self->{'codes'} }; $i++) {
        my $code = $self->{'codes'}[$i];
        $self->compile_code($code) unless $self->{'compiled'};
        next if $self->{'check'};
        my $code_is_final = ($i == @{ $self->{'codes'} }-1);
        $self->{'recursive'} = 0 if $i;
        #print STDERR "DEBUG: items (before): ".dump(@items)."\n";
        $self->process_items($code, $code_is_final, \@items);
        #print STDERR "DEBUG: items (after): ".dump(@items)."\n";
    }
    $self->{'compiled'}++;
}

1;
# ABSTRACT: Rename files using Perl code

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv - Rename files using Perl code

=head1 VERSION

This document describes version 0.50 of App::perlmv (from Perl distribution App-perlmv), released on 2015-11-17.

=for Pod::Coverage ^(.*)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
