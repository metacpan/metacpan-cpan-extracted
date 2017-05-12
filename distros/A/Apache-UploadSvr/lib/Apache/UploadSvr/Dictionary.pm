package Apache::UploadSvr::Dictionary;

use strict;
use IO::File;
use vars qw( $VERSION $D );

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

sub init {
  $D = {};
  local($/) = "";
  my $file = __FILE__;
  $file =~ s/\.pm$/.data/;
  my $fh = IO::File->new;
  $fh->open($file) or die "Could not open file[$file]: $!";
  while (<$fh>) {
    my($lang,$code) = /(..):(\w+)/ or last;
    die "strange string $_" unless $code;
    my $string = <$fh> or "No string for lang[$lang]code[$code]";
    $D->{$lang}{$code} = $string;
  }
  $fh->close;
}

&init;

sub fetch {
  my($class,$lang,$code,@arg) = @_;
  # May be inefficient if they do not use arguments, but conveniently to use
  # if they do
  unless (exists $D->{$lang} && exists $D->{$lang}{$code}){
    warn "Not in dictionary: lang[$lang]code[$code]";
    return "<B>INCOMPLETE DICTIONARY</B>";
  }
  sprintf $D->{$lang}{$code}, @arg;
}

sub exists {
  my($class,$lang) = @_;
  exists $D->{$lang};
}

1;

