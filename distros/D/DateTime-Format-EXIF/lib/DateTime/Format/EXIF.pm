package DateTime::Format::EXIF;
$DateTime::Format::EXIF::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: DateTime parser for EXIF timestamps



sub _make_regex {
    my $date_re = '(\d{4}) : (\d{2}) : (\d{2})';
    my $time_re = '(\d{2}) : (\d{2}) : (\d{2} (?: \. \d{1,9})?)';
    my $tz_re = '(Z | [\+\-] \d{2} : \d{2})';
    return qr/^ $date_re \s $time_re $tz_re? $/xms;
}


use DateTime::Format::Builder (
    parsers => {
        parse_datetime => [
            {
                params => [ qw( year month day hour minute second time_zone ) ],
                regex  => _make_regex(),
                postprocess => \&_postprocess,
            },
        ],
    },
);


sub _postprocess {
    my %args = @_;
    my ($date, $p) = @args{qw( input parsed )};

    # timezone
    if (!$p->{time_zone}) {
        $p->{time_zone} = 'floating';
    }
    elsif ($p->{time_zone} eq 'Z') {
        $p->{time_zone} = 'UTC';
    }

    # nanoseconds
    my ($s, $fs) = split /(?=\.)/x => $p->{second};
    $p->{second} = $s;
    $p->{nanosecond} = int($fs * 1e9)  if $fs;

    return $date;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::EXIF - DateTime parser for EXIF timestamps

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Image::ExifTool;
    use DateTime::Format::EXIF;

    my $image_info = Image::ExifTool::ImageInfo("example.jpg");
    my $dt = DateTime::Format::EXIF->parse_datetime($image_info->{DateTimeOriginal});

=head1 DESCRIPTION

DateTime parser for EXIF timestamps

=head1 AUTHOR

liosha <liosha@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by liosha.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
