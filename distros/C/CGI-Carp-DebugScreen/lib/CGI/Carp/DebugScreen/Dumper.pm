package CGI::Carp::DebugScreen::Dumper;

use strict;
use warnings;

our $VERSION = '0.15';

my $IgnoreOverload;

sub ignore_overload { shift; $IgnoreOverload = shift; }

sub dump {
  my ($pkg, $thingy) = @_;

  return _dump($thingy);
}

sub _dump {
  my $thingy = shift;

  my $res = '';

  require overload if $IgnoreOverload;

  if (!defined $thingy) {
    $res .= 'undef';
  }
  elsif (ref $thingy eq 'HASH') {
    if (%{ $thingy }) {
      $res = qq{<table class="watch" border="1">\n};
      foreach my $key (sort {$a cmp $b} keys %{ $thingy }) {
        $res .= q{<tr><th>}._escape($key).q{</th><td>}._dump($thingy->{$key}).qq{</td></tr>\n};
      }
      $res .= qq{</table>\n};
    }
    else {
      $res .= '*EMPTY_HASH*';
    }
  }
  elsif (ref $thingy eq 'ARRAY') {
    if (@{ $thingy }) {
      $res .= join ', ', map { _dump($_) } @{ $thingy };
    }
    else {
      $res .= '*EMPTY_ARRAY*';
    }
  }
  elsif (ref $thingy eq 'SCALAR') {
    $res .= _escape(${ $thingy });
  }
  elsif (ref $thingy eq 'CODE') {
    $res .= '*CODE*';
  }
  elsif (ref $thingy eq 'GLOB') {
    $res .= '*GLOB*';
  }
  elsif (my $name = ref $thingy) {
    my $blessed;
    my $strval = $IgnoreOverload ? overload::StrVal($thingy) : '';
    if ($thingy =~ /=HASH/ or $strval =~ /=HASH/) {
      my %hash = %{ $thingy };
      $blessed = \%hash;
    }
    elsif ($thingy =~ /=ARRAY/ or $strval =~ /=ARRAY/) {
      my @array = @{ $thingy };
      $blessed = \@array;
    }
    elsif ($thingy =~ /=SCALAR/ or $strval =~ /=SCALAR/) {
      $blessed = $$thingy;
    }
    elsif ($name eq 'REF') {
      $blessed = $$thingy;
    }

    $res .= qq{<table class="watch" border="1">\n};
    $res .= q{<tr><th>}._escape($name).q{ (blessed)</th><td>}.($blessed ? _dump($blessed) : _escape($thingy)).qq{</td></tr>\n};
    $res .= qq{</table>\n};
  }
  else {
    $res .= _escape($thingy);
  }
  return $res;
}

sub _escape {
  my $str = shift;

  return 'undef' unless defined $str;
  return '*BINARY*' if $str =~ /[\x00-\x08\x0b\x0c\x0e-\x1f]/;

  $str =~ s/&/&amp;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/</&lt;/g;

  $str eq '' ? '*BLANK*' : $str;
}

1;

__END__

=head1 NAME

CGI::Carp::DebugScreen::Dumper - Dump a variable as an HTML table

=head1 SYNOPSIS

  use CGI::Carp::DebugScreen::Dumper;

  # if you want to poke into further
  CGI::Carp::DebugScreen::Dumper->ignore_overload(1);

  my $table = CGI::Carp::DebugScreen::Dumper->dump($thingy);

  print "Content-type:text/html\n\n", $table;

=head1 DESCRIPTION

This module dumps the contents of a variable (supposedly, a reference) as an HTML table. If the variable has something unfit for an HTML output, it dumps alternative texts such as '*BINARY*', '*CODE*', or '*GLOB*'. It also escapes every key and value, so all you have to do is print some headers (likely to have been printed) and the dumped table. Dead easy.

=head1 METHOD

Currently this module has only two package methods.

=head2 dump()

takes a variable (supposedly, a reference) and returns an HTML table.

=head2 ignore_overload()

If set to true, dump() will ignore overloading (to stringify, maybe) and poke into the object further.

=head1 TODO

I'm afraid that this module should have another (and shorter) name and stand alone. The dumps() method should take array, hash, or multiple variables. 

=head1 SEE ALSO

L<CGI::Carp::DebugScreen>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
