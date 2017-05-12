package CGI::Ex::Dump;

=head1 NAME

CGI::Ex::Dump - A debug utility

=cut

###----------------------------------------------------------------###
#  Copyright 2004-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION
            $CALL_LEVEL
            $ON $SUB $QR1 $QR2 $full_filename $DEPARSE);
use strict;
use Exporter;

$VERSION   = '2.44';
@ISA       = qw(Exporter);
@EXPORT    = qw(dex dex_warn dex_text dex_html ctrace dex_trace);
@EXPORT_OK = qw(dex dex_warn dex_text dex_html ctrace dex_trace debug caller_trace);

### is on or off
sub on  { $ON = 1 };
sub off { $ON = 0; }

sub set_deparse { $DEPARSE = 1 }

###----------------------------------------------------------------###

BEGIN {
  on();

  $SUB = sub {
    ### setup the Data::Dumper usage
    local $Data::Dumper::Deparse   = $DEPARSE && eval {require B::Deparse};
    local $Data::Dumper::Pad       = '  ';
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Quotekeys = 0;

    require Data::Dumper;
    return Data::Dumper->Dumpperl(\@_);
  };

  ### how to display or parse the filename
  $QR1 = qr{\A(?:/[^/]+){2,}/(?:perl|lib)/(.+)\Z};
  $QR2 = qr{\A.+?([\w\.\-]+/[\w\.\-]+)\Z};
}

###----------------------------------------------------------------###


### same as dumper but with more descriptive output and auto-formatting
### for cgi output
sub _what_is_this {
  return if ! $ON;
  ### figure out which sub we called
  my ($pkg, $file, $line_n, $called) = caller(1 + ($CALL_LEVEL || 0));
  substr($called, 0, length(__PACKAGE__) + 2, '');

  ### get the actual line
  my $line = '';
  if (open(IN,$file)) {
    $line = <IN> for 1 .. $line_n;
    close IN;
  }

  ### get rid of extended filename
  if (! $full_filename) {
    $file =~ s/$QR1/$1/ || $file =~ s/$QR2/$1/;
  }

  ### dump it out
  my @dump = map {&$SUB($_)} @_;
  my @var  = ('$VAR') x ($#dump + 1);
  my $hold;
  if ($line =~ s/^ .*\b \Q$called\E ( \s* \( \s* | \s+ )//x
      && ($hold = $1)
      && (   $line =~ s/ \s* \b if \b .* \n? $ //x
          || $line =~ s/ \s* ; \s* $ //x
          || $line =~ s/ \s+ $ //x)) {
    $line =~ s/ \s*\) $ //x if $hold =~ /^\s*\(/;
    my @_var = map {/^[\"\']/ ? 'String' : $_} split (/\s*,\s*/, $line);
    @var = @_var if $#var == $#_var;
  }

  ### spit it out
  if ($called eq 'dex_text'
      || $called eq 'dex_warn'
      || ! $ENV{REQUEST_METHOD}) {
    my $txt = "$called: $file line $line_n\n";
    for (0 .. $#dump) {
      $dump[$_] =~ s|\$VAR1|$var[$_]|g;
      $txt .= $dump[$_];
    }
    if    ($called eq 'dex_text') { return $txt }
    elsif ($called eq 'dex_warn') { warn  $txt  }
    else                          { print $txt  }
  } else {
    my $html = "<pre class=debug><span class=debughead><b>$called: $file line $line_n</b></span>\n";
    for (0 .. $#dump) {
      $dump[$_] =~ s/(?<!\\)\\n/\n/g;
      $dump[$_] = _html_quote($dump[$_]);
      $dump[$_] =~ s|\$VAR1|<span class=debugvar><b>$var[$_]</b></span>|g;
      $html .= $dump[$_];
    }
    $html .= "</pre>\n";
    return $html if $called eq 'dex_html';
    require CGI::Ex;
    CGI::Ex::print_content_type();
    print $html;
  }
  return @_[0..$#_];
}

### some aliases
sub debug    { &_what_is_this }
sub dex      { &_what_is_this }
sub dex_warn { &_what_is_this }
sub dex_text { &_what_is_this }
sub dex_html { &_what_is_this }

sub _html_quote {
  my $value = shift;
  return '' if ! defined $value;
  $value =~ s/&/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
#  $value =~ s/\"/&quot;/g;
  return $value;
}

### ctrace is intended for work with perl 5.8 or higher's Carp
sub ctrace {
  require 5.8.0;
  require Carp::Heavy;
  local $Carp::MaxArgNums = 3;
  local $Carp::MaxArgLen  = 20;
  my $i = shift || 0;
  my @i = ();
  my $max1 = 0;
  my $max2 = 0;
  my $max3 = 0;
  while (my %i = Carp::caller_info(++$i)) {
    $i{sub_name} =~ s/\((.*)\)$//;
    $i{args} = $i{has_args} ? $1 : "";
    $i{sub_name} =~ s/^.*?([^:]+)$/$1/;
    $i{file} =~ s/$QR1/$1/ || $i{file} =~ s/$QR2/$1/;
    $max1 = length($i{sub_name}) if length($i{sub_name}) > $max1;
    $max2 = length($i{file})     if length($i{file})     > $max2;
    $max3 = length($i{line})     if length($i{line})     > $max3;
    push @i, \%i;
  }
  foreach my $ref (@i) {
    $ref = sprintf("%-${max1}s at %-${max2}s line %${max3}s", $ref->{sub_name}, $ref->{file}, $ref->{line})
      . ($ref->{args} ? " ($ref->{args})" : "");
  }
  return \@i;
}

*caller_trace = \&ctrace;

sub dex_trace {
  _what_is_this(ctrace(1));
}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

  use CGI::Ex::Dump; # auto imports dex, dex_warn, dex_text and others

  my $hash = {
    foo => ['a', 'b', 'Foo','a', 'b', 'Foo','a', 'b', 'Foo','a'],
  };

  dex $hash; # or dex_warn $hash;

  dex;

  dex "hi";

  dex $hash, "hi", $hash;

  dex \@INC; # print to STDOUT, or format for web if $ENV{REQUEST_METHOD}

  dex_warn \@INC;  # same as dex but to STDOUT

  print FOO dex_text \@INC; # same as dex but return dump

  # ALSO #

  use CGI::Ex::Dump qw(debug);
  
  debug; # same as dex

=head1 DESCRIPTION

Uses the base Data::Dumper of the distribution and gives it nicer formatting - and
allows for calling just about anytime during execution.

Calling &CGI::Ex::set_deparse() will allow for dumped output of subroutines
if available.

perl -e 'use CGI::Ex::Dump;  dex "foo";'

See also L<Data::Dumper>.

Setting any of the Data::Dumper globals will alter the output.

=head1 SUBROUTINES

=over 4

=item C<dex>, C<debug>

Prints out pretty output to STDOUT.  Formatted for the web if on the web.

=item C<dex_warn>

Prints to STDERR.

=item C<dex_text>

Return the text as a scalar.

=item C<ctrace>

Caller trace returned as an arrayref.  Suitable for use like "debug ctrace".
This does require at least perl 5.8.0's Carp.

=item C<on>, C<off>

Turns calls to routines on or off.  Default is to be on.

=back

=head1 LICENSE

This module may distributed under the same terms as Perl itself.

=head1 AUTHORS

Paul Seamons <perl at seamons dot com>

=cut
