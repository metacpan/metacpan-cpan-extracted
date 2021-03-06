package Data::Dumper::Lazy;
use strict;
use warnings;

use B::Deparse;
use Data::Dumper;
$Data::Dumper::Indent=0;
$Data::Dumper::Terse=1;


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw(dmp);
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

#-- init deparse code-block
my $deparse = B::Deparse->new("-q");
# $deparse->ambient_pragmas(
#     strict => 'all', warnings =>'all'
#    );


sub dmp (&){
  my ($block)=@_;

  my $body = $deparse->coderef2text($block);

  # trim body, remove curlies
  $body =~ s/^{\s*//s;
  $body =~ s/;\s*}$//s;

  # TODO delete pragmas 
  $body =~ s/^\s*(no|use) .*?;\s*?\n//sg;
  
  my @varnames = split /\s*,\s*/,$body;
  my $max=1;
  my $is_flat=0;
  my $r_ident=qr/[a-zA-Z][a-zA-Z0-9]*/;
  my $r_full=qr/((::)?$r_ident)+/;

  #  parse multiple variable names
  #  guess if array or hash was flattened
  
  for my $name (@varnames) {
      my $len = length($name);
      $max=$len if $max<$len;
      print "<$body>\n";
      my ($ref,$sigils,$full)=
	$name =~ /\s*(\\*) \s* ([*@%\$]+) ($r_full) /x;
      $is_flat++
	unless $ref or $sigils =~ /^\$/;
  }

  my @vars     = &$block;

  #  if scalars can't be distinguished, dump all
  if ($is_flat) {
      print "$body  =>  ";
      print Dumper(\@vars),";\n";
      # print "(",join (",",@vars),");\n";
      return;
  }

  #  align multiple vars
  for ( my $i=0; $i<@varnames; $i++ ) {
    printf "%-${max}s => ",$varnames[$i];
    print Dumper($vars[$i]),";\n";
  }
  print "\n";
}

#  TODO
#  * ignore pragmas

1;
__END__

=head1 NAME

Data::Dumper::Lazy - Easily dump variables with names

=head1 SYNOPSIS

  use Data::Dumper::Lazy;
  @a = 1..5;
  dmp {@a};


=head1 DESCRIPTION

THIS MODULE IS UNDER CONSTRUCTION

This module allow the user to dump variables in a Data::Dumper format.

Unlike the default behavior of Data::Dumper, the variables are named
(instead of $VAR1, $VAR2, etc.)  Data::Dumper provides an extended
interface that allows the programmer to name the variables, but this
interface requires a lot of typing and is prone to typos (sic).
(paragraph copied from Data::Dumper::Simple's abstract)

The variables have to be passed within a code-block i.e. surrounded by
curlies.  Their names are gathered by inspecting the op-tree the
block's op-tree with the help of B::Deparse.

This avoids the limitations of Data::Dumper::Simple (using Source
Filter) and Data::Dumper::Names (using PadWalker).


=head1 USAGE

use Data::Dumper::Lazy;


=head1 BUGS

Please report any bugs or feature requests to
bug-data-dumper-lazy@rt.cpan.org, or through the web interface at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Dumper-Lazy. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make chang es.

=head1 SUPPORT



=head1 AUTHOR

    Rolf Michael Langsdorf
    CPAN ID: LanX
    Darmstadt PM
    lanx@cpan.org
    http://www.perlmonks.org/?node=LanX

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut





