package App::mookview;
use 5.008005;
use strict;
use warnings;
use Plack::Request;
use Path::Tiny qw/path/;
use Text::Markdown::Discount qw/markdown/;
use Text::Xslate qw/mark_raw/;
use Number::Format qw/format_number/;
use File::ShareDir qw/dist_dir/;
use Plack::App::Directory;
use Try::Tiny;
use Encode;

our $VERSION = "0.03";

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my $name = shift or return;
    my $file_path = path($name);
    return unless $file_path->is_file();
    $self->{file_path} = $file_path;
    $self->{xslate} = Text::Xslate->new(
        path => $self->local_or_share_path( [qw/share templates/] )
    );
    return $self;
}

sub local_or_share_path {
    my ($self, $p) = @_;
    my $path = path(@$p);
    return $path if $path->exists;
    try {
        shift @$p;
        $path = path(dist_dir('App-mookview'), @$p);
    };
    return $path;
}

sub psgi_app {
    my $self = shift;
    return sub {
        my $req  = Plack::Request->new(shift);
        my $path = $req->path_info;
        return $self->return_markdown($path) if $path eq '/';
        return $self->return_css($path) if $path =~ m!^/css/.+!;
        Plack::App::Directory->new->to_app->($req->env);        
    };
}

sub return_404 {
    return [404, [ 'Content-Type' => 'text/plain' ], ['Not Found'] ];
}

sub return_css {
    my ($self, $path) = @_;
    return $self->return_404 unless $path;
    my ($name) = $path =~ m!/([^/]+?)$!;
    my $local_path = $self->local_or_share_path([qw/share static css/, $name]);
    return $self->return_404 unless $local_path;
    my $css = $local_path->slurp();
    return [200, [ 'Content-Type' => 'text/css', 'Content-Length' => length $css ], [ encode_utf8($css) ] ];
}

sub return_markdown {
    my ($self, $path) = @_;
    my $text = $self->{file_path}->slurp_utf8();
    my $length = format_number(length $text);
    $text = $self->filter_markdown($text);
    my $stock = '';   my $page = 1;  my $content = '';
    my $limit = 1100;
    for my $t (split /\n/, $text) {
        $stock .= $t . "\n";
        if (length $stock > $limit) {
            $content = $self->add_markdown_to_html($content, $stock, $page);
            $stock = '';
            $page++;
        }
    }
    $content = $self->add_markdown_to_html($content, $stock, $page);
    my $html = $self->{xslate}->render('preview.tx', {
        content => mark_raw($content),
        filename => $self->{file_path}->basename,
        length => $length
    });
    $html = encode_utf8($html);
    return [200, [
        'Content-Type' => 'text/html; charset=utf8',
        'Content-Length' => length $html,
    ], [ $html ] ];
}

sub filter_markdown {
    my ($self, $markdown) = @_;
    $markdown =~ s!^```.*?\n(.+?)\n```.*?$!
        my $code = '';
        $code .= "    $_\n" for split /\n/, $1;
        $code;
    !gmse;
    return $markdown;
}

sub add_markdown_to_html {
    my ($self, $html, $markdown, $page) = @_;
    $html .= '<div class="page">' . markdown($markdown) . "</div>\n";
    $html .= "<div class=\"page-number\"><span>$page</span></div>\n";
    return $html;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::mookview - View Markdown texts as a "Mook-Book" style

=head1 SYNOPSIS

    mookview text.md

Then open "http://localhost:5000/" with your web-browser.

You can use "plackup options" in command line.

    mookview --port 9000 text.md

=head1 DESCRIPTION

App::mookview is Plack/PSGI application for viewing Markdown texts as a "Mook-book".

"mookview command" is useful when you are writing a book using Markdown format.

=head2 Features

=over 4

=item * 2 columns page layouts

=item * count characters

=item * support fenced code blocks in Markdown

=item * use the new font in OSX "mervericks"

=back

=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Wada E<lt>yusuke@kamawada.comE<gt>

=cut

