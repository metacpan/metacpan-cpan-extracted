package Apache::Compress;

use strict;
use Compress::Zlib 1.0;
use Apache::File;
use Apache::Constants qw(:common);
use vars qw($VERSION);

$VERSION = '1.005';

sub handler {
  my $r = shift;
  
  my $can_gzip = can_gzip($r);

  my $filter   = lc $r->dir_config('Filter') eq 'on';
  #warn "can_gzip=$can_gzip, filter=$filter";
  return DECLINED unless $can_gzip or $filter;
  
  # Other people's eyes need to check this 1.1 stuff.
  if ($r->protocol =~ /1\.1/) {
    my %vary = map {$_,1} qw(Accept-Encoding User-Agent);
    if (my $vary = $r->header_out('Vary')||0) {
      $vary{$vary} = 1;
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
    $r->print( Compress::Zlib::memGzip(do {local $/; <$fh>}) );
  } else {
    $r->send_http_header;
    $r->send_fd($fh);
  }
  
  return OK;
}

sub can_gzip {
  my $r = shift;

  my $how_decide = $r->dir_config('CompressDecision');
  if (!defined($how_decide) || lc($how_decide) eq 'header') {
    return +($r->header_in('Accept-Encoding')||'') =~ /gzip/;
  } elsif (lc($how_decide) eq 'user-agent') {
    return guess_by_user_agent($r->header_in('User-Agent'));
  }
  
  die "Unrecognized value '$how_decide' specified for CompressDecision";
}
  
sub guess_by_user_agent {
  # This comes from Andreas' Apache::GzipChain.  It's very out of
  # date, though, I'd like it if someone sent me a better regex.

  my $ua = shift;
  return $ua =~  m{
		   ^Mozilla/            # They all start with Mozilla...
		   \d+\.\d+             # Version string
		   [\s\[\]\w\-]+        # Language
		   (?:
		    \(X11               # Any unix browser should work
		    |             
		    Macint.+PPC,\sNav   # Does this match anything??
		   )
		  }x;
}


1;


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
  
  # Compress regular files - decides whether to compress by
  # examining the Accept-Encoding header
  <FilesMatch "\.blah$">
   SetHandler perl-script
   PerlHandler Apache::Compress
  </FilesMatch>
  
  # Compress output of Perl scripts
  PerlModule Apache::Filter
  <FilesMatch "\.pl$">
   SetHandler perl-script
   PerlSetVar Filter on
   PerlHandler Apache::RegistryFilter Apache::Compress
  </FilesMatch>
  
  # Guess based on user-agent
  <FilesMatch "\.blah$">
   SetHandler perl-script
   PerlSetVar CompressDecision User-Agent
   PerlHandler Apache::Compress
  </FilesMatch>

=head1 DESCRIPTION

This module lets you send the content of an HTTP response as
gzip-compressed data.  Certain browsers (Netscape, IE) can request
content compression via the C<Accept-Encoding> header.  This can
speed things up if you're sending large files to your users through
slow connections.

Browsers that don't request gzipped data will receive regular
noncompressed data.

Apparently some older browsers (and maybe even some newer ones)
actually support gzip encoding, but don't send the C<Accept-Encoding>
header.  If you want to try to guess which browsers these are and
encode the content anyway, you can set the C<CompressDecision>
variable to C<User-Agent>.  The default C<CompressDecision> value is
C<Header>, which means it will only look at the incoming
C<Accept-Encoding> header.

Note that the browser-guessing is currently using a regular expression
that I don't think is very good, but I don't know what user agents to
support and which not to.  Please send me information if you have any,
especially in the form of a patch. =)

This module is compatibile with Apache::Filter, so you can compress
the output of other content-generators.

=head1 TO DO

Compress::Zlib provides a facility for buffering output until there's
enough data for efficient compression.  Currently we don't take
advantage of this facility, we simply compress the whole content body
at once.  We could achieve better memory usage if we changed this (at
a small cost to the compression ratio).  See Eagle book, p.185.

=head1 AUTHOR

Ken Williams, KWILLIAMS@cpan.org

Partially based on the work of several modules, like Doug MacEachern's
Apache::Gzip (in the Eagle book but not on CPAN), Andreas Koenig's
Apache::GzipChain, and an unreleased module by Geoffrey Young and
Philippe Chiasson.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache::Filter(3)

=cut
