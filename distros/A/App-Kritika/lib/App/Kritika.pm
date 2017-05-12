package App::Kritika;

use strict;
use warnings;

our $VERSION = '0.03';

use JSON ();
use Cwd qw(abs_path);
use HTTP::Tiny;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{base_url} = $params{base_url} or die 'base_url required';
    $self->{token}    = $params{token}    or die 'token required';
    $self->{root}     = $params{root};

    $self->{ua} = $params{ua} || HTTP::Tiny->new;

    return $self;
}

sub validate {
    my $self = shift;
    my ($path) = @_;

    $path = abs_path($path);

    my $content = do {
        local $/;
        open my $fh, '<', $path or die "Can't open file '$path': $!";
        <$fh>;
    };

    my $ua = $self->{ua};

    if (my $root = $self->{root}) {
        $root = abs_path($root);
        $path =~ s{^$root}{};
        $path =~ s{^/}{};
    }

    my $response = $ua->post_form(
        "$self->{base_url}/validate",
        {
            content => $content,
            path    => $path
        },
        {headers => {Authorization => 'Token ' . $self->{token}}}
    );

    die
"Remote error: $response->{status} $response->{reason}; $response->{content}\n"
      unless $response->{success};

    return JSON::decode_json($response->{content});
}

1;
__END__
=pod

=head1 NAME

App::Kritika - kritika.io integration

=head1 DESCRIPTION

You want to look at C<script/kritika> documentation instead. This is just an
implementation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<viacheslav.t@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
