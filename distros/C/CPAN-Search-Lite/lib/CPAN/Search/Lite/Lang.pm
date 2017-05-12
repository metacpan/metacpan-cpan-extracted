package CPAN::Search::Lite::Lang;
use strict;
use warnings;
our $VERSION = 0.77;

use utf8;
use base qw(Exporter);
our (@EXPORT_OK, %langs, $chaps_desc, $pages, $dslip, $months);
@EXPORT_OK = qw(%langs load);

%langs = map {$_ => 1} qw(de en es fr it pt);

sub load {
  my %args = @_;
  my $lang = delete $args{lang};
  unless ($lang) {
    return "Please specify a language";
  }
  unless ($langs{$lang}) {
    return "Language '$lang' not available";
  }
  my $pkg = __PACKAGE__ . '::' . $lang;
  eval "require $pkg";
  if ($@) {
    return "Error from requiring $pkg: $@";
  }
  eval "import $pkg qw(\$chaps_desc \$pages \$dslip \$months)";
  if ($@) {
    return "Error importing from $pkg: $@";
  }
  my %wanted = (chaps_desc => $chaps_desc,
                pages => $pages,
                dslip => $dslip,
                months => $months);
  foreach my $request (keys %args) {
    next unless (defined $request and defined $wanted{$request});
    $args{$request}->{$lang} = $wanted{$request};
  }
  return 1;
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang - export some common data structures used by CPAN::Search::Lite::*

=head1 DESCRIPTION

This module can be used to populate some common data structures 
used by other I<CPAN::Search::Lite::*> modules based on
a requested language. The translated form of these structures
are contained in I<CPAN::Search::Lite::Lang::*.pm> (for example,
I<en.pm> or I<fr.pm>). A hash I<%langs> is exported, supplying
a list of languages available, as well as a function I<load>,
used as

   load(lang => $lang, pages => $pages, chaps_desc => $chaps_desc);

which will, for example, take the data structure C<$pages> and
populate C<< $pages->{$lang} >> with the appropriate C<$page> from
the requested C<$pages> from C<CPAN::Search::Lite::Lang::$lang.pm>.
At present the available data structures are:

=over 3

=item * C<$chaps_desc>

This is a hash reference giving a description, in different
languages, of the various CPAN chapter ids.

  foreach my $lang(sort keys %$chaps_desc) {
   print "For language $lang\n";
     foreach my $id(sort {$a <=> $b} keys %{$chaps_desc->{$lang}}) {
       print "   $id => $chaps_desc->{$lang}->{$id}\n";
     }
  }

Special characters used are HTML-encoded.

=item * C<$dslip>

This is a hash reference describing the I<dslip> (development,
support, language, interface, and public license) information,
available in different languages:

  for my $lang (sort keys %$dslip) {
    print "For language $lang:\n";
      for my $key (qw/d s l i p/) {
        print "  For key $key: $dslip->{$lang}->{$key}->{desc}\n";
          for my $entry (sort keys %{$dslip->{$lang}->{$key}}) {
            next if $entry eq 'desc';
            print "    Entry $entry: $dslip->{$lang}->{$key}->{$entry}\n"; 
        }
    }
  }

Special characters used are HTML-encoded.

=item * C<$pages>

This hash, with keys being various languages, provides some
translations of terms used in the tt2 pages.

=item * C<$months>

This hash, with keys being various languages, provides
translations of the abbreviations of names of the months.

=back

=cut
