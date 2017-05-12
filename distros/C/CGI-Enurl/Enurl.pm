
=head1 NAME

CGI::Enurl.pm - module for URL-encoding strings and hashes

version 1.07

=head1 SYNOPSIS

 use CGI::Enurl;
 %hash = (name=>'Jenda Krynicky',address=>'Nerudova 1016');
 print "Location: http://$ENV{SERVER_NAME}/cgi-bin/do.pl?",enurl \%hash,"\n\n";

=head1 DESCRIPTION

This is a little module made for CGI scripting. It encodes the parameters
to be passed to a CGI. It does nothing more, so it's much smaller and loads
more quickly.

=head1 Functions

=over 2

=item enurl STRING

=item enurl ARRAY

=item enurl HASH

Encodes the parameter. If the parameter is a single string
it encodes it and returns the encoded form.

If it is an array or a reference to an array it encodes all
items and returns them joined by '&'.

If it is a hash it encodes the values and return a querystring in form
"key2=encoded_value1&key2=encoded_value2&...".

!!! Please note that a hash in a list context returns a list of all
keys and values. This means that if you call enurl(%hash) you will NOT
get what you may thing you should. You HAVE to use enurl(\%hash) !!!

=item enURL STRING

Encodes the parameter, this version doesn't encode '=' and '&' characters,
so you should make sure they are not present in the data.

Notice the difference :

 enurl 'a&b=f o o'   =>   'a%26b%3Df+o+o'
 enURL 'a&b=f o o'   =>   'a&b=f+o+o'

=item $CGI::Enurl::ParamSeparator

You may specify another character to be used as the parameter separator.
Simply set this variable to the character (or string) you want to use.

The default value is '&'

=item $CGI::Enurl::KeepUnencoded

This variable contains the characters that should stay unencoded.
Please keep in mind that the string will be interpolated into a regexp
in a [^...] group!

Any change of this variable will be ignored after the first call to
enurl or enURL. (I'm using /o switch in the regexp.) So if you want to
change the variable you should do it as soon as posible. You may do that
even before you "use" the module!

The default value is 'a-zA-Z 0-9_\\-@.='

=back

=head2 EXAMPLE:

 use CGI::Enurl;

 print "Location: http://www.somewhere.com/Scripts/search.pl?",
  enurl('something strange'),"\n\n";

or

 use CGI::Enurl;

 print "Location: http://www.somewhere.com/Scripts/search.pl?",
  enurl('something strange','and other',666),"\n\n";

or

 use CGI::Enurl;

 print "Location: http://www.somewhere.com/Scripts/myscript.pl?",
  enurl({fname => 'Jan',lname => 'Krynický',tel => '+420-2-9618 1234'},1),"\n\n";

or

 use CGI::Enurl;

 print "Location: http://www.somewhere.com/Scripts/myscript.pl?",
  enURL('fname=Jan&lname=Krynický&tel=+420-2-9618 1234&1',"\n\n";


or using the tricks of Interpolation.pm - http://www.plover.com/~mjd/perl/Interpolation/manual.html

 use CGI::Enurl;
 use Interpolation URL => \&enurl;
 print "name=$URL{'Jann Linder, jr'}&address=$URL{'129 kjhlkjd st'}";

or even

 use CGI::Enurl;
 use Interpolation enurl => sub {my %hash=split /$;/o,$_[0];enurl \%hash};
  # use other name instead of enurl if you like.

 print "script.pl?$enurl{name=>'Jenda Krynicky',address=>'Nerudova 1016'}\n";

 %hash = (name=>'Jenda Krynicky',address=>'Nerudova 1016');

 sub var {
  if (ref $_[0] eq 'HASH') {
    join $;, %{shift()}, @_;
  } else {
    join $;, @_;
  }
 }

 print "script.pl?$enurl{var %hash}\n";
	 # the "var" is necessary !
     # without it you will get : "Odd number of elements in hash list at ... line 2."

 print "script.pl?$enurl{var %hash,age=>22}\n";

     # you may omit the "var" only if you enter the hash as a constant directly
     # into $enurl{...}.

If you want to be cheeky you may use '$?{}' as the interpolator:

 use CGI::Enurl;
 use Interpolation '?' => sub {my %hash=split /$;/o,$_[0]; '?' . enurl \%hash};

 print "cript.pl$?{a=>5,b=>7,n=>'Jenda Krynicky'}\n";

or

 use CGI::Enurl;
 use Interpolation '?' => sub {'?' . enURL $_[0]};

 print "cript.pl$?{'a=5&b=7&n=Jenda Krynicky'}\n";
 # # or
 # print qq{cript.pl$?{"a=5&b=7&n=$name"}\n};

Please read the docs for enurl versus enURL so that you understand the difference!

=cut

#!/big/bin/perl
package CGI::Enurl;
$VERSION='1.07';
require Exporter;
@ISA = (Exporter);
@EXPORT = qw(&enurl &enURL);
@EXPORT_OK = qw(&enurl &enURL &enurl_str);

$ParamSeparator = '&' unless $ParamSeparator;
$KeepUnencoded = 'a-zA-Z 0-9_\\-@.=' unless $KeepUnencoded;

sub enurl {
 my @data;
 my $item;
 foreach $item (@_) {
  if (ref $item eq 'HASH') {
   my $key;
   foreach $key (keys %$item) {
    if ($key =~ /^\d+$/) {
     if (ref $item->{$key} eq 'ARRAY') {
         foreach (@{$item->{$key}}) {
             push @data,enurl_str($_);
         }
     } else {
         push @data,enurl_str($item->{$key});
     }
    } else {
     if (ref $item->{$key} eq 'ARRAY') {
         foreach (@{$item->{$key}}) {
             push @data,(enurl_str($key).'='.enurl_str($_));
         }
     } else {
         push @data,(enurl_str($key).'='.enurl_str($item->{$key}));
     }
    }
   }
  } elsif (ref $item eq 'ARRAY') {
   my $x;
   foreach $x (@$item) {
    push @data,enurl_str($x);
   }
  } else {
   push @data,enurl_str($item);
  }
 }
 return (join $ParamSeparator, @data);
}

#sub enurl_str ($);
sub enurl_str {
    my($toencode) = @_;
    $toencode=~s/([^$KeepUnencoded])/sprintf("%%%02X",ord($1))/ego;
    $toencode=~s/ /+/gm;
    return $toencode;
}

#sub enURL ($);
sub enURL {
    my($toencode) = @_;
    $toencode=~s/([^$ParamSeparator$KeepUnencoded])/sprintf("%%%02X",ord($1))/ego;
    $toencode=~s/ /+/gm;
    return $toencode;
}

1;

=head2 DISCLAIMER

The enurl_str function is taken from CGI.pm. (It's named 'escape' there.) Thanks.

=head2 AUTHOR

Jan Krynicky <Jenda@Krynicky.cz>

=head2 COPYRIGHT

Copyright (c) 1997-2001 Jan Krynicky <Jenda@Krynicky.cz>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

