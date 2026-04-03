package App::Test::Generator::LCSAJ::Coverage;

use strict;
use warnings;
use JSON::MaybeXS;

sub merge {
	my ($lcsaj_file,$hits_file,$out_file) = @_;

    my $paths = decode_json(do { local(@ARGV,$/)=$lcsaj_file;<> });
    my $hits  = decode_json(do { local(@ARGV,$/)=$hits_file;<> });

    for my $path (@$paths) {

        my $covered = 0;

        for my $line ($path->{start} .. $path->{end}) {

            if ($hits->{$line}) {
                $covered = 1;
                last;
            }
        }

        $path->{covered} = $covered;
    }

    open my $fh,'>',$out_file;

    print $fh encode_json($paths);

    close $fh;
}

1;
