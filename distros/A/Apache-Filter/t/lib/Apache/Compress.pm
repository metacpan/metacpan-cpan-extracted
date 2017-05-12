package Apache::Compress;

use strict;
use Compress::Zlib 1.0;
use Apache::File;
use Apache::Constants qw(:common);
use vars qw($VERSION);

$VERSION = sprintf '%d.%03d', q$Revision: 1.1 $ =~ /: (\d+).(\d+)/;

sub handler {
  my $r = shift;

  my $can_gzip = $r->header_in('Accept-Encoding') =~ /gzip/;
  my $filter   = lc $r->dir_config('Filter') eq 'on';
  #warn "can_gzip=$can_gzip, filter=$filter";
  return DECLINED unless $can_gzip or $filter;
  
  # Other people's eyes need to check this 1.1 stuff.
  if ($r->protocol =~ /1\.1/) {
    my %vary = map {$_,1} qw(Accept-Encoding User-Agent);
    if (my @vary = $r->header_out('Vary')) {
      @vary{@vary} = ();
    }
    $r->header_out('Vary' => join ',', keys %vary);
  }
  
  my $fh;
  if ($filter) {
    $r = $r->filter_register;
    $fh = $r->filter_input();
  } else {
    $fh = Apache::File->new($r->filename);
  }
  return SERVER_ERROR unless $fh;
  
  if ($can_gzip) {
    $r->content_encoding('gzip');
    $r->send_http_header;
    local $/;
    print Compress::Zlib::memGzip(<$fh>);
  } else {
    $r->send_http_header;
    $r->send_fd($fh);
  }
  
  return OK;
}

1;


#  my $user_agent = $r->header_in('User-Agent');
#  
#  unless ($can_gzip) {
#    $can_gzip = 1 if $user_agent =~ 
#      m{
#        ^Mozilla/
#        \d+\.\d+
#        [\s\[\]\w\-]+
#        (?:
#         \(X11 |
#         Macint.+PPC,\sNav
#        )
#       }x;
#  }

# Verbose version:
#    my $content = do {local $/; <$fh>};
#    my $content_size = length($content);
#    $content = Compress::Zlib::memGzip(\$content);
#    my $compressed_size = length($content);
#    my $ratio = int(100*$compressed_size/$content_size) if $content_size;
#    print STDERR "GzipCompression $content_size/$compressed_size ($ratio%)\n";
#    print $content;

__END__

=head1 NAME

Apache::Compress - Auto-compress web files with Gzip

=head1 SYNOPSIS

  PerlModule Apache::Compress
  
  # Compress regular files
  <FilesMatch "\.blah$">
   PerlHandler Apache::Compress
  </FilesMatch>
  
  # Compress output of Perl scripts
  PerlModule Apache::Filter
  <FilesMatch "\.pl$">
   PerlSetVar Filter on
   PerlHandler Apache::RegistryFilter Apache::Compress
  </FilesMatch>

=head1 DESCRIPTION

This module lets you send the content of an HTTP response as
gzip-compressed data.  Certain browsers (Netscape, IE) can request
content compression via the C<Content-Encoding> header.  This can
speed things up if you're sending large files to your users through
slow connections.

Browsers that don't request gzipped data will receive regular
noncompressed data.

This module is compatibile with Apache::Filter, so you can compress
the output of other content-generators.

=head1 TO DO

Compress::Zlib provides a facility for buffering output until there's
enough data for efficient compression.  Currently we don't take
advantage of this facility, we simply compress the whole content body
at once.  We could achieve better memory usage if we changed this (at
a small cost to the compression ratio).  See Eagle book, p.185.

=head1 AUTHOR

Ken Williams, ken@forum.swarthmore.edu

Partially based on the work of several modules, like Doug MacEachern's
Apache::Gzip (in the Eagle book but not on CPAN), Andreas Koenig's
Apache::GzipChain, and an unreleased module by Geoffrey Young and
Philippe Chiasson.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache::Filter(3)

=cut
