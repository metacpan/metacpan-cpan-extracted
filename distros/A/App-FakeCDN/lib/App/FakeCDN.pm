package App::FakeCDN;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.01";

use Path::Tiny;
use Plack::MIME;

use Mouse;
use Mouse::Util::TypeConstraints;

subtype 'App::FakeCDN::Path' => as class_type('Path::Tiny');
coerce 'App::FakeCDN::Path'
    => from 'Str'
    => via { Path::Tiny::path($_) };

has cache => (
    is => 'ro',
    isa => 'Object',
    default => sub {
        require Cache::Memory::Simple;
        Cache::Memory::Simple->new;
    },
);

has root => (
    is       => 'ro',
    isa      => 'App::FakeCDN::Path',
    required => 1,
    coerce   => 1,
);

has expiration => (
    is  => 'ro',
    isa => 'Int',
);

no Mouse;

sub to_app {
    my $self = shift;

    sub {
        my $env = shift;

        my $path  = $env->{PATH_INFO} // '';
        my $query = $env->{QUERY_STRING} // '';

        if ($path =~ /\0/ || $query =~ /\0/) {
            return $self->res_400;
        }
        $path =~ s!^/!!;

        my ($data, $content_type) = $self->get_content($path, $query);

        return $self->res_404 unless $data;

        return [ 200, [
            'Content-Type'   => $content_type,
            'Content-Length' => length($data),
        ], [ $data ] ];
    };
}

sub res_400 {
    [400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

sub res_404 {
    [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['not found']];
}

sub get_content {
    my ($self, $path, $query) = @_;

    my $mime_type = Plack::MIME->mime_type($path) // 'application/octet-stream';
    my $is_binary = is_binary($mime_type);

    unless ($is_binary) {
        my $encoding = $self->encoding || 'utf-8';
        $mime_type .= "; charset=$encoding";
    }

    my $content = $self->get_stuff($path, $query);

    ($content, $mime_type);
}

sub is_binary {
    my $mime_type = shift;

    $mime_type !~ /\b(?:text|xml|javascript|json)\b/;
}

sub get_stuff {
    my ($self, $path, $query) = @_;
    my $key = $path . $query;

    if (my $val = $self->cache->get($key)) {
        return $val;
    }
    else {
        my $file = $self->root->child($path);
        return unless -e -f $file;

        my $val = $file->slurp;
        $self->cache->set($key, $val, $self->expiration || ());
        return $val;
    }
}

sub parse_options {
    my ($class, @argv) = @_;

    require Getopt::Long;
    require Pod::Usage;

    my $p = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case auto_help pass_through bundling/]
    );
    $p->getoptionsfromarray(\@argv, \my %opt, qw/
        root=s
        expiration=i
    /) or Pod::Usage::pod2usage();
    Pod::Usage::pod2usage() if !$opt{root};

    (\%opt, \@argv);
}

sub run {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    if (!$args{listen} && !$args{port} && !$ENV{SERVER_STARTER_PORT}) {
        $args{port} = 4907;
    }
    require Plack::Loader;
    Plack::Loader->auto(%args)->run($self->to_app);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::FakeCDN - fake CDN server emulator

=head1 SYNOPSIS

    use App::FakeCDN;
    my $fake_cdn = App::FakeCDN->new(root => 'static');
    $fake_cdn->to_app;

=head1 DESCRIPTION

App::FakeCDN launches fake CDN server emulator.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

