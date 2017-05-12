package App::pandoc::preprocess;
$App::pandoc::preprocess::VERSION = 'v0.9.10';
#  PODNAME: App::pandoc::preprocess
# ABSTRACT: Preprocess Pandoc before Processing Pandoc


'make CPAN happy -- we only have a main in bin/ppp'

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pandoc::preprocess - Preprocess Pandoc before Processing Pandoc

=head1 VERSION

version v0.9.10

=head1 ppp - pandoc pre-process

=head1 USAGE

     cat chapters/input-*.pandoc | ppp | pandoc -o output.pdf --smart [more pandoc options...]

Additionally see `etcE<sol>input.txt` for concrete examples.

=head1 PREREQUISITES

=over

=item *

dotE<sol>neato (neato is new!)

=item *

rdfdot

=item *

ditaa

=item *

Image::Magick (for downscaling of large images)

=back

=head1 BACKGROUND

=over

=item *

much simpler design than version 1: pipeable & chainable, reading line-by-line

=item *

parallelized work on image file creation

=back

=head2 How it works

1. while-loop will iterate line by line and is using the flip-flop-operator:

     * as soon, as a ditaa/rdfdot/dot-block starts,
       globals ($fileno, $outfile, etc) are set, so all other routines can see them
     * when actually *inside* the block, the block's contents are printed
       to the newly generated file (image-X.(ditaa/rdfdot/dot))

2. once the flip-flop-operator hits the end of the ditaaE<sol>rdfdotE<sol>dot-block,
a child will be spawned to take over the actual ditaaE<sol>rdfdotE<sol>dot-process
to create the png-file and the globals are reset

3. all other lines which are not part of a ditaaE<sol>rdfdotE<sol>dot-block will simply
be piped through to stdout

4. at the end of the program, all children are waited for

5. in the meantime, the new pandoc contents are printed to stdout

6. all child-processes will remain quiert as far as stdout is concerned and
write to their individual log-files

=head2 Todo

=over

=item *

Captions

=item *

Checks whether ditaa... are available

=item *

check whether ditaa has file.encoding set

=item *

bundle ditaa with this

=back

=head1 AUTHOR

DBR <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by DBR.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
