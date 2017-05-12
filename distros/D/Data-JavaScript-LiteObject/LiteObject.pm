package Data::JavaScript::LiteObject;
use strict;
use vars qw($VERSION $JSVER);
$VERSION = '1.04';

sub import{
  no strict 'refs';
  shift;
  $JSVER = shift || 1.0;
  *{"@{[scalar caller()]}::jsodump"} = \&jsodump;
}

sub jsodump {
  my %opts = @_;
  my(@keys, $obj, @objs, $EOL, $EOI, @F);

  unless( $opts{protoName} && $opts{dataRef} ){
    return warn("// Both protoName and dataRef must be supplied");
  }

  ($EOI, $EOL) = $opts{explode} ? ("$/\t")x2 : ('', ' ');

  if( ref($opts{dataRef}) eq "ARRAY" ){
    my $i=0;
    $opts{dataRef} =  {map {$opts{protoName}.$i++=>$_} @{$opts{dataRef}} };
  }
  #NOT elsif
  if( ref($opts{dataRef}) eq "HASH" ){
    if( ref($opts{attributes}) eq "ARRAY" ){
      @keys = @{$opts{attributes}};
    }
    else{
      @keys = sort { $a cmp $b } keys
	%{$opts{dataRef}->{(sort keys %{$opts{dataRef}})[0]}};
    }
  }
  else{
    warn("// Unknown reference type, attributes"); return;
  }

  push @F, "function $opts{protoName} (", join(', ', @keys) ,") {$/\t";
  push @F, map("this.$_ = $_;$EOL", @keys);  
  push @F, "}$/";

  foreach $obj ( sort keys %{$opts{dataRef}} ){
    push @F, "$obj = new $opts{protoName}($EOI";
    push @F, join(",$EOL",
		  map(datum($opts{dataRef}->{$obj}->{$_}), @keys) ).$EOL;
    push @F, ");$/";
    push @objs, $obj;
  }

  if( defined($opts{listObjects}) ){
    push @F, "$opts{listObjects} = new Array($EOI",
      join(",$EOL", map("'$_'", @objs)), ");$/";
  }

  if( defined($opts{lineIN}) ){
    local $. = $opts{lineIN}+1;
    @F = split($/, join('', @F));
    foreach ( @F ) {
      $_ .= $/ . '// '. ++$. unless (++$.-$opts{lineIN}) %5;
      $_ .= $/;
    }
    ${$opts{lineOUT}} = $.;
    unshift @F, '// '. ($opts{lineIN}+1) .$/;
  }
  return @F;
}

sub datum {
  local $_ = shift() || '';
  my $val;

  if ( ref eq "ARRAY" ) {
    $val = $JSVER >= 1.2 ?
      "[" . join(',',
		 map /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ ?
		 $_ : do{ s/'/\\'/g; qq('$_') }, @{$_})
	. "]"
    :

      "new Array(" . join(',',
			  map /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ ?
			  $_ : do{ s/'/\\'/g; qq('$_') }, @{$_})
	. ")";

  }
  elsif( $val = $_, $val !~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ ){
    s/'/\\'/g;
    $val = qq('$_');
  }

  return $val;
}

1;
__END__

=pod

=head1 NAME

Data::JavaScript::LiteObject - lightweight data dumping to JavaScript

=head1 SYNOPSIS

    use Data::JavaScript:LiteObject;
    #OR
    use Data::JavaScript:LiteObject '1.2';

    %A = (protein      => 'bacon',
          condiments   => 'mayonaise',
          produce      => [qw(lettuce tomato)]);
    %B = (protein      => 'peanut butter',
          condiments   => 'jelly');
    @lunch             = (\%A, \%B);
    %lunch             = (BLT=>\%A, PBnJ=>\%B);

    jsodump(protoName  => "sandwich",
            dataRef    => \%lunch
            attributes => [qw(condiments protein produce)]);

=head1 DESCRIPTION

This module was inspired by L<Data::JavaScript>, which while incredibly
versatile, seems rather brute force and inelegant for certain forms
of data. Specifically a series of objects of the same class, which it
seems is a likely use for this kind of feature. So this module was
created to provide a lightweight means of producing configurable, clean
and compact output.

B<LiteObject> is used to format and output loh, hoh, lohol, and hohol.
The output is JavaScript 1.0 compatible, with the limitation that none
of the properties be a single-element array whose value is a number.
To lift this limitation pass use the extra value I<'1.2'>, which will
generate JavaScript 1.2 compatible output.

One function, B<jsodump>, is exported. B<jsodump> accepts a list of named
parameters; two of these are required and the rest are optional.

=head2 Required parameters

=over 4

=item C<protoName>

The name to be used for the prototype object function.

=item C<dataRef>

A reference to an array of hashes(loh) or hash of hashes(hoh) to dump.

=back

=head2 Optional parameters

=over 4

=item C<attributes>

A reference to an array containing a list of the object attributes
(hash keys). This is useful if every object is not guaranteed to
posses a value for each attribute.
It could also be used to exclude data from being dumped.

=item C<explode>

A scalar, if true output is one I<attribute> per line.
The default; false; is one I<object> per line.

=item C<lineIN>

A scalar, if true output is numbered every 5 lines. The value provided
should be the number of lines printed before this output.
For example if a CGI script included:

    print q(<html>
	    <head>
	    <title>Pthbb!!</title>
	    <script language=javascript>);>
    jsodump(protoName  => "sandwich",
            dataRef    => \@lunch,
            lineIN     => 4);

The client would see:

    <html>
    <head>
    <title>Pthbb!!</title>
    <script language=javascript>
    // 5
    function sandwich (condiment, produce, protein) {
            this.condiment = condiment; this.produce = produce; this.protein = protein; }
    BLT = new sandwich('mayonaise', new Array('lettuce','tomato'), 'bacon' );
    PBnJ = new sandwich('jelly', '', 'peanut butter' );
    // 10

making it easier to read and/or debug.

=item C<lineOUT>

A reference to a scalar. B<jsodump> will set the scalar's value to the number
of the last line of numbered output produced when lineIN is specified. Thus
you may pass the scalar to a subsequent call to B<jsodump> as the value of
lineIn for continuous numbering.
For example:

    jsodump(protoName  => "sandwich",
              dataRef  => \@lunch,
              lineIN   => 4,
              lineOUT  => \$.);
    jsodump(protoName  => "sandwich",
              dataRef  => \%lunch,
              lineIN   => $.);

=item C<listObjects>

A scalar, if true the parameters value is used as the name of an array to
be output which will contain a list of all the dumped object.
This allows data-ignorant client side code which need only
traverse the named array.

    jsodump(protoName  => "sandwich",
            dataRef    => \@lunch,
            listObjects=> "sandwiches");

would append the following to the output

    sandwiches = new Array('BLT', 'PBnJ');

=back

=head1 BUGS

Nothing that am I aware of.

=head1 SEE ALSO

L<Data::JavaScript>, L<Data::Dumper>

=head1 AUTHOR

Jerrad Pierce I<jpierce@cpan.org>, I<webmaster@pthbb.org>.
F<http://pthbb.org/>

=cut
