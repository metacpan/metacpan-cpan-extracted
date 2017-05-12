use 5.010;
use strict;
use warnings;

package App::MP4Meta::Command::film;
{
  $App::MP4Meta::Command::film::VERSION = '1.153340';
}

# ABSTRACT: Apply metadata to a film. Parses the filename in order to get the films title and (optionally) year.

use App::MP4Meta -command;

use Try::Tiny;


sub usage_desc { "film %o [file ...]" }

sub abstract {
'Apply metadata to a film. Parses the filename in order to get the films title and (optionally) year.';
}

sub opt_spec {
    return (
        [ "genre=s",     "The genre of the Film" ],
        [ "coverfile=s", "The location of the cover image" ],
        [ "sources=s@", "The sources to search", { default => [qw/OMDB/] } ],
        [ "title=s",    "The title of the Film" ],
        [ "noreplace", "Don't replace the file - creates a temp file instead" ],
        [ "itunes",  "adds to iTunes after applying meta data. Mac OSX only." ],
        [ "verbose", "Print verbosely" ],
        [
            "withoutany",
"Continue to process even if we can not find any information on the internet"
        ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    # we need at least one file to work with
    $self->usage_error("too few arguments") unless @$args;

    # check each file
    for my $f (@$args) {
        unless ( -e $f ) {
            $self->usage_error("$f does not exist");
        }
        unless ( -r $f ) {
            $self->usage_error("can not read $f");
        }

        # TODO: is $f an mp4?
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    require App::MP4Meta::Film;
    my $film = App::MP4Meta::Film->new(
        {
            noreplace            => $opt->{noreplace},
            genre                => $opt->{genre},
            sources              => $opt->{sources},
            title                => $opt->{title},
            coverfile            => $opt->{coverfile},
            itunes               => $opt->{itunes},
            verbose              => $opt->{verbose},
            continue_without_any => $opt->{withoutany},
        }
    );

    for my $file (@$args) {
        say "processing $file" if $opt->{verbose};
        my $error;
        try {
            $error = $film->apply_meta($file);
        }
        catch {
            $error = "Error applying meta to $file: $_";
        }
        finally {
            say $error if $error;
        };
    }

    say 'done' if $opt->{verbose};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MP4Meta::Command::film - Apply metadata to a film. Parses the filename in order to get the films title and (optionally) year.

=head1 VERSION

version 1.153340

=head1 SYNOPSIS

  mp4meta film PULP_FICTION.mp4 "The Truman Show.m4v"

  mp4meta film --noreplace THE-ITALIAN-JOB-2003.m4v

This command applies metadata to one or more films. It parses the filename in order to get the films title and (optionally) year.

It gets the films metadata by querying the OMDB. It then uses AtomicParsley to apply the metadata to the file.

By default, it will apply the metadata to the existing file. If you want it to write to a temporary file and leave the existing file untouched, provide the C<--noreplace> option.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
