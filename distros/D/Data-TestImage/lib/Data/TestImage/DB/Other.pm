package Data::TestImage::DB::Other;
# ABSTRACT: other test images
$Data::TestImage::DB::Other::VERSION = '0.007';
use Data::TestImage;
use parent qw(Data::TestImage::DB);

use strict;
use warnings;

sub get_db_dir {
	Data::TestImage->get_dist_dir()->subdir(qw{ other });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TestImage::DB::Other - other test images

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Data::TestImage::DB::Other;

    my $camera_file = Data::TestImage::DB::Other->get_image('cameraman');
    say $camera_file->basename;
    # cameraman.tiff

Produces the L<cameraman.tiff|http://EntropyOrg.github.io/p5-Data-TestImage/Other/cameraman.png> image.

=for html <div><img width="200" alt="Cameraman image" src="http://EntropyOrg.github.io/p5-Data-TestImage/Other/cameraman.png"/></div>

=head1 INHERITANCE

=over 4

=item L<Data::TestImage::DB>

=back

=head1 DESCRIPTION

This image database currently contains just cameraman.tiff.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
