=head1 NAME

CGI::Deurl.pm - a CGI parameter decoding package

version 1.08

=head1 SYNOPSIS

 use CGI::Deurl as => 'q';
 ...
 print "$q{ParamName}\n";

=head1 DESCRIPTION

This is a little module made for CGI scripting. It decodes the parameters
passed to the CGI. It does nothing more, so it's much smaller and loads
more quickly than CGI.pm.

Since version 0.04 it also exports the C<deurl>, C<deurlstr> and C<deurlarr>
functions so that you are able to decode not only the parameters your
CGI got, but also an arbitrary string.

=head2 Reading CGI query

The module can take the arguments from several sources. CGI::Deurl tests the environmental
variable 'REQUEST_METHOD' to find the arguments.

=over 4

=item REQUEST_METHOD=POST

CGI::Deurl slurps in it's STDIN and parses it, then it tests
$ENV{QUERY_STRING} and if defined parses the data as well.

=item REQUEST_METHOD=GET

 CGI::Deurl reads $ENV{QUERY_STRING} and parses the contents.

=item REQUEST_METHOD not defined

CGI::Deurl tests ARGV and parses all it's arguments.
If it didn't find any args it reads it's STDIN line by line
until EOF and parses all the lines. This is handy if you want
to test a CGI script from command prompt. You may specify the parameters
either on the command line or enter them after the script starts to run.

=back

If you C<use CGI::Deurl NOTCGI;> the module doesn't look for the parameters
and just exports the functions. This is handy if you use CGI::Deurl.pm in a
script that is not a CGI.

=head2 Using query variables

The data are stored in a hash C<%CGI::Deurl::query>, but CGI::Deurl provides
two ways to specify otherwise. They may be stored either in a hash
you specify or be exported into a package.

=head2 "use" statement options

=over 4

=item lc

If you use the option 'lc' all names of the parameters are converted
to lowercase. This way you may get case insensitive parameters.

=item uc

This option is similar to 'lc'. It converts the names to uppercase.

=item as variable

If you use CGI::Deurl qw(as variablename); CGI::Deurl uses  variable
%variablename from package main
to store the data (%CGI::Deurl::query works as well, this is just
a nickname).

=item use CGI::Deurl export;

All the query variables are exported into package CGI::Deurl.
That means that if the query was "?x=5&y=24", you can
use $CGI::Deurl::x + $CGI::Deurl::y. Again %CGI::Deurl::query works
as usual.

=item use CGI::Deurl export Package;

All the query values are exported into Package.
That means that if the query was "?x=5&y=24", you can
use $Package::x + $Package::y. Again %CGI::Deurl::query works
as usual.

=item use CGI::Deurl NOTCGI;

Do not read any query. This option should be first or directly after the
&=....

=item use CGI::Deurl '&=.'

You may change the character used to separate the parameters. Use any
character or string you want. This must be the first option if present!

The parameter separator is stored in variable $CGI::Deurl::ParamSeparator.
You may change it any time you want.

=item use CGI::Deurl 'JOIN' => ';';

=item use CGI::Deurl 'JOIN' , 'file' => ';', '-all' => ',';

This option will cause a call to joinquery(), all folowing arguments
will be passed to this function, so this switch has to be the last one!

=back

=head2 Parsing query

If the argument in the query in in the form "name=value".
$CGI::Deurl::query{name} is set to value. If it is just "value"
(say myscript.pl?one&two), $CGI::Deurl::query{0}='one' and
$CGI::Deurl::query{1}='two'. These kinds of parameters can be intermixed.

If there is more than one occurence of a variable,
$CGI::Deurl::query{name} contains a refference to an array containing
all the values.

 Ex.
   ?x=one&y=two&x=three
  =>
   $CGI::Deurl::query{x}=['one','three'];
   $CGI::Deurl::query{y}='two';

!!! If you 'export' such a variable it's not exported as a refference
but as a real array!!!

 That is if you use CGI::Deurl qw(export CGI::Deurl) you will get :
    @CGI::Deurl::x = ('one','three');
    $CGI::Deurl::y = 'two';

! All changes made to $CGI::Deurl::variable are visible in
  $CGI::Deurl::query{variable} and vice versa.

=head2 Functions

=over 4

=item deurl

=item deurl $string, \%hash

Decodes the string as if it was an ordinary CGI query.
The %hash then contains all CGI parameters specified there.

 Ex.
   deurl('a=5&b=13',\%query);
  leads to :
   $query{a} = 5;
   $query{b} = 13;

=item deurlstr

=item $decodedstring = deurlstr $string

Decodes the string as if it was a CGI parameter value.
That is ist translates all '+' to ' ' and all
%xx to the corresponding character. It doesn't care about
'&' nor '='.

 Ex.
   $result = deurlstr 'How+are+you%3F';
  leads to:
   $result = 'How are you?'
  !!! but notice that !!!
   $result = deurlstr('a=5&b=13%25');
  gives:
   $result = 'a=5&b=13%'
  !!!!!!

=item deurlarr

=item @result = deurlarr $string;

Decodes the string as a sequence of unnamed CGI parameters,
that is it supposes that the $string looks somehow like this :
'param1&param2&par%61m3'. It doesn't care about '='

 Ex.
   @result = deurlarr 'How&are+you%3f';
  leads to
   @result = ( 'How', 'are you?');

   @result = deurlstr('a=5&b=13%25');
  gives:
   @result = ( 'a=5', 'b=13%');
  which may but may not be what you want.

=item CGI::Deurl::load

Instructs CGI::Deurl to load the CGI data from QUERY_STRING, @ARGV or <STDIN>.
The parameters are the same as for the C<use CGI::Deurl ...;>
Usefull only if you C<use CGI::Deurl NOTCGI;>, but later on you find out you want
the CGI parameters.

=item joinquery %query, $delimiter

=item joinquery %query, $key => $delimiter [, ...]

If the query contains several values for a singe variable, these values
are stored as an array in the hash. This function joins them using the delimiter
you specify. You may either join all the keys using the same delimiter, or use different
delimiters for each key. You may even leave some values intact.

 Ex.:
  joinquery %query, $delimiter
    it will join all multivalues it finds using the $delimiter.

  joinquery %query, 'key' => $delimiter
    it will join only the multivalue for 'key'. All other values will remain
    the same.

  joinquery %query, 'key' => ';', '-all' => ' '
    it will join the multivalue for 'key' by semicolons. All other values will
    be joined using spaces.

You may call this function from the "use" statement.

=item $CGI::Deurl::offline

If the script was called from the command line instead of as a CGI,
this variable contains 1. Otherwise it's undefined.

=back

=cut


package CGI::Deurl;
require Exporter;
@EXPORT=qw(deurl deurlstr deurlarr joinquery);
use vars qw'$VERSION $query $string';
$VERSION='1.08';

$ParamSeparator = '&' unless $ParamSeparator;

sub joinquery (\%@);

sub export {
 my $pkg=$_[0];
 $pkg.='::' if $pkg;
 my $key;
 foreach $key (keys %CGI::Deurl::query) {
  if (ref ${CGI::Deurl::query{$key}}) {
   *{$pkg.$key} = ${CGI::Deurl::query{$key}};
  } else {
   *{$pkg.$key} = \${CGI::Deurl::query{$key}};
  }
 }
}

sub as {
 my $name = $_[0];
 package main;
 *{$name} = *CGI::Deurl::query;
 package CGI::Deurl;
}

sub import {
 my $caller_pack = caller;
 my( $pkg )= shift;

 Exporter::export( $pkg, $caller_pack, qw(deurl deurlstr deurlarr joinquery));

 if (defined $_[0]) {
  if ($_[0] =~ /^&=(.+)$/) {shift; $ParamSeparator="\Q$1"}
  return if ($_[0] eq 'NOTCGI' or $_[0] eq 'NOCGI');
  if ($_[0] =~ /^&=(.+)$/) {shift; $ParamSeparator="\Q$1"}
 }

 &CGI::Deurl::load(@_);
}

sub load {
    my $data;
    if (defined $ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} eq "POST") {
     read STDIN , $data , $ENV{CONTENT_LENGTH} ,0;
     if ($ENV{QUERY_STRING}) {
      $data .= $ParamSeparator . $ENV{QUERY_STRING};
     }
    } elsif (defined $ENV{REQUEST_METHOD} and $ENV{REQUEST_METHOD} eq "GET") {
     $data=$ENV{QUERY_STRING};
    } elsif (defined $ENV{REQUEST_METHOD}) {
	 print "Status: 405 Method Not Allowed\r\n\r\n";
	 exit;
    } elsif ($#ARGV >= 0) {
     $CGI::Deurl::offline = 1;
     $data=join $ParamSeparator, @ARGV;
    } else {
     print STDERR "\t<ENTER THE CGI QUERY. End with CTRL+",$^O eq 'MSWin32' ? 'Z' : 'D',">\n";
     $CGI::Deurl::offline = 1;

     my @lines=<STDIN>;
     chomp @lines;
     $data=join $ParamSeparator, @lines;
    }

    return unless (defined $data and $data ne '');

    deurl($data,\%CGI::Deurl::query);
    my $i;
    for($i=0;$i<=$#_;$i++) {
     if (lc $_[$i] eq 'lc') {
      my (%hash,$key,$value);
      while (($key,$value) = each %CGI::Deurl::query) {
        $hash{lc $key} = $value;
      }
      %CGI::Deurl::query = %hash;
     } elsif (lc $_[$i] eq 'uc') {
      my (%hash,$key,$value);
      while (($key,$value) = each %CGI::Deurl::query) {
        $hash{uc $key} = $value;
      }
      %CGI::Deurl::query = %hash;
     } elsif (lc $_[$i] eq 'as') {
      $i++;
      CGI::Deurl::as $_[$i];
     } elsif (lc $_[$i] eq 'export') {
      CGI::Deurl::export($_[++$i]);
     } elsif ($_[$i] =~ /^join$/i) {
        if (ref $_[++$i] eq 'ARRAY') {
            joinquery(%CGI::Deurl::query, @{$_[$i]});
        } else {
            joinquery(%CGI::Deurl::query, $_[$i]);
        }
     } else {
      die "Unknown export directive $_[$i] in CGI::Deurl.pm!\n"
     }
    }
}

sub deurl ($$) {
    my ($data,$hash)=@_;
    die "deurl: ussage deurl($string, \%hash)\n" unless ($data and ref $hash eq 'HASH');
    $data=~s/\?$//;
    my $i=0;

    my @items = grep {!/^$/} (split /$ParamSeparator/o, $data);
    my $thing;

    foreach $thing (@items) {

     my @res = $thing=~/^(.*?)=(.*)$/;
     my ($name,$value,@value);

     if ($#res<=0) {
      $name = $i++;
      $value = $thing;
     } else {
      ($name,$value) = @res;
     }
     next unless $value ne '';

     $name=~tr/+/ /;
     $name =~ s/%(\w\w)/chr(hex $1)/ge;

     $value=~tr/+/ /;
     $value =~ s/%(\w\w)/chr(hex $1)/ge;

     if ($hash->{$name}) {
      if (ref $hash->{$name}) {
       push @{$hash->{$name}},$value;
      } else {
       $hash->{$name} = [ $hash->{$name}, $value];
      }
     } else {
      $hash->{$name} = $value;
     }

    }
    1;
}

sub deurlstr ($) {
    my $value=$_[0];
    $value=~tr/+/ /;
    $value =~ s/%(\w\w)/chr(hex $1)/ge;
    $value;
}

sub deurlarr ($) {
    my @value = split /$ParamSeparator/o, $_[0];
    foreach (@value) {
        tr/+/ /;
        s/%(\w\w)/chr(hex $1)/ge;
    }
    return @value;
}

sub joinquery (\%@) {
    my $query = shift;
#{
#local $"=", ";
#print "(@_)\n";
#}

    if (@_ == 1) {
        @_ = ('-all',$_[0]);
    }
    my %joins = @_;
    while (($key,$value) = each %$query) {
        if (ref $value eq 'ARRAY') {
            my $join;
            if ($join = $joins{$key} or $join = $joins{'-all'}) {
                $query->{$key} = join $join, @$value;
            }
        }
    }
}

1;
__END__

=head2 AUTHOR

Jenda@Krynicky.cz

=head2 COPYRIGHT

Copyright (c) 1997 Jan Krynicky <Jenda@Krynicky.cz>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
