package App::vaporcalc::FormatString;
$App::vaporcalc::FormatString::VERSION = '0.005004';
use Defaults::Modern;

use parent 'Exporter::Tiny';
our @EXPORT = our @EXPORT_OK = 'format_str';

sub format_str {
  my $string = shift;
  return '' unless defined $string and length $string;

  my %vars = @_ > 1 ? @_ 
    : ref $_[0] && reftype $_[0] eq 'HASH' ? %{$_[0]} 
    : ();

  my $rpl = sub {
    my ($orig, $match) = @_;
    if (defined $vars{$match}) {
      return ref $vars{$match} eq 'CODE' ?
        $vars{$match}->($match, $orig, $vars{$match})
        : $vars{$match}
    }
    $orig
  };

  state $re = qr/(%([^\s%]+)%?)/;
  $string =~ s/$re/$rpl->($1, $2)/ge;

  $string
}

1;

=pod

=head1 NAME

App::vaporcalc::FormatString - Templated string formatter

=head1 SYNOPSIS

  my $things = "some very special";
  my $formatted = format_str( "My %string% with %this% var",
    this   => $things,
    string => "cool string",
  );  ## -> My cool string with some very special var

=head1 DESCRIPTION

A tiny string formatter.

Exports a single function: L</format_str>

=head2 format_str

Takes a string and a hash (or hash reference) mapping template variables to
replacement strings.

The replacement variables can be coderefs returning a string:

  format_str( "My string with %code",
    code => sub {
      my ($match, $orig, $callback) = @_;
      . . .
      return "Some string replacing variable $match"
    },
  );

The code reference will receive the matching variable ("code"), the original matched
string ("%code" in the above example), and itself as its respective arguments.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
