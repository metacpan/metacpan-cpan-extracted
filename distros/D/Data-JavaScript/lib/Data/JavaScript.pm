package Data::JavaScript;    ## no critic (PodSpelling)

use Modern::Perl;
use Readonly;
use Scalar::Util 'reftype';

our $VERSION = '1.16';

# Exporter
Readonly our @EXPORT      => qw(jsdump hjsdump);
Readonly our @EXPORT_OK   => '__quotemeta';
Readonly our %EXPORT_TAGS => (
  all    => [ @EXPORT, @EXPORT_OK ],
  compat => [@EXPORT],
);

# Magic numbers
Readonly my $MIN_ENCODE_REQUIRE_BREAKPOINT => 5.007;
Readonly my $JSCOMPAT_DEFAULT_VERSION      => 1.3;
Readonly my $JSCOMPAT_UNDEFINED_MISSING    => 1.2;

# This is a context variable which holds on to configs.
my %opt = ( JS => $JSCOMPAT_DEFAULT_VERSION );  # TODO: This is super out-dated.

if ( $] >= $MIN_ENCODE_REQUIRE_BREAKPOINT ) { require Encode; }

sub import {
  my ( $package, @args ) = @_;

  # Let's get the stuff we're going to import
  my @explicit_imports = ();
  my @import           = ();
  my %allowable        = map { $_ => 1 } ( @EXPORT, @EXPORT_OK );

  # This is the madness for the JS version
  for my $arg (@args) {
    if ( ref $arg eq 'HASH' ) {
      if ( exists $arg->{JS} )    { $opt{JS}    = $arg->{JS}; }
      if ( exists $arg->{UNDEF} ) { $opt{UNDEF} = $arg->{UNDEF}; }
    }
    elsif ( not ref $arg ) {
      push @explicit_imports, $arg;
    }
  }
  $opt{UNDEF} ||= $opt{JS} > $JSCOMPAT_UNDEFINED_MISSING ? 'undefined' : q('');

  #use (); #imports nothing, as package is not supplied
  if ( defined $package ) {

    if ( scalar @explicit_imports ) {

      # Run through the explicitly exported symbols
      for my $explicit_import (@explicit_imports) {

        # Looks like a tag
        if ( substr( $explicit_import, 0, 1 ) eq q/:/ ) {
          my $tag = substr $explicit_import, 1;

          # Only do things for the actually exported tags.
          if ( not exists $EXPORT_TAGS{$tag} ) { next; }
          push @import, @{ $EXPORT_TAGS{$tag} };
        }

        # Not a tag
        elsif ( exists $allowable{$explicit_import} ) {

          #only user-specfied subset of @EXPORT, @EXPORT_OK
          push @import, $explicit_import;
        }
      }
    }
    else {
      @import = @EXPORT;
    }

    my $caller = caller;
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    for my $func (@import) {
      *{"$caller\::$func"} = \&{$func};
    }
    use strict 'refs';
  }

  return;
}

sub hjsdump {
  my @input = @_;

  my @res = (
    qq(<script type="text/javascript" language="JavaScript$opt{JS}" />),
    '<!--', jsdump(@input), '// -->', '</script>',
  );
  return wantarray ? @res : join qq/\n/, @res, q//;
}

sub jsdump {
  my ( $sym, @input ) = @_;

  return "var $sym;\n" if ( not scalar @input );
  my ( $elem, $undef ) = @input;
  my %dict = ();
  my @res  = __jsdump( $sym, $elem, \%dict, $undef );
  $res[0] = qq/var $res[0]/;
  return wantarray ? @res : join qq/\n/, @res, q//;
}

sub __quotemeta {
  my ($input) = @_;

  ## ENCODER!
  if ( $] < $MIN_ENCODE_REQUIRE_BREAKPOINT ) {
    $input =~ s{
      ([^ \x21-\x5B\x5D-\x7E]+)
    }{
      sprintf(join('', '\x%02X' x length$1), unpack'C*',$1)
    }gexsm;
  }
  else {
    if ( $opt{JS} >= $JSCOMPAT_DEFAULT_VERSION && Encode::is_utf8($input) ) {
      $input =~ s{
        ([\x{0080}-\x{fffd}]+)
      }{
        sprintf '\u%0*v4X', '\u', $1
      }gexms;
    }

    {
      use bytes;
      $input =~ s{
          ((?:[^ \x21-\x7E]|(?:\\(?!u)))+)
        }{
          sprintf '\x%0*v2X', '\x', $1
        }gexms;
    }

  }

  #This is kind of ugly/inconsistent output for munged UTF-8
  #tr won't work because we need the escaped \ for JS output
  $input =~ s/\\x09/\\t/gxms;
  $input =~ s/\\x0A/\\n/gxms;
  $input =~ s/\\x0D/\\r/gxms;
  $input =~ s/"/\\"/gxms;
  $input =~ s/\\x5C/\\\\/gxms;

  #Escape </script> for stupid browsers that stop parsing
  $input =~ s{</script>}{\\x3C\\x2Fscript\\x3E}gxms;

  return $input;
}

sub __jsdump {
  my ( $sym, $elem, $dict, $undef ) = @_;
  my $ref = ref $elem;

  if ( not $ref ) {
    if ( not defined $elem ) {
      return qq($sym = @{[defined($undef) ? $undef : $opt{UNDEF}]};);
    }

    #Translated from $Regexp::Common::RE{num}{real}
    if ( $elem ne '.' &&
	 $elem =~ /^[+-]?(?:(?=\d|[.])\d*(?:[.]\d{0,})?)(?:[eE][+-]?\d+)?$/xsm ) {

      if( $elem =~ /^0\d+$/xsm ){
        return qq($sym = "$elem";) }
      return qq($sym = $elem;);
    }

    #Fall-back to quoted string
    return qq($sym = ") . __quotemeta($elem) . '";';
  }

  #Circular references
  if( $dict->{$elem} ){
    return qq($sym = $dict->{$elem};) }
  $dict->{$elem} = $sym;

  #isa over ref in case we're given objects
  if ( $ref eq 'ARRAY' || reftype $elem eq 'ARRAY' ) {
    my @list = ("$sym = new Array;");
    my $n    = 0;
    foreach my $one ( @{$elem} ) {
      my $newsym = "$sym\[$n]";
      push @list, __jsdump( $newsym, $one, $dict, $undef );
      $n++;
    }
    return @list;
  }
  elsif ( $ref eq 'HASH' || reftype $elem eq 'HASH' ) {
    my @list = ("$sym = new Object;");
    foreach my $k ( sort keys %{$elem} ) {
      my $old_k;
      $k = __quotemeta( $old_k = $k );
      my $newsym = qq($sym\["$k"]);
      push @list, __jsdump( $newsym, $elem->{$old_k}, $dict, $undef );
    }
    return @list;
  }
  else {
    return "//Unknown reference: $sym=$ref";
  }
}

1;
## no critic (RequirePodSections)
__END__

=head1 NAME

Data::JavaScript - Dump perl data structures into JavaScript code

=head1 SYNOPSIS

  # Compatibility mode
  {
    use Data::JavaScript;                     # Use defaults
  
    my @code =  jsdump('my_array',  $array_ref); # Return array for formatting
    my $code =  jsdump('my_object', $hash_ref);  # Return convenient string
    my $html = hjsdump('my_stuff',  $reference); # Convenience wrapper
  };

=head1 DESCRIPTION

This module is mainly intended for CGI programming, when a perl script
generates a page with client side JavaScript code that needs access to
structures created on the server.

It works by creating one line of JavaScript code per datum. Therefore,
structures cannot be created anonymously and need to be assigned to
variables. However, this format enables dumping large structures.

The module can output code for different versions of JavaScript.
It currently supports 1.1, 1.3 and you specify the version on the
C<use> line like so:

  use Data::JavaScript {JS=>1.3};          # The new default
  use Data::JavaScript {JS=>1.1};          # Old (pre module v1.10) format

JavaScript 1.3 contains support for UTF-8 and a native C<undefined> datatype.
Earlier versions support neither, and will default to an empty string C<''>
for undefined values. You may define your own default--for either version--at
compile time by supplying the default value on the C<use> line:

  use Data::JavaScript {JS=>1.1, UNDEF=>'null'};

Other useful values might be C<0>, C<null>, or C<NaN>.

=head1 EXPORT

In addition, althought the module no longer uses Exporter, it heeds its
import conventions; C<qw(:all>), C<()>, etc.

=over

=item jsdump('name', \$reference, [$undef]);

The first argument is required, the name of JavaScript object to create.

The second argument is required, a hashref or arrayref.
Structures can be nested, circular referrencing is supported (experimentally).

The third argument is optional, a scalar whose value is to be used en lieu
of undefined values when dumping a structure.

When called in list context, the function returns a list of lines.
In scalar context, it returns a string.

=item hjsdump('name', \$reference, [$undef]);

hjsdump is identical to jsdump except that it wraps the content in script tags.

=back

=head1 EXPORTABLE

=over

=item __quotemeta($str)

This function escapes non-printable and Unicode characters (where possible)
to promote playing nice with others.

=back

=head1 CAVEATS

Previously, the module eval'd any data it received that looked like a number;
read: real, hexadecimal, octal, or engineering notations. It now passes all
non-decimal values through as strings. You will need to C<eval> on the client
or server side if you wish to use other notations as numbers. This is meant
to protect people who store ZIP codes with leading 0's.

Unicode support requires perl 5.8 or later. Older perls will gleefully escape
the non-printable portions of any UTF-8 they are fed, likely munging it in
the process as far as JavaScript is concerned. If this turns out to be a
problem and there is sufficient interest it may be possible to hack-in UTF-8
escaping for older perls.

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or if you truly insist, you may use and distribute this under ther terms
of Perl itself (GPL and/or Artistic License).

=head1 SEE ALSO

L<Data::JavaScript::LiteObject>, L<Data::JavaScript::Anon>, L<CGI::AJAX|CGI::Ajax>

=head1 AUTHOR

Maintained by Jerrad Pierce <jpierce@cpan.org>

Created by Ariel Brosh <schop cpan.org>.
Inspired by WDDX.pm JavaScript support.

=cut
