=head1 NAME

App::BlurFill::CLI - The command line interface for App::BlurFill

=head1 SYNOPSIS

  use App::BlurFill::CLI;

  my $blur_fill = App::BlurFill::CLI->new;

  my $output = $blur_fill->process;
  print "Blurred image saved to: $output\n";

=head1 DESCRIPTION

App::BlurFill::CLI is a simple command line tool to create a blurred background image
from a given image. It scales the image to a specified width and height, applies
a Gaussian blur, and saves the result as a new image file.

=head1 METHODS

=head2 new

  my $blur_fill = App::BlurFill::CLI->new();

Creates a new App::BlurFill object. The no parameters are required.

=head2 run

  $blur_fill->run();

Runs the command line interface. It processes the command line arguments and
creates a new App::BlurFill object.

=cut

use v5.40;
use experimental 'class';

class App::BlurFill::CLI {
  our $VERSION = '0.0.4';

  use Getopt::Long;
  use File::Basename;
  use App::BlurFill;

  method run {
    my %opts;
    GetOptions(\%opts, 'width:i', 'height:i', 'output:s');

    my $in = shift @ARGV or die "Usage: blurfill [--width w] [--height h] [--output o] image_file\n";

    my $blur = App::BlurFill->new(
        file   => $in,
        %opts,
    );

    my $outfile = $blur->process;
    say "Wrote $outfile";
  }
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025, Magnum Solutions Ltd. All rights reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
