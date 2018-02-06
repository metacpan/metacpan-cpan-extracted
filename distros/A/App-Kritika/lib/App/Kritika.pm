package App::Kritika;

use strict;
use warnings;

our $VERSION = '0.05';

use JSON ();
use Cwd qw(abs_path);
use HTTP::Tiny;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{base_url} = $params{base_url} || 'https://kritika.io';
    $self->{token} = $params{token} or die 'token required';
    $self->{root} = $params{root};

    $self->{ua} = $params{ua} || HTTP::Tiny->new;

    $self->{diff_ref}      = $params{diff_ref};
    $self->{diff_snapshot} = $params{diff_snapshot};
    $self->{diff_branch}   = $params{diff_branch};

    $self->{branch} = $params{branch};
    $self->{branch} = $self->_detect_branch unless defined $self->{branch};

    $self->{revision} = $params{revision};
    $self->{revision} = $self->_detect_revision
      unless defined $self->{revision};

    return $self;
}

sub validate {
    my $self = shift;
    my (@paths) = @_;

    my $files = [];

    foreach my $path (@paths) {
        $path = abs_path($path);

        my $content = do {
            local $/;
            open my $fh, '<', $path or die "Can't open file '$path': $!";
            <$fh>;
        };

        if ( my $root = $self->{root} ) {
            $root = abs_path($root);
            $path =~ s{^$root}{};
            $path =~ s{^/}{};
        }

        push @$files,
          {
            path    => $path,
            content => $content
          };
    }

    my $ua = $self->{ua};

    my $response = $ua->post(
        "$self->{base_url}/validate",
        {
            headers => {
                Authorization => 'Token ' . $self->{token},
                Accept        => 'application/json',
                'X-Version'   => $VERSION,
            },
            content => JSON->new->canonical(1)->encode(
                {
                    branch   => $self->{branch},
                    revision => $self->{revision},
                    files    => $files,
                    $self->{diff_ref}
                    ? ( diff_ref =>
                          $self->_detect_revision( $self->{diff_ref} ) )
                    : (),
                    $self->{diff_snapshot}
                    ? ( diff_snapshot => $self->{diff_snapshot} )
                    : (),
                    $self->{diff_branch}
                    ? ( diff_branch => $self->{diff_branch} )
                    : (),
                }
            )
        }
    );

    if ( $response->{status} eq '599' ) {
        my $content = $response->{content};
        $content = substr( $content, 0, 64 ) . '[...]' if length $content > 64;
        die "Internal error: $response->{status} $content";
    }

    unless ( $response->{success} ) {
        my $message =
          eval { JSON::decode_json( $response->{content} )->{message} }
          || 'Unknown Error';

        die "Remote error: $response->{status} $response->{reason}: $message\n";
    }

    return JSON::decode_json( $response->{content} );
}

sub _detect_branch {
    my $self = shift;

    die "Doesn't look like a git repository\n" unless -d "$self->{root}/.git";

    my ($branch) = `cd $self->{root}; git branch` =~ m/^\*\s+(.*)$/m;
    die "Can't detect current branch\n" unless $branch;

    return $branch;
}

sub _detect_revision {
    my $self = shift;
    my ($ref) = @_;

    $ref = 'HEAD' unless defined $ref;

    die "Doesn't look like a git repository\n" unless -d "$self->{root}/.git";

    my ($revision) =
      `cd $self->{root}; git rev-parse '$ref'` =~ m/([a-f0-9]+)/i;
    die "Can't detect current revision\n" unless $revision;

    return $revision;
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
