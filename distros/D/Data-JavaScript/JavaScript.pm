package Data::JavaScript;
require 5;
use vars qw(@EXPORT @EXPORT_OK %OPT $VERSION);
%OPT = (JS=>1.3);
$VERSION = 1.13;

@EXPORT = qw(jsdump hjsdump);
@EXPORT_OK = '__quotemeta';

use strict;
require Encode unless $] < 5.007;

sub import{
  my $package = shift;

  foreach( @_ ){
    if(ref($_) eq 'HASH'){
      $OPT{JS} = $$_{JS} if exists($$_{JS});
      $OPT{UNDEF} = $$_{UNDEF} if exists($$_{UNDEF});
    }
  }
  $OPT{UNDEF} ||=  $OPT{JS} > 1.2 ? 'undefined' : q('');

  #use (); #imports nothing, as package is not supplied
  if( defined $package ){
    no strict 'refs';

    #Remove options hash
    my @import = grep { ! length ref } @_;

    if( scalar @import ){
      if( grep {/^:all$/} @import ){
	@import = (@EXPORT, @EXPORT_OK) }
      else{
	#only user-specfied subset of @EXPORT, @EXPORT_OK
	my $q = qr/@{[join('|', @EXPORT, @EXPORT_OK)]}/;
	@import = grep { $_ =~ /$q/ } @import;
      }
    }
    else{
      @import = @EXPORT;
    }
    
    my $caller = caller;
    for my $func (@import) {
      *{"$caller\::$func"} = \&$func;
    }
  }
}

sub hjsdump {
    my @res = (qq(<script type="text/javascript" language="JavaScript$OPT{JS}" />),
	       '<!--', &jsdump(@_), '// -->', '</script>');
    wantarray ? @res : join("\n", @res, "");
}

sub jsdump {
    my $sym  = shift;
    return "var $sym;\n" unless (@_);
    my $elem  = shift;
    my $undef = shift;
    my %dict;
    my @res   = __jsdump($sym, $elem, \%dict, $undef);
    $res[0]   = "var " . $res[0];
    wantarray ? @res : join("\n", @res, "");
}


my $QMver;
if( $] < 5.007 ){
  $QMver=<<'EO5';
    s<([^ \x21-\x5B\x5D-\x7E]+)>{sprintf(join('', '\x%02X' x length$1), unpack'C*',$1)}ge;
EO5
}
else{
  $QMver=<<'EO58';
    if( $OPT{JS} >= 1.3 && Encode::is_utf8($_) ){
        s<([\x{0080}-\x{fffd}]+)>{sprintf '\u%0*v4X', '\u', $1}ge;
    }

    {
      use bytes;
      s<((?:[^ \x21-\x7E]|(?:\\(?!u)))+)>{sprintf '\x%0*v2X', '\x', $1}ge;
    }
EO58
}

eval 'sub __quotemeta {local $_ = shift;' . $QMver . <<'EOQM';

    #This is kind of ugly/inconsistent output for munged UTF-8
    #tr won't work because we need the escaped \ for JS output
    s/\\x09/\\t/g;
    s/\\x0A/\\n/g;
    s/\\x0D/\\r/g;
    s/"/\\"/g;
    s/\\x5C/\\\\/g;

    #Escape </script> for stupid browsers that stop parsing
    s%</script>%\\x3C\\x2Fscript\\x3E%g;

    return $_;
  }
EOQM


sub __jsdump {
    my ($sym, $elem, $dict, $undef) = @_;
    my $ref;

    unless( $ref = ref($elem) ){
      unless( defined($elem) ){
	return "$sym = @{[defined($undef) ? $undef : $OPT{UNDEF}]};";
      }

      #Translated from $Regexp::Common::RE{num}{real}
      if( $elem =~ /^[+-]?(?:(?=\d|\.)\d*(?:\.\d{0,})?)$/ ){
#                                                      (?:[eE][+-]?\d+)?
	  return qq($sym = "$elem";) if $elem =~ /^0\d+$/;
	  return "$sym = $elem;";
      }

      #Fall-back to quoted string
      return qq($sym = ") . __quotemeta($elem) . '";';
    }

    #Circular references
    if ($dict->{$elem}) {
        return "$sym = " . $dict->{$elem} . ";";
    }
    $dict->{$elem} = $sym;

    #isa over ref in case we're given objects
    if( $ref eq 'ARRAY' || UNIVERSAL::isa($elem, 'ARRAY') ){
        my @list = ("$sym = new Array;");
        my $n = 0;
        foreach (@$elem) {
            my $newsym = "$sym\[$n]";
            push(@list, __jsdump($newsym, $_, $dict, $undef));
            $n++;
        }
        return @list;
    }
    elsif(  $ref eq 'HASH' || UNIVERSAL::isa($elem, 'HASH') ){
        my @list = ("$sym = new Object;");
        my ($k, $old_k, $v);
        foreach $k (sort keys %$elem) {
	  $k = __quotemeta($old_k=$k);
	  my $newsym = qq($sym\["$k"]);
	  push(@list, __jsdump($newsym, $elem->{$old_k}, $dict, $undef));
        }
        return @list;
    }
    else{
      return "//Unknown reference: $sym=$ref";
    }
}


1;
__END__

=head1 NAME

Data::JavaScript - Dump perl data structures into JavaScript code

=head1 SYNOPSIS

  use Data::JavaScript;                     # Use defaults
  
  @code =  jsdump('my_array',  $array_ref); # Return array for formatting
  $code =  jsdump('my_object', $hash_ref);  # Return convenient string
  $html = hjsdump('my_stuff',  $reference); # Convenience wrapper

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
