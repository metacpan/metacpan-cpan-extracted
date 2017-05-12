package CSS::Watcher;

use strict; 
use warnings;

use Carp;
use Data::Dumper;

use Log::Log4perl qw(:easy);
use File::Slurp qw/read_file write_file/;
use Path::Tiny;
use Digest::MD5 qw/md5_hex/;
use List::MoreUtils qw(any);

use CSS::Watcher::Parser;
use CSS::Watcher::ParserLess;
use CSS::Watcher::Monitor;

our $VERSION = '0.5.0';

use constant DEFAULT_HTML_STUFF_DIR => '~/.emacs.d/ac-html-csswatcher/completion/';

sub new {
    my $class= shift;
    my $options = shift;

    return bless ({
        outputdir => $options->{'outputdir'} // DEFAULT_HTML_STUFF_DIR,
        parser_css => CSS::Watcher::Parser->new(),
        parser_less => CSS::Watcher::ParserLess->new(),
    }, $class);
}

sub update {
    my $self = shift;
    my $obj = shift;

    # check what is the monobj. file? dir?
    if (-f $obj || -d $obj) {
        my $proj_dir = $self->get_project_dir ($obj);
        return unless (defined $proj_dir);

        INFO "Update project: $proj_dir";

        my $prj = $self->_get_project ($proj_dir);
        $prj->{parsed_files} = [];    # clean old parsed file list

        my $changes = 0;

        my (@ignore, @allow, @skip_dirs);
        my $cfg = path($proj_dir)->child('.csswatcher');

        # clear project cache if .csswatcher changed
        if ($prj->{monitor}->is_changed($cfg)) {
            INFO ('.csswatcher changed, resetting');
            $prj->{monitor}->make_dirty();
            delete $prj->{parsed};
            $changes++;
        }

        if (-f $cfg) {
            if (open (CFG, '<:encoding(UTF-8)', $cfg)) {
                while (<CFG>) {
                    chomp;
                    (m/^\s*ignore:\s*(.*?)\s*$/i) ? push @ignore,    $1 :
                    (m/^\s*skip:\s*(.*?)\s*$/i)   ? push @skip_dirs, $1 :
                    (m/^\s*use:\s*(.*?)\s*$/i)    ? push @allow,     $1 : 1;
                }
                close CFG;
            }
        }

        # scan new or changed files, cache them
        $prj->{monitor}->scan (
            sub {
                my $file = shift;

                return if (any {$_ eq $file} @{$prj->{parsed_files}});

                my $allow = 0;
                foreach (@allow) {
                    if ($file =~ m/$_/) {
                        $allow = 1;
                        last;
                    }
                }
                unless ($allow) {
                    foreach (@ignore) {
                        if ($file =~ m/$_/) {
                            INFO " Ignored $file =~\"$_\"";
                            return;
                        }
                    }
                }
                ($file =~  m/\.css$/) ? $changes += 1 && $self->_parse_css              ($prj, $file) :
                ($file =~ m/\.less$/) ? $changes += 1 && $self->_parse_less_and_imports ($prj, $file) : 1;

            }, \@skip_dirs);
        INFO "Update done.";
        return ($changes, $proj_dir);
    }
    return;
}

sub _parse_css {
    my ($self, $project, $file) = @_;

    INFO " (Re)parse css: $file";
    my $data = read_file ($file);
    my ($classes, $ids) = $self->{parser_css}->parse_css ($data);
    $project->{parsed}{$file} = {CLASSES => $classes,
                                 IDS => $ids};
    push @{$project->{parsed_files}}, $file;
    return 1;
}

sub _parse_less {
    my ($self, $project, $file) = @_;

    INFO " (Re)parse less: $file";
    my ($classes, $ids, $requiries) = $self->{parser_less}->parse_less ($file);
    $project->{parsed}{$file} = {CLASSES => $classes,
                                 IDS => $ids};
    push @{$project->{parsed_files}}, $file;

    # normilize path of requiried files, they may have .././
    # eval {
    #     $project->{imports_less}{$file} =
    #         [ map {path($file)->parent->child($_)->realpath()->stringify} @{$requiries} ];
    # };
    # if ($@) {
    #     WARN $@;
    # }
        $project->{imports_less}{$file} =
            [ map {path($file)->parent->child($_)->realpath()->stringify} @{$requiries} ];
    return 1;
}

sub _parse_less_and_imports {
    my ($self, $project, $file) = @_;

    my $parsed_files = 1; # 1, cause we parse $file for sure., ++ if dependencies parsed too

    eval {
        $self->_parse_less ($project, $file);

        while (my ($less_fname, $imports) = each %{$project->{imports_less}}) {
            foreach (@{$imports}) {
                if ($file eq $_) {
                    next if (any {$_ eq $less_fname} @{$project->{parsed_files}});
                    INFO sprintf "  %s required by %s, parse them too.", path($file)->basename, path($less_fname)->basename;
                    $self->_parse_less($project, $less_fname);
                    $parsed_files++;
                }
            }
        }
        1;
    } or do {
        ERROR qq{Less parse fail: "$file", reason: "$@"};
        return 1;
    };

    return $parsed_files;
}

sub project_stuff {
    my $self = shift;
    my $proj_dir = shift;

    my $prj = $self->_get_project ($proj_dir);

    # build unique tag - class,id
    my (%classes, %ids);
    my ($total_classes, $total_ids) = (0, 0);
    while ( my ( $file, $completions ) = each %{$prj->{parsed}} ) {
        while ( my ( $tag, $classes ) = each %{$completions->{CLASSES}} ) {
            foreach (keys %{$classes}) {
                $classes{$tag}{$_} .= 'Defined in ' . path( $file )->relative( $proj_dir ) . '\n';
                $total_classes++;
            }
        }
    }
    while ( my ( $file, $completions ) = each %{$prj->{parsed}} ) {
        while ( my ( $tag, $ids ) = each %{$completions->{IDS}} ) {
            foreach (keys %{$ids}) {
                $ids{$tag}{$_} .= 'Defined in ' . path( $file )->relative( $proj_dir ) . '\n';
                $total_ids++;
            }
        }
    }
    INFO "Total for $proj_dir:";
    INFO " Classes: $total_classes, ids: $total_ids";

    return (\%classes, \%ids);
}

# clean old output html complete stuff and build new
sub build_ac_html_stuff {
    my $self = shift;
    my $proj_dir = shift;

    my ($classes, $ids) = $self->project_stuff ($proj_dir);

    my $ac_html_stuff_dir = path ($self->{outputdir})->child (md5_hex( ''.$proj_dir ));
    my $attrib_dir = path ($ac_html_stuff_dir)->child ('html-attributes-complete');

    $attrib_dir->remove_tree({safe => 0});
    $attrib_dir->mkpath;

    while ( my ( $tag, $class ) = each %{$classes} ) {
        my $fname = File::Spec->catfile ($attrib_dir, $tag . '-class');
        DEBUG "Write $fname";
        write_file ($fname, join "\n", map {
            $_ . ' ' . $class->{$_} } sort keys %{$class});
    }
    while ( my ( $tag, $id ) = each %${ids} ) {
        my $fname = File::Spec->catfile ($attrib_dir, $tag . '-id');
        DEBUG "Write $fname";
        write_file ($fname, join "\n", map {
            $_ . ' ' . $id->{$_} } sort keys %{$id});
    }
    DEBUG "Done writing. Reply to client.";
    return $ac_html_stuff_dir;
}

sub get_html_stuff {
    my $self = shift;
    my $obj = shift;

    my ($changes, $project_dir) = $self->update ($obj);
    return unless defined $changes;

    my $prj = $self->_get_project ($project_dir);

    my $ac_html_stuff_dir;

    if ($changes) {
        $ac_html_stuff_dir = $self->build_ac_html_stuff ($project_dir);
        $prj->{'ac_html_stuff'} = $ac_html_stuff_dir;
    } else {
        $ac_html_stuff_dir = $prj->{'ac_html_stuff'};
    }
    return ($project_dir, $ac_html_stuff_dir);
}

sub _get_project {
    my $self = shift;
    my $dir = shift;
    return unless defined $dir;

    unless (exists $self->{PROJECTS}{$dir}) {
        $self->{PROJECTS}{$dir} = 
            bless ( {monitor => CSS::Watcher::Monitor->new({dir => $dir})}, 'CSS::Watcher::Project' );
    }
    return $self->{PROJECTS}{$dir};
}

# Lookup for project dir similar to projectile.el
sub get_project_dir {
    my $self = shift;
    my $obj = shift;
    
    my $pdir = ! defined ($obj) ? undef:
               (-f $obj) ? path ($obj)->parent :
               (-d $obj) ? $obj : undef;
    return unless (defined $pdir);

    $pdir = path( $pdir );

    foreach (qw/.projectile .csswatcher .git .hg .fslckout .bzr _darcs/) {
        if (-e ($pdir->child( $_ ))) {
            return $pdir;
        }
    }
    return if ($pdir->is_rootdir());
    #parent dir
    return $self->get_project_dir ($pdir->parent);
}

1;

__END__

=head1 NAME

CSS::Watcher - class, id completion for ac-html.

=head1 SYNOPSIS

   use CSS::Watcher;
   my $cw = CSS::Watcher->new ();

   my ($project_dir, $ac_html_stuff_dir) = $cw->get_html_stuff ('~/work/css/');
   if (!defined $ac_html_stuff_dir) {
      print "oops, there no css files "
   }

=head1 DESCRIPTION

Watch for changes in css less files, parse them and populate ac-html completion.
Supported imports in less, reparse if imported file changed.

=head1 AUTHOR

Olexandr Sydorchuk (olexandr.syd@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Olexandr Sydorchuk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
