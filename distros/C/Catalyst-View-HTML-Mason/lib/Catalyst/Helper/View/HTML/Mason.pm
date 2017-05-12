package Catalyst::Helper::View::HTML::Mason;
our $AUTHORITY = 'cpan:FLORA';
# ABSTRACT: Helper for L<Catalyst::View::HTML::Mason> views
$Catalyst::Helper::View::HTML::Mason::VERSION = '0.19';
use strict;
use warnings;


sub mk_compclass {
    my ($self, $helper) = @_;
    my $file = $helper->{file};
    (my $template = do { local $/; <DATA> }) =~ s/^\s\s//g;
    $helper->render_file_contents($template, $file);
}


1;

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::View::HTML::Mason - Helper for L<Catalyst::View::HTML::Mason> views

=head1 SYNOPSIS

    script/create.pl view Mason HTML::Mason

=head1 METHODS

=head2 mk_compclass

=head1 SEE ALSO

L<Catalyst::View::HTML::Mason>, L<Catalyst::Helper>

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Sebastian Willert <willert@cpan.org>

=item *

Robert Buels <rbuels@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
  package [% class %];
  use Moose;
  extends 'Catalyst::View::HTML::Mason';

  ## uncomment below to pass default configuration options to this view
  # __PACKAGE__->config( );

  =head1 NAME

  [% class %] - Mason View Component for [% app %]

  =head1 DESCRIPTION

  Mason View Component for [% app %]

  =head1 SEE ALSO

  L<[% app %]>, L<Catalyst::View::HTML::Mason>, L<HTML::Mason>

  =head1 AUTHOR

  [% author %]

  =head1 LICENSE

  This library is free software . You can redistribute it and/or modify
  it under the same terms as perl itself.

  =cut

  1;
