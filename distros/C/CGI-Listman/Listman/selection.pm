# selection.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman::selection;

use Carp;

=pod

=head1 NAME

CGI::Listman::selection - managing I<CGI::Listman::line>'s in batch

=head1 SYNOPSIS

    use CGI;
    use CGI::Listman;
    use CGI::Listman::selection;

    my $cgi = CGI->new ();
    my $list_manager = CGI::Listman->new ();

    [...]

    my $selection = CGI::Listman::selection->new ();
    foreach my $param ($cgi->param ()) {
      if ($param =~ m/^select_([0-9].*$)/) {
        $selection->add_line_by_number ($listman, $1);
      }
    }


=head1 DESCRIPTION

A I<CGI::Listman::selection> encapsulates an array of selected lines for
further batch processing. This is handy for example in an administration
interface when the developer wants to export or erase several lines at a
time from the database.

=head1 API

=head2 new

Creates, initializes and returns a new instance of
I<CGI::Listman::selection> for you to enjoy and work with.

=over

=item Parameters

This method takes no parameter.

=item Return values

A blessed instance of I<CGI::Listman::selection>.

=back

=cut

sub new {
  my $class = shift;

  my $self = {};
  my @selection_list;
  $self->{'list'} = \@selection_list;

  bless $self, $class;
}

=pod

=head2 add_line

Use this method to add a I<CGI::Listman::line> to your selection.

=over

=item Parameters

=over

=item line

A single instance of I<CGI::Listman::line> to be exported.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_line {
  my ($self, $line) = @_;

  my $list_ref = $self->{'list'};
  push @$list_ref, $line;
}

=pod

=head2 add_line_by_number

This method helps you adding a line by number. The first parameter has to
be its contextual instance of I<CGI::Listman>. Without it, a line cannot
be guaranteed to be numbered since line numbers make no sense when they
are not part of a I<CGI::Listman>.

=over

=item Parameters

=over

=item list_manager

An instance of I<CGI::Listman>.

=item number

An integer representing the I<CGI::Listman::line> you want to add to your
selection.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_line_by_number {
  my ($self, $listman, $number) = @_;

  my $line = $listman->seek_line_by_num ($number);
  croak "Line number ".$number." not found.\n"
    unless (defined $line);
  $self->add_line ($line);
}

=pod

=head2 add_lines_by_number

Same as above, except that it takes a reference to an ARRAY of numbers.

=over

=item Parameters

=over

=item list_manager

An instance of I<CGI::Listman>.

=item numbers

A reference to an ARRAY of integers representing the
I<CGI::Listman::line>'s you want to add to your selection.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_lines_by_number {
  my ($self, $listman, $numbers) = @_;

  foreach my $number (@$numbers) {
    $self->add_line_by_number ($listman, $number);
  }
}

1;
__END__

=pod

=head1 AUTHOR

Wolfgang Sourdeau, E<lt>Wolfgang@Contre.COME<gt>

=head1 COPYRIGHT

Copyright (C) 2002 iScream multimédia <info@iScream.ca>

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Listman::line(3)>  L<CGI::Listman::exporter(3)>

=cut
