package App::Microsite::Assemble;
{
  $App::Microsite::Assemble::VERSION = '0.03';
}
# ABSTRACT: Assemble a microsite with Handlebars
use strict;
use warnings;
use File::Next;
use Path::Class;
use JSON;
use Try::Tiny;
use Text::Handlebars;
use Text::Xslate 'mark_raw';

sub assemble {
    my $class = shift;
    my $args = {
        wrapper_name     => 'wrapper.handlebars',
        content_name     => 'content.handlebars',
        config_name      => 'config.json',
        templates_dir    => 'templates/',
        fragments_dir    => 'fragments/',
        build_dir        => 'build/',
        missing_fragment => sub {
            my ($name, $paths) = @_;
            die "Fragment named '$name' does not exist: (paths: @$paths)\n";
        },
        @_,
    };

    for my $arg (qw/templates_dir fragments_dir build_dir/) {
        $args->{$arg} = dir($args->{$arg});
    }

    $args->{_seen_fragments} = {};

    $args->{build_dir}->mkpath;

    my %seen;

    my $dir_iter = File::Next::dirs($args->{templates_dir});
    while (defined(my $dir_name = $dir_iter->())) {
        my $dir = dir($dir_name);

        for my $child ($dir->children) {
            # File::Next recurses into subdirectories, so
            # we can skip them
            next if $child->is_dir;

            # any level in the hierarchy can have a wrapper.handlebars or config.json
            next if $child->basename eq $args->{wrapper_name}
                 || $child->basename eq $args->{config_name};

            # look, it's a page to generate!
            if ($child->basename eq $args->{content_name}) {
                my ($output, $config) = $class->_generate_page($dir, $args);
                my $target = $config->{target}
                    or die "No configured 'target' file for '$dir'. Add: \"target\":\"path.html\" to $child\n";

                my $outfile = $args->{build_dir}->file($target);

                if ($seen{$outfile}) {
                    die "Outfile '$outfile' for $dir was already built by $seen{$outfile}\n";
                }
                $seen{$outfile} = $dir;

                $outfile->spew(iomode => '>:encoding(UTF-8)', $output);

                next;
            }
        }
    }

    return {
        seen_fragments => $args->{_seen_fragments},
        built_files    => \%seen,
    };
}

sub _generate_page {
    my $class = shift;
    my $dir   = shift;
    my $args  = shift;

    my $input_file = $dir->file($args->{content_name});
    my $input = $input_file->slurp
        or die "Expected $args->{content_name} in $dir\n";

    my @paths;
    my $path_dir = $dir;
    while ($args->{templates_dir}->subsumes($path_dir)) {
        push @paths, "$path_dir";
        $path_dir = $path_dir->parent;
    }

    my $handlebars = $class->_handlebars(\@paths, $args);

    my %config = %{ $class->_merge_config($dir, $args) };

    $args->{_current_template} = [$input_file];

    # render the innermost content
    my $output = $handlebars->render_string($input, \%config);

    # now wrap it with all its parent dirs' wrapper.handlebars templates
    my $wrapper_dir = $dir;
    while ($args->{templates_dir}->subsumes($wrapper_dir)) {
        my $wrapper_file = $wrapper_dir->file($args->{wrapper_name});
        if (-e $wrapper_file) {
            $config{content} = mark_raw($output);
            my $wrapper = $wrapper_file->slurp;

            push @{ $args->{_current_template} }, $wrapper_file;
            $output = $handlebars->render_string($wrapper, \%config);
        }

        $wrapper_dir = $wrapper_dir->parent;
    }

    return ($output, \%config);
}

sub _handlebars {
    my $class = shift;
    my $path  = shift;
    my $args  = shift;

    my $hb;
    $hb = Text::Handlebars->new(
        # errors are caught and kind of suppressed inside xslate,
        # so make their presence more violently known
        # also, current_template provides more context for where the error
        # occurred
        die_handler => sub {
            my $error = shift;
            my $template = shift @{ $args->{_current_template} };
            $template = "$_ (wrapping $template)"
                for @{ $args->{_current_template} };
            warn "Unable to process $template\n    $error";
            exit 1;
        },
        helpers => {
            %{ $args->{helpers} || {} },
            fragment => sub {
                my ($context, $name) = @_;

                # {{fragment foo}} doesn't work, need {{fragment "foo"}}
                die "{{fragment NAME}} helper needs a quoted name\n"
                    if !$name;

                my @paths = @$path;
                s{^templates\b}{fragments} for @paths;

                for my $path (@paths) {
                    my $fragment = dir($path)->file($name);
                    if (-e $fragment) {
                        $args->{_seen_fragments}{$fragment}++;

                        my $content = $fragment->slurp(iomode => '<:encoding(UTF-8)');
                        if ($args->{fragment_filter}) {
                            $content = $args->{fragment_filter}->($content, $fragment, $name);
                        }

                        return mark_raw($hb->render_string($content));
                    }
                }

                my $content = $args->{missing_fragment}->($name, \@paths);
                return mark_raw($hb->render_string($content));
            },
        },
        suffix => '.partial',
        path   => $path,
    );
}

# merge all the config.json's in this hierarchy
sub _merge_config {
    my $class = shift;
    my $dir   = shift;
    my $args  = shift;

    my %config;

    my $config_dir = $dir;
    while ($args->{templates_dir}->subsumes($config_dir)) {
        my $config_file = $config_dir->file($args->{config_name});
        if (-e $config_file) {
            my $config_contents = $config_file->slurp;

            # provide more context for JSON syntax errors
            try {
                # more specific dirs override config from wrapper dirs
                %config = (
                    %{ from_json($config_contents) },
                    %config,
                );
            } catch {
                die "Parse error in $config_file:\n    $_\n";
            };
        }

        $config_dir = $config_dir->parent;
    }

    return \%config;
}

1;

__END__

=pod

=head1 NAME

App::Microsite::Assemble - Assemble a microsite with Handlebars

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This module assembles F<templates/> into fully-baked pages.

Your project should contain a F<fragments/> subdirectory, filled with files that contain bits of copy. Any template can use C<{{fragment "copy-file-name"}}> to inline the text from that file.

Subdirectories of F<templates/> can establish a hierarchy of wrappers. For example, you might have F<templates/basic/contact/> which is page C<contact> wrapped by wrapper C<basic>. The F<templates/basic/contact/> directory would have a F<content.handlebars> (the body of the page) and F<config.json> (for setting page title, etc).

Any directory in the hierarchy can have a F<wrapper.handlebars> which wraps everything below it. So the top-level F<templates/> could have a very generic F<wrapper.handlebars> that sets up C<< <html> >> etc. Subdirectories under F<templates/> can provide more specific wrappers, in case where many pages share the same structure. So if your site has a bunch of pages divided into three different layouts, you might have three subdirectories under F<templates/> to manage your three wrappers.

Similarly, any directory can have a F<config.json> which will combine in the usual way; files deeper in the hierarchy override settings from their upwards directories. Config variables will be provided in the template and its wrappers. This is intended for things like your generic F<templates/wrapper.handlebars> setting the page title, using the C<{{title}}> variable.

You can put partials in any directory under F<templates/> and they will cascade; deeper partials will shadow shallower partials.

Finally, the F<fragments/> directory structure should match F<templates/>. The search path for fragment names works just like everything else.

=head1 AUTHORS

=over 4

=item *

Shawn M Moore <code@sartak.org>

=item *

Michael Reddick <michael.reddick@iinteractive.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
