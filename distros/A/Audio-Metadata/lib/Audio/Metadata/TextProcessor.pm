package Audio::Metadata::TextProcessor;
{
  $Audio::Metadata::TextProcessor::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::TextProcessor::VERSION = '0.15';
}

use strict;
use warnings;

use Audio::Metadata;
use Any::Moose;


has input_fh  => ( is => 'ro', isa => 'FileHandle', );
has output_fh => ( is => 'ro', isa => 'FileHandle', );
has debug     => ( is => 'rw', isa => 'Bool', default => 0, );


sub BUILDARGS {
    ## Overriden.
    my $self = shift;
    my ($init_params) = @_;

    my %new_args = %$init_params;
    foreach my $mode (qw/input output/) {

        next if !defined $init_params->{$mode};
        delete $new_args{$mode};

        open my $fh, $mode eq 'input' ? '<' : '>', $init_params->{$mode}
            or die "Couldn't open $mode stream \"$init_params->{$mode}\": $!";
        $new_args{"${mode}_fh"} = $fh;
    }

    return \%new_args;
}


sub update_from_cue {
    ## Reads track info from a cue file and saves to tracks, based on track numbers.
    my $self = shift;

    my @metadatas = $self->_input_cue;
    my @file_names = grep /^\d+[_ ]?-[_ ]?.+\.(flac|ogg|mp3)$/i, glob('*.*');

    die @metadatas . ' tracks parsed, but ' . @file_names . ' files found'
        unless @metadatas == @file_names;

    for (my $i = 0; $i < @file_names; $i++) {
        my $file_name = $file_names[$i];
        my $metadata = $metadatas[$i];

        my $metadata_writer = Audio::Metadata->new_from_path($file_name);
        $self->_log($file_name);

        foreach my $var (keys %$metadata) {
            $self->_log(" $var => $metadata->{$var}");
            $metadata_writer->set_var($var => $metadata->{$var});
        }
        $metadata_writer->save;
    }
}


sub update {
    ## Reads metadata from specified file handle and saves to media files.
    my $self = shift;

    my $fh = $self->input_fh;
    my %curr_item;
    while (my $line = <$fh>) {
        chomp $line;

        my ($var, $value) = $line =~ /^(\S+) *(.*)$/;
        if ($var) {
            $curr_item{$var} = $value;
        }
        else {
            $self->_apply_item(\%curr_item);
            %curr_item = ();
            next;
        }
    }
    $self->_apply_item(\%curr_item) if %curr_item;
}


sub _apply_item {
    ## Saves metadata to file in the given hash.
    my $self = shift;
    my ($item) = @_;

    my $metadata = Audio::Metadata->new_from_path($item->{_FILE_NAME});
    my $is_changed;

    foreach my $var (grep /^[^_]/, keys %$item) {
        no warnings 'uninitialized';
        next if $item->{$var} eq $metadata->get_var($var);

        $metadata->set_var($var => $item->{$var});
        $is_changed++;
    }

    $metadata->save if $is_changed;
}


sub _input_cue {
    ## Reads cue file from input file handle and returns track list as array of hashes.
    my $class = shift;

    # Define names of properties common to the whole album, and how to map
    # them to tags.
    my %common_props;
    my %common_props_map = (
        TITLE       => 'ALBUM',
        PERFORMER   => 'ARTIST',
    );

    # Go through .CUE file, parsing common properties as well as individual ones.
    my @tracks;
    my $curr_track_no;

    my $fh = $class->input_fh;
    while (<$fh>) {

        s/^\s+|\s+$//g;
        my ($key, $value) = /^([A-Z]+)\s+"?([^"]+)"?$/s;
        next if !$key || $key eq 'REM';

        if (!defined $curr_track_no && (my $translated_key = $common_props_map{$key})) {
            $common_props{$translated_key} = $value;
        }
        elsif ($key eq 'TRACK') {
            ($curr_track_no) = $value =~ /^(\d+)/;
        }
        elsif (defined $curr_track_no && $key ne 'INDEX') {
            $tracks[$curr_track_no]{$key} = $value;
        }
    }

    return
        map { { %common_props, %$_ } }
            grep defined $_ && $_->{TITLE} ne 'DATA', @tracks;
}


sub _log {
    ## Logs a specified message.
    my $self = shift;

    print STDERR @_, "\n" if $self->debug;
}


1;


__END__

=head1 NAME

Audio::Metadata::TextProcessor - Manipulate audio file metadata sets as plain text files

=cut

=head1 DESCRIPTION

This module is meant to be used from its command-line front-end, L<ametadata> utility.

It provides means to edit audio file metadata (often called tags) using plain text
files. Its main goal is to leverage the power of Unix tools and the piping concept for
managing collections of audio files.

It can produce text metadata representations from audio files, or conversely, update
metadata in audio files from plain text.

=head1 SYNOPSIS

=head1 METHODS

=head3 new($init_params)

=over

The constructor. Can take the following named parameters, provided in a hash reference:
"inpit" - input file name, "input_fh" - input file handle, "output" - output file name,
"output_fh" - output file handle, "debug" - enable debug messages.

All parameters are optional. Input and output default to STDIN and STDOUT.

=back

=head3 C<update_from_cue()>

=over

Reads track info from a cue file and saves to tracks, based on track numbers.

=back

=head3 C<update()>

=over

Reads metadata from specified file handle and saves to media files.

=back

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-blogger at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-Metadata>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audio::Metadata

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-Metadata>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-Metadata>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-Metadata>

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-Metadata/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
