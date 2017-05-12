package CGI::Apache2::Wrapper::Upload;
use Apache2::Request;
push our @ISA, qw/APR::Request::Param/;
our $VERSION = '0.215';
{
  no strict 'refs';
  for (qw/type size tempname filename/) {
    *{$_} = *{"APR::Request::Param::upload_$_"}{CODE};
  }
}

sub Apache2::Request::upload {
  my $req = shift;
  return unless @_;
  my $body = $req->body or return;
  $body->param_class(__PACKAGE__);
  my @uploads = grep $_->upload, $body->get(@_);
  return wantarray ? @uploads : $uploads[0];
}

*bb = *APR::Request::Param::upload;

1;

__END__

=head1 NAME

CGI::Apache2::Wrapper::Upload - uploads via libapreq2

=head1 SYNOPSIS

  use CGI::Apache2::Wrapper::Upload;

  my $cgi = CGI::Apache2::Wrapper->new($r);
  my $upload = $cgi->req->upload("foo");

=head1 DESCRIPTION

This module is a mod_perl wrapper around the upload functionality
of L<libapreq2>, for use by L<CGI::Apache2::Wrapper>. It is
very similar to L<Apache2::Upload>, but only provides
the I<tempname> method for accessing the contents
of an uploaded file. It is not intended to be used directly;
rather, the I<upload> method of L<CGI::Apache2::Wrapper> should
be used.

=head1 SEE ALSO

L<CGI>, L<Apache2::Upload>, and L<CGI::Apache2::Wrapper>.

Development of this package takes place at
L<http://cpan-search.svn.sourceforge.net/viewvc/cpan-search/CGI-Apache2-Wrapper/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc CGI::Apache2::Wrapper::Upload

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Apache2-Wrapper>

=item * CPAN::Forum: Discussion forum

L<http:///www.cpanforum.com/dist/CGI-Apache2-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Apache2-Wrapper>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Apache2-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Apache2-Wrapper>

=item * UWinnipeg CPAN Search

L<http://cpan.uwinnipeg.ca/dist/CGI-Apache2-Wrapper>

=back

=head1 COPYRIGHT

This software is copyright 2007 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself;
see L<http://www.perl.com/pub/a/language/misc/Artistic.html>.

=cut

