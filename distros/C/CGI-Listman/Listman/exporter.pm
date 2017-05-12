# exporter.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman::exporter;

use Carp;
use Text::CSV_XS;

=pod

=head1 NAME

CGI::Listman::exporter - exporting database records with bookkeeping

=head1 SYNOPSIS

    use CGI::Listman::exporter;

=head1 DESCRIPTION

CGI::Listman::exporter provides some simple API to export instances of
I<CGI::Listman::line> to "Comma-Separated Values"-formatted files. Such
files will generally be transmitted through a CGI (see the
I<file_contents> method below). Between instances of this CGI, you want
to use the I<save_file> method since there is no way for I<CGI::Listman>
to know when a CGI session get closed.

=head1 API

=head2 new

Creates an initialized instance of I<CGI::Listman::exporter>.

=over

=item Parameters

All the parameters are optional with this method.

=over

=item filename

An optional string representing the filename of the export file.

=item separator

An optional single-character string representing the CSV separator to be
used. If not specified, the default will of course be a comma.

=back

=item Return values

An instance of I<CGI::Listman::exporter>

=back

=cut

sub new {
  my $class = shift;

  my $self = {};

  my @lines;
  $self->{'file_name'} = shift;
  $self->{'separator'} = shift || ',';
  $self->{'lines'} = \@lines;
  $self->{'_csv'} = Text::CSV_XS->new ({sep_char => $self->{'separator'},
					binary => 1});
  $self->{'_file_read'} = 0;

  bless $self, $class;
  $self->_read_file () if (defined $self->{'file_name'});

  return $self;
}

=pod

=head2 set_file_name

This method is of mandatory use if the filename is not specified when
calling the I<new> method. It cannot however be called twice.

=over

=item Parameters

=over

=item filename

A string representing the filename of the export file.

=back

=item Return values

This methods returns nothing.

=back

=cut

sub set_file_name {
  my ($self, $file_name) = @_;

  croak "A file name is already defined for this instance"
    ." of CGI::Listman::exporter.\n"
      if (defined $self->{'file_name'});
  $self->{'file_name'} = $file_name;
  $self->_read_file ();
}

=pod

=head2 set_separator

This method's name is quite explicit. It is useful when people want to
use any other separator than the comma. People should however not be
afraid of using the latter since even textual data containing such a
character will be encapsulated in a way that prevent formatting
conflicts.

=over

=item Parameters

=over

=item separator

A single-character string representing the separator in the CSV file.

=back

=item Return values

This methods returns nothing.

=back

=cut

sub set_separator {
  my ($self, $sep) = @_;

  $self->{'separator'} = $sep;
}

=pod

=head2 add_line

Add an instance of I<CGI::Listman::line> to your instance of
I<CGI::Listman::exporter>.

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

  my $csv = $self->{'_csv'};

  my $data_ref = $line->{'data'};
  my @columns = @$data_ref;
  $csv->combine (@columns);
  my $csv_line = $csv->string ();
  my $lines_ref = $self->{'lines'};
  push @$lines_ref, $csv_line;
  $line->mark_exported ();
}

=pod

=head2 add_selection

Add instances of I<CGI::Listman::line> in batch to your instance of
I<CGI::Listman::exporter>.

=over

=item Parameters

=over

=item selection

An instance of I<CGI::Listman::selection>.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_selection {
  my ($self, $selection) = @_;

  my $sel_list_ref = $selection->{'list'};
  foreach my $line (@$sel_list_ref) {
    $self->add_line ($line);
  }
}

=pod

=head2 file_contents

=over

=item Parameters

This method takes no parameter.

=item Return values

A perl string containing the contents of the export file in a
DOS-formatted fashion (with both a "linefeed" and a "carriage return" at
the end of each line). This is to ensure compatibility with the
world-dominating operating systems.

=back

=cut

sub file_contents {
  my $self = shift;

  my $contents = undef;
  my $lines_ref = $self->{'lines'};
  foreach my $line (@$lines_ref) {
    $contents .= $line."\r\n";
  }

  return $contents;
}

=pod

=head2 save_file

Except when defining and exporting the data put in a
I<CGI::Listman::exporter> during the same CGI session, it is wise to save
its contents in-between.

=over

=item Parameters

This method takes no parameter.

=item Return values

This method returns nothing.

=back

=cut

sub save_file {
  my $self = shift;

  croak "No file to export to.\n"
    unless (defined $self->{'file_name'});
  my $contents = $self->file_contents ();

  open EFOUT, '>'.$self->{'file_name'}
    or croak "Could not open export file (\""
      .$self->{'file_name'}."\") for writing.\n";
  print EFOUT $contents;
  close EFOUT;
}

### private methods

sub _read_file {
  my $self = shift;

  if (-f $self->{'file_name'}) {
    open EFIN, $self->{'file_name'}
      or croak "Could not open export file ('".$self->{'file_name'}."').\n";

    my $lines_ref = $self->{'lines'};
    while (<EFIN>) {
      my $line = $_;
      chomp $line;
      push @$lines_ref, $line;
    }
    close EFIN;

    $self->{'_file_read'} = 1;
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

L<CGI::Listman::line(3)> L<CGI::Listman::selection(3)>

=cut
