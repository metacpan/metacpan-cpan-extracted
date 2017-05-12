# TODO:
# - Generate a Makefile to bring everything up to date
#   - Use tt with Makefile template
package Cog::Maker;
use Mo;
extends 'Cog::Base';

use Template::Toolkit::Simple;
use IO::All;
use IPC::Run;
use Pod::Simple::HTML;
use File::Copy;
use File::Path;

sub make {
    my $self = shift;
    File::Path::mkpath $self->app->build_root;
    File::Path::mkpath $self->app->webapp_root;
    $self->make_config_js();
    $self->make_url_map_js();
    $self->make_all_js();
    $self->make_all_css();
    $self->make_image();
    $self->make_index_html;
}

sub make_assets {
    my $self = shift;
    my $files = $self->config->files_map;
    my $root = $self->app->build_root;

    for my $file (sort keys %$files) {
        my $plugin = $files->{$file}[0];
        my $source = $files->{$file}[1];
        my $target = "$root/$file";
        if ($ENV{COG_SYMLINK_INSTALL}) {
            unless (-l $target and readlink($target) eq $source) {
                unlink $target;
                io($target)->assert->symlink($source);
                print "> link $source => $target\n";
            }
        }
        else {
            unless (
                -f $target and
                not(-l $target) and
                io($target)->all eq io($source)->all
            ) {
                unlink $target;
                io($target)->assert->print(io($source)->all);
                printf "Update: %-25s %s\n", $plugin, $file;
            }
        }
    }
}

sub make_config_js {
    my $self = shift;
    my $config_path = $self->app->config_file;
    my $data = {
        json => $self->json->encode(YAML::XS::LoadFile($config_path)),
    };
    my $build = $self->app->build_root;
    my $javascript = tt()
        ->path(["$build/template/"])
        ->data($data)
        ->post_chomp
        ->render('config.js');
    io("$build/js/config.js")->print($javascript);
}

sub make_url_map_js {
    my $self = shift;
    my $data = {
        json => $self->json->encode($self->config->url_map),
    };
    my $build = $self->app->build_root;
    my $javascript = tt()
        ->path(["$build/template/"])
        ->data($data)
        ->post_chomp
        ->render('url-map.js');
    io("$build/js/url-map.js")->print($javascript);
}

sub make_all_js {
    my $self = shift;
    my $build = $self->app->build_root;
    my $js = "$build/js";

    my $data = {
        build => $build,
        list => join(
            ' ',
            @{$self->config->js_files},
            map {
                s/\.coffee$/\.js/;
                $_;
            } @{$self->config->coffee_files}
        )
    };
    my $makefile = tt()
        ->path(["$build/template/"])
        ->data($data)
        ->post_chomp
        ->render('js-mf.mk');
    io("$js/Makefile")->print($makefile);

    system("(cd $js; make)") == 0 or die;
    # TODO - Make fingerprint file here instead of Makefile
    my ($file) = glob("$js/all-*.js") or die;
    copy $file, $self->app->webapp_root;
    $file =~ s!.*/!!;
    $self->config->all_js_file($file);
}

sub make_all_css {
    my $self = shift;
    my $build = $self->app->build_root;
    my $css = "$build/css";

    my $data = {
        list => join(' ', @{$self->config->css_files}),
    };
    my $makefile = tt()
        ->path(["$build/template/"])
        ->data($data)
        ->post_chomp
        ->render('css-mf.mk');
    io("$css/Makefile")->print($makefile);

    system("(cd $css; make)") == 0 or die;
    my ($file) = glob("$css/all-*.css") or die;
    copy $file, $self->app->webapp_root;
    $file =~ s!.*/!!;
    $self->config->all_css_file($file);
}

sub make_image {
    my $self = shift;
    my $build = $self->app->build_root;
    my $webapp = $self->app->webapp_root;
    symlink "$build/image", "$webapp/image"
        unless -e "$webapp/image";
}

sub make_index_html {
    my $self = shift;
    my $build = $self->app->build_root;
    my $webapp = $self->app->webapp_root;
    my $data = +{%{$self->config}};
    my $html = tt()
        ->path(["$build/template/"])
        ->data($data)
        ->post_chomp
        ->render('index-table.html');
    io("$webapp/index.html")->print($html);
}

sub make_clean {
    my $self = shift;
    my $build_root = $self->app->build_root
        or die "build_root not available";
    my $webapp_root = $self->app->webapp_root
        or die "webapp_root not available";
    for my $file_dir (qw(coffee css image js template)) {
        File::Path::rmtree "$build_root/$file_dir"
            if -e "$build_root/$file_dir";
    }
    File::Path::rmtree $webapp_root if -e $webapp_root;
}

1;
