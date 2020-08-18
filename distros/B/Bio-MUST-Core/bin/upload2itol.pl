#!/usr/bin/env perl
# PODNAME: upload2itol.pl
# ABSTRACT: Upload trees and associate metadata files to iTOL

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments '###';

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Basename;
use File::Find::Rule;
use HTTP::Request::Common;
use LWP::UserAgent;


my $upload_url = "https://itol.embl.de/batch_uploader.cgi";

FILE:
for my $infile (@ARGV_infiles) {
    ### Processing: $infile

    # write ZIP archive file
    my $zip = Archive::Zip->new();
    my ($basename, $dir, $suffix) = fileparse($infile, qr{\.[^.]*}xms);
    my $zipfile = "$basename.zip";

    my $newname = "$basename.tree";     # iTOL wants a .tree suffix
    symlink($infile, $newname);         # TODO: improve this
    $zip->addFile($newname);

    $zip->addFile($_)
        for File::Find::Rule->file()->name("$basename\-*.txt")->in($dir);

    ### Storing ZIP file: $zipfile
    unless ( $zip->writeToFileNamed($zipfile) == AZ_OK ) {
        warn <<"EOT";
Warning: cannot ZIP archive file; skipping!
EOT
        next FILE;
    }

    # delete the symlink
    unlink($newname);                   # TODO: improve this

    # prepare the data
    my %data_for;
    $data_for{ 'zipFile'         } = [ $zipfile ];
    $data_for{ 'treeName'        } = $basename;
    $data_for{ 'APIkey'          } = $ARGV_api_key;
    $data_for{ 'projectName'     } = $ARGV_project;
    $data_for{ 'treeDescription' } = $ARGV_description if $ARGV_description;

    # submit the data
    my $ua = LWP::UserAgent->new();
    $ua->agent("iTOLbatchUploader4.0");
    my $request  = POST $upload_url,
        Content_Type => 'form-data', Content => [ %data_for ];
    my $response = $ua->request($request);

    message($response);
}


# TODO: use standard BMC error message scheme
sub message {
    my $response = shift;

    if ( $response->is_success() ) {
        my @res = split /\n/xms, $response->content;

        # check for an upload error
        if ($res[-1] =~ /^ERR/xms) {
            warn <<"EOT";
Warning: upload failed; iTOL returned the following error message:
$res[$#res]
EOT
        }

        # upload without warnings, ID on first line
        if ($res[0] =~ /^SUCCESS: \s (\S+)/xms) {
            print <<"EOT";
Upload successful; your tree is accessible using the following iTOL tree ID:
$1
EOT
        }
    }

    else {
        warn <<"EOT";
Warning: iTOL returned a web server error; full message follows:
EOT
        print $response->as_string;
    }

    return;
}

__END__

=pod

=head1 NAME

upload2itol.pl - Upload trees and associate metadata files to iTOL

=head1 VERSION

version 0.202310

=head1 USAGE

   upload2itol.pl <infiles> --api-key=<string> --project=<string> [options]

=head1 REQUIRED ARGUMENTS

This script is based on C<iTOL_uploader.pl>.

=over

=item <infiles>

Path to input TRE files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --api-key=<string>

Your API key, which can be generated through your user account options menu
(while logged in, click your name in the top right corner of any page to access
the option) [default: none].

=for Euclid: string.type: string

=item --project=<string>

Your project name from your user account [default: none].

=for Euclid: string.type: string

=back

=head1 OPTIONS

=over

=item --description=<string>

Any description for your tree [default: no].

=for Euclid: string.type: string

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
