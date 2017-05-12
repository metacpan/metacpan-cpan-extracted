package App::makedpkg;
#ABSTRACT: Facilitate building Debian packages with templates
our $VERSION = '0.05'; #VERSION
use strict;
use v5.10.0;

use base qw(App::Cmd::Simple);
 
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy ();
use Text::Template qw(fill_in_file);
use Config::Any;
use File::ShareDir qw(dist_dir);

our $dist_dir = dist_dir('App-makedpkg');

sub opt_spec {
    return (
        [ "config|c=s", "configuration file" ],
        [ "verbose|v", "verbose output" ],
        [ "templates|t=s", "template directory" ],
        [ "dry|n", "don't build, just show" ],
        [ "prepare|p", "prepare build" ],
        [ "force|f", "use the force, Luke!" ],
        [ "init", "initialize template directory makedpkg/" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
      
    $self->{config} = $self->read_config($opt->config);

    if (!defined $opt->templates) {
        if (-d 'makedpkg') {
            $opt->{templates} = 'makedpkg';
        } else {
            $opt->{templates} = $dist_dir;
        }
    }

    unless ( -d $opt->templates ) {
        die "error reading template directory ".$opt->templates."\n";
    }
}

sub read_config {
    my ($self, $file) = @_;

    my $config = eval {
        if (defined $file) {
            Config::Any->load_files({ files => [$file], use_ext => 1, flatten_to_hash => 1 });
        } else {
            Config::Any->load_stems({ stems => ['makedpkg'], use_ext => 1, flatten_to_hash => 1 });
        }
    };

    if ($config && keys %$config) {
        ($file) = keys %$config;
        ($config) = values %$config;
    } else {
        $config = undef;
    }

    if ( ref ($config // '') ne 'HASH' ) {
        die "error reading config file $file\n";
    }

    return $config;
}

sub expand_command {
    my ($cmd, $out) = @_;

#    use IPC::Open3;
#    use File::Spec;
#    use Symbol qw(gensym);
#    open(NULL, ">", File::Spec->devnull);
#    my $pid = open3(gensym, \*PH, ">&NULL", $cmd);
#    while( <PH> ) { $out .= $_ }
#    waitpid($pid, 0);

    $out = `$cmd`;
    die "`$cmd` died with exit code ".($?>>8)."\n" if $?;
    chomp $out;

    return $out;
}

sub expand_config {
    my $h = $_[0];
    return if (ref $h || "") ne 'HASH';
    foreach my $key (keys %$h) {
        my $v = $h->{$key};
        if ( !ref $v and $v =~ /^`(.+)`$/ ) {
            $h->{$key} = expand_command($1);
        } else {
            expand_config($v);
        }
    }
}

sub list_dir {
    my ($dir) = @_;
    opendir(my $dh, $dir) or die "failed to open $dir: $!\n";
    my @files = map {
        my $f = $_;
        -d "$dir/$_" ? 
           map { "$f/$_" } @{ list_dir("$dir/$_") }
        : $_;
    } grep { /^[^.]+/ } readdir($dh);
    closedir $dh;
    return \@files;
}

sub execute {
    my ($self, $opt, $args) = @_;

    expand_config($self->{config});
    $self->{config}->{verbose} ||= $opt->verbose ? 1 : 0;

    if ($opt->verbose) {
        $self->_dump( $self->{config} );
    }

    if ($opt->init) {
        return $self->init_templates($opt, $args);
    }

    $self->prepare_debuild($opt, $args);

    $self->exec_debuild($opt, $args);
}

sub prepare_debuild {
    my ($self, $opt, $args) = @_;

    $self->{config}{build} //= { };
    $self->{config}{build}{directory} //= 'debuild';

    my $dir = $self->{config}{build}{directory};
    say "building into $dir" if $opt->verbose;
    return if $opt->dry;

    remove_tree($dir);
    make_path("$dir/debian");

    my $conf = $self->{config};
    my $build_dir = $conf->{build}{directory};

    # copy and fill in template files
    my $template_dir = $opt->templates;
    my $template_files = list_dir($template_dir);

    # say "templates in $template_dir\n";
    foreach my $file (sort @$template_files) {
        my $template = $opt->templates."/$file";
        next unless -f $template;

        $self->_create_debian_file( 
            $opt, $file,
            fill_in_file($template, HASH => $conf)
        );
    }

    # execute commands before build
    foreach (@{ $self->{config}{build}{before} || [ ] }) {
        say "before: $_" if $opt->verbose;
        `$_`;
        die "failed to run $_\n" if $?;
    }

    if (my $files = $self->{config}{build}{files}) {
        my @install;
    
        foreach my $source (sort keys %{ $files->{copy} || { } }) {
            if ($source =~ qr{^(.*)/\*$}) {
                make_path(my $path = "$build_dir/$1");
                `cp -r $source $path`;
            } else {
                make_path($1) if $source =~ qr{^(.*)/[^/]+$};
                `cp -r $source $build_dir/$source`;
            }
            die "failed to copy $source\n" if $?;
            
            push @install, "$source " . $files->{copy}->{$source};
        }

        if ($files->{to} and $files->{from}) {
            foreach my $from (@{ $files->{from} }) {
                if ($from =~ qr{^(.*)/[^/]+$}) {
                    make_path("$build_dir/$1"); 
                }
                `cp -r $from $build_dir/$from`;

                my $target = $from;
                $target =~ s{/?[^/]+$}{};
                $target = "/$target" if $target ne '';
                push @install, "$from ".$files->{to}.$target;
            }
        }

        unless ( grep { $_ eq 'install' } @$template_files ) {
            $self->_create_debian_file( $opt, 
                'install', join("\n", @install, '') );
        }
    }
}

sub _create_debian_file {
    my ($self, $opt, $name, $contents) = @_;

    my $filename = $self->{config}{build}{directory} . "/debian/$name";
    make_path(dirname($filename));

    open my $fh, ">", $filename;
    print $fh $contents;
    close $fh;

    say $filename if $opt->verbose;
}

sub exec_debuild {
    my ($self, $opt, $args) = @_;

    return if $opt->prepare;
    
    my $command = $self->{config}{build}{command} || 'debuild';

    if ($opt->dry) {
        say "exec $command";
    } else {
        chdir $self->{config}{build}{directory};
        exec $command;
    }
}

sub init_templates {
    my ($self, $opt) = @_;

    my $template_dir = $opt->templates;
    $template_dir = 'makedpkg' if $template_dir eq $dist_dir;
    make_path($template_dir) unless $opt->dry;

    my $templates = list_dir($dist_dir);
    foreach my $file (sort @$templates) {
        if (-e "$template_dir/$file" and !$opt->force) {
            say "kept $template_dir/$file";
        } else {
            say "created $template_dir/$file";
            unless ($opt->dry) {
                if ($file =~ /\//) {
                    make_path(dirname("$template_dir/$file"));
                }
                File::Copy::copy("$dist_dir/$file", "$template_dir/$file");
            }
        }
    }

    return;
}

sub _dump {
    my ($self, $data) = @_;
    # Config::Any requires any of 'YAML::XS', 'YAML::Syck', or 'YAML'
    for my $pkg (qw(YAML::XS YAML::Syck YAML)) {
        eval "require $pkg";
        unless ( $@ ) { 
            my $dump = eval "${pkg}::Dump(\$data);";
            $dump =~ s/\n$//m;
            say "$dump\n---";
            return; 
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::makedpkg - Facilitate building Debian packages with templates

=head1 VERSION

version 0.05

=head1 DESCRIPTION

See the command line client L<makedpkg> for more documentation.

=head1 SEE ALSO

Several CPAN modules exist to create Debian packages for CPAN modules, e.g.
L<Debian::Perl>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
