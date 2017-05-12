package CGI::FileUpload::Manager;

use warnings;
use strict;

=head1 NAME

CGI::FileUpload::Manager - manipulating the list of CGI::FileUpload

=head1 DESCRIPTION

brwose the working directory and build a list of CGI:FileUpload

=head1 EXPORT


=head1 FUNCTIONS

=head3 lskey()

Return an array (sorted by date) of upload file keys

=head3 ls()

Return an array (sorted by date) of upload file CGI::FileUpload objects



=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot at genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-fileupload at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-FileUpload>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::FileUpload


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-FileUpload>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-FileUpload>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-FileUpload>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-FileUpload>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Alexandre Masselot, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


use CGI::FileUpload;
use File::Basename;
use File::Glob qw(:glob);


require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK);
@ISA=qw (Exporter);
@EXPORT=qw(&ls &lskey);
@EXPORT_OK=qw();

sub lskey{
  my %tmp;
  foreach(glob CGI::FileUpload::uploadDirectory()."/*.properties"){
    my $k=basename($_);
    $k=~s/\.properties$//;
    $tmp{$k}=(stat($_))[9];
  }
  return sort {$tmp{$b} <=> $tmp{$a}} keys %tmp;
}

sub ls{
  my @keys=lskey();
  my @ret;
  foreach(@keys){
    push @ret, CGI::FileUpload->new(key=>$_);
  }
  return @ret;
}

1;
