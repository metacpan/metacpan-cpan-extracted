package App::Brl2Brl;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;
use Exporter qw(import);
our @EXPORT_OK = qw(parse_dis Conv switch_brl_char_map);

=head1 NAME

App::Brl2Brl - Convert between braille character sets.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use App::Brl2Brl;

    my %from_table = parse_dis( "$table_path/$from_table_file" );
    my %to_table = parse_dis( "$table_path/$to_table_file" );
    while( <> ){
      my $s = Conv( \%from_table, \%to_table, $_);
      print "$s";
    }



sub new {
  my $class = shift;
  my $from_table_file = shift;
  my $to_table_file = shift;
  my $self = {};
  bless( $self, $class );
  %{ $self->{frm} } = parse_dis( $from_table_file );
  %{ $self->{to} } = parse_dis( $to_table_file );
  return $self;
}

sub switch_map {
  my $self = shift;
  my $inputstr = shift;
  my $outputstr = Conv( $self->{frm}, $self->{to}, $inputstr );
  return $outputstr;
}


=head2 parse_dis

Parses a liblouis .dis table file and return a hash with the
characters and dots respectively.

=cut

sub parse_dis {
  my $fileName = shift;
  my ($char, $dots, %table);
  open( DIS, "<", $fileName) || die "Error opening file $fileName;";
  while( my $line = <DIS>) {
    $char = '';
    $dots = 0;
    next unless( $line =~ /^display/i);
    ($char, $dots) = $line =~ /display\s+(\S+)\s+(\S+)/i;
    if( length($char) >=4 ){ # $char is a hex value, not a char.
      #$charhex = "u";
      #$charhex = sprintf '%2.2x', unpack('U0U*', $char);
      #$charhex .= sprintf "%04x", ord Encode::decode("UTF-8", $char);
      $char =~ s/\\x//i;
      $char =~ s/(....)/ pack( 'U*', hex($1))/ie;
    }
    if( !defined($table{$char})) {
      if( $dots =~ /^$/ ){
	$dots = 0;
      }
      $char =~ s/^\\\\$/\\/;
      $table{$char} = $dots;
    }
  }
  close( DIS );
  return( %table );
}


=head2 Conv

Converts a string, character by character, from %from_table to %to_table.

=cut

sub Conv {
  my %from_tab = %{shift()};
  my %to_tab = %{shift()};
  my $inputstr = shift;
  my( $dots, $outC, $outstr);
  foreach my $inC (split( //, $inputstr )){
    if( !exists $from_tab{$inC} ) {
      $outstr .= $inC;
      #warn "Character $inC isn't defined in input table!\n";
      next;
    }
    $dots = 0;
    $outC = '';
    $dots = $from_tab{$inC};
    for my $outkey (keys %to_tab) {
      if( $to_tab{$outkey} =~ /^$dots$/ ){
	$outC = $outkey;
	$outstr .= $outC;
      }
    }
    if( $outC =~ /^$/ ){
      $outstr .= $inC;
      warn "dots $dots isn't defined in output table!\n";
    }
  }
  return $outstr;
}

sub switch_brl_char_map {
  my $from_table_file = shift;
  my $to_table_file = shift;
  my $s = shift;
  my %from_table = parse_dis( $from_table_file );
  my %to_table = parse_dis( $to_table_file );
  return Conv( \%from_table, \%to_table, $s );
}

=head1 AUTHOR

Lars Bjørndal, C<< <lars at lamasti.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-App-brl2brl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Brl2Brl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Brl2Brl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Brl2Brl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Brl2Brl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Brl2Brl>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Brl2Brl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Lars Bjørndal.

LICENSE

Artistic

=cut

1; # End of App::Brl2Brl
