#!/usr/bin/env perl
use strict;
use warnings;

# ABSTRACT: Set up & manage a Blio instance
# PODNAME: blio_meta.pl

die "not implemented yet"

#Blio->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

blio_meta.pl - Set up & manage a Blio instance

=head1 VERSION

version 2.003

=head1 SYNOPSIS

  ~/your_blog$ blio_meta.pl init
  ~/your_blog$ blio_meta.pl copy_templates

=head1 DESCRIPTION

Helper script to set up / manage a <Blio> instance.

=head1 COMMANDS

=head2 init

Init a new B<Blio> instance.

Sets up the directory structure and some example files.

=head2 copy_templates

Copies the default templates shipped with C<Blio> into your instance.

=head1 SEE ALSO

L<blio.pl>, L<Blio>

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
