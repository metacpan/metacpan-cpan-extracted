package App::Kritika;

use strict;
use warnings;

our $VERSION = '0.04';

use JSON ();
use Cwd qw(abs_path);
use HTTP::Tiny;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{base_url} = $params{base_url} || 'https://kritika.io';
    $self->{token}   = $params{token} or die 'token required';
    $self->{root}    = $params{root};
    $self->{head}    = $params{head};
    $self->{changes} = $params{changes};

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

    if ( my $root = $self->{root} ) {
        $root = abs_path($root);
        $path =~ s{^$root}{};
        $path =~ s{^/}{};
    }

    my $response = $ua->post_form(
        "$self->{base_url}/validate",
        {
            $self->{head}    ? ( head    => $self->{head} )    : (),
            $self->{changes} ? ( changes => $self->{changes} ) : (),
            content => $content,
            path    => $path
        },
        { headers => { Authorization => 'Token ' . $self->{token} } }
    );

    if ($response->{status} eq '599') {
        my $content = $response->{content};
        $content = substr($content, 0, 64) . '[...]' if length $content > 64;
        die "Internal error: $response->{status} $content";
    }

    die "Remote error: $response->{status} $response->{reason}\n"
      unless $response->{success};

    return JSON::decode_json( $response->{content} );
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
