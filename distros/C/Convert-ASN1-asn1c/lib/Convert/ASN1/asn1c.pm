package Convert::ASN1::asn1c;

use Carp;
use strict;
use warnings;
use File::Slurp;
use IPC::Run qw(run pump start finish);

require Exporter;

=head1 NAME

Convert::ASN1::asn1c - A perl module to convert ASN1 to XML and back, using the
asn1c tools enber and unber.

=head1 SYNOPSIS

To use this module you need a xml template for the ASN1 PDU's you want to
encode/decode. For now we assume we have a file named "test-pdu.xml" in the
current working directory with the following content (read L</"DESCRIPTION"> for
information on how to create such a template):

	<C O="0" T="[1]" TL="2" V="12">
	    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$integer1</P>
	    <P O="5" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">$integer2</P>
	    <C O="9" T="[UNIVERSAL 16]" TL="2" V="3" A="SEQUENCE">
	        <P O="11" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">$enumerated1</P>
	    </C O="14" T="[UNIVERSAL 16]" A="SEQUENCE" L="5">
	</C O="14" T="[1]" L="14">

Now we can use this file together with Convert::ASN1::asn1c as shown:

	use Convert::ASN1::asn1c;
	
	my $pdu = "A1 0C 02 01 01 02 02 00 D3 30 03 0A 01 02";
	$pdu =~ s/ //g;
	$pdu = pack('H*', $pdu);

	# Now we have a binary ASN1 protocol data unit (PDU) in $pdu.
	# Typically you would read such data i.e., from a socket of course.

	my $conv = Convert::ASN1::asn1c->new();
	
	# Now let's decode this pdu, assuming it is a pdu which corresponds
	# to the test-pdu.xml file created earlier.

	my $values = $conv->decode("test-pdu.xml", $pdu);
	print $values->{'integer2'} . "\n";   # prints '211' for this example

	# Now let's change some values, use the same number of bytes to store this value as before
	$values->{'integer2'} = $conv->encode_integer(210, $values->{'integer2_length'});

	# and encode it into a binary ASN1 PDU again
	my $pdu_new = $conv->encode("test-pdu.xml", $values);

=head1 DESCRIPTION

Abstract Syntax Notation One (ASN1) is a protocol for data exchange by
applications, defined by the ITU-T. It works as follows: All parties agree on a
ASN1 specification for the Protocol Data Units (PDUs). Such a specification
might look like:

	AARQ-apdu ::= [APPLICATION 0] IMPLICIT SEQUENCE {
	    application-context-name        [1]     Application-context-name,
	    sender-acse-requirements        [10]    IMPLICIT ACSE-requirements          OPTIONAL,
	    calling-authentication-value    [12]    EXPLICIT Authentication-value       OPTIONAL,
	    user-information                [30]    IMPLICIT Association-information    OPTIONAL
	}

	Application-context-name ::= SEQUENCE { foo OBJECT IDENTIFIER }
	ACSE-requirements ::= BIT STRING
	Authentication-value ::= CHOICE { external [2] IMPLICIT PrivatExtPassword }
	PrivatExtPassword ::= [UNIVERSAL 8] IMPLICIT SEQUENCE { encoding EncodingPassword } 
	...

Now every party (that is aware of this specification) can take some data and
encode it (using standardized encoding rules) - Every other party will be able
to decode the information afterwards.

A module that does exactly this is Convert::ASN1. However, this approach has
a slight problem if you just want to receive a ASN1 encoded data unit, modify a
few values and send the modified PDU somewhere, for example during development,
testing or fuzzing of ASN1 processing entities: Sometimes you don't have the
ASN1 specification for that device.

In that case you can try to reverse engineer it, which is error prone and
tiresome. One tool that can assist you with that is the open source ASN1
compiler asn1c. It comes with two tools, unber and enber. The unber program
takes a binary pdu and tries to decode it to xml (without a matching ASN1
specification) just using the encoding information present in the binary ASN1
data. Due to the nature of BER-encoded (the most widely used encoding standard)
data, this is almost always possible. The only information that might get lost
is the description what kind of data we are dealing with, i.e., if we should
interpret the data with a hex value of 0x31 as an 1-byte integer or a 1-char
character string.

The enber tool can read the xml created by unber and convert it back into a
binary ASN1 pdu. Of course it is possible to edit the xml in between this
process to change some values. This is exactly what this module does.

Suppose you sniffed a data packet from somewhere (for example from a Siemens
HiPath PBX, from which you know it uses the CSTA protocol, which itself uses
ASN1 PDUs). You dumped the data in a file called pdu-siemens.bin for analysis.

    $ hexdump  pdu-siemens.bin
    0000000 0ca1 0102 0201 0002 30d3 0a03 0201     
    000000e

Now use the unber tool to decode this file: 

    $ unber -p pdu-siemens.bin
    <C O="0" T="[1]" TL="2" V="12">
	  <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x01;</P>
      <P O="5" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">&#x00;&#xd3;</P>
      <C O="9" T="[UNIVERSAL 16]" TL="2" V="3" A="SEQUENCE">
        <P O="11" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">&#x02;</P>
      </C O="14" T="[UNIVERSAL 16]" A="SEQUENCE" L="5">
   </C O="14" T="[1]" L="14">

The -p option instructs unber to generate xml that enber can understand. Now
let's assume we want to take control over the two integer values, maybe because
we want to change their values and see what happens or we want to examine their
values in similar PDUs. We create a template with the following content:

    <C O="0" T="[1]" TL="2" V="12">
	  <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$integer1</P>
      <P O="5" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">$integer2</P>
      <C O="9" T="[UNIVERSAL 16]" TL="2" V="3" A="SEQUENCE">
        <P O="11" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">&#x02;</P>
      </C O="14" T="[UNIVERSAL 16]" A="SEQUENCE" L="5">
   </C O="14" T="[1]" L="14">

And save it as "test-pdu.xml". Now we can use this module to read and create
simillar PDUs.

	use Convert::ASN1::asn1c;
	
	my $pdu = "A1 0C 02 01 01 02 02 00 D3 30 03 0A 01 02";
	$pdu =~ s/ //g;
	$pdu = pack('H*', $pdu);

	my $conv = Convert::ASN1::asn1c->new();
	my $values = $conv->decode("test-pdu.xml", $pdu);
	print $values->{'integer2'} . "\n";   # prints '211' for this example

	# Now let's change some values, use the same number of bytes to store this value as before
	$values->{'integer2'} = $conv->encode_integer(210, $values->{'integer2_length'});

	# and encode it into a binary ASN1 PDU again
	my $pdu_new = $conv->encode("test-pdu.xml", $values);

Of course this is a quick hack and not a real protocol implementation. But
quick hacks can be extremely usefull during protocol implementations. :-D 

=head2 EXPORT

None by default.

=cut



our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Convert::ASN1::asn1c ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';


# Preloaded methods go here.

=head1 METHODS

=head2 new()

Create a new ASN1 converter object

=cut

sub new {
	my ($class_name) = @_;

    my $self = {};
    bless ($self, $class_name);
	$self->{'_templatedir'} = '.';
	$self->{'_size_autocorrection'} = 1;
    return $self;
}

=head2 set_templatedir("./xmltemplates")

Set a directory where the xml templates for later encoding/decoding can be found

=cut

sub set_templatedir {
	my ($self, $dir) = @_;
	if (-d $dir) {
		$self->{'_templatedir'} = $dir;
		return 1;
	}
	else {
		carp "The directory $dir does not exists or is not a directory.\n";
		return undef;
	}
}

=head2 enable_sizecorr()

It is easily possible to produce invalid ASN1 packets with this module if you
specify incorrect sizes for the values in your template. If you turn on
automatic size correction with this function, such errors are automatically
corrected for you. Note that automatic size correction is turned on by default.

=cut

sub enable_sizecorr {
	my ($self, $dir) = @_;
	$self->{'_size_autocorrection'} = 1;
}

=head2 disable_sizecorr()

It is easily possible to produce invalid ASN1 packets with this module if you
specify incorrect sizes for the values in your template. If you turn off
automatic size correction with this function, such errors are NOT automatically
corrected for you. Note that automatic size correction is turned on by default.

=cut

sub disable_sizecorr {
	my ($self, $dir) = @_;
	$self->{'_size_autocorrection'} = 0;
}



=head2 $pdu = encode('pduname', {
                                  'value1'=>encode_integer(42, 1),
                                  'value2'=>encode_bitstring("10010")
                                }
                    );

The encode function takes the name of a template (the directory where to find
those templates can be modified with set_templatedir($dir)) and a reference to
a hash which's keys are names (the same that occur in the template) and values
with which these variables in the template should be substituted.

Note that these values have to be in xml format. To encode perl scalars into
the correct format you can use the encoding functions provided by this module.

The return value is the (binary) ASN1 PDU.

=cut

sub encode {

	my ($self, $pduname, $valueref) = @_;
	my %values = %{$valueref};

	# try to find the packet description
	my $text = read_file(File::Spec->catfile($self->{'_templatedir'}, $pduname));
	foreach (keys %values) {	
 		$text =~ s/\$$_(\W)/$values{$_}$1/g;
	}
	if ($text =~ m/(\$.+?)("|<| |>)/) {
		carp "Undefined variable ($1) in $pduname, your template contained that variable, but you didn't specify a value for it!\n";
	}

	if ($self->{'_size_autocorrection'}) {
		$text = correct_sizes($self, $text);
	}

	my $pdu;
	my @enber = qw( enber - );
	my $h = start \@enber, \$text, \$pdu;
	pump $h while length $text;
	finish $h or croak "enber returned $?";

	return $pdu;
}



=head2 $pdu = sencode($xmltemplate, {
                                  'value1'=>encode_integer(42, 1),
                                  'value2'=>encode_bitstring("10010")
                                }
                    );

The sencode function takes a template and a reference to a hash which's keys are
names (the same that occur in the template) and values with which these
variables in the template should be substituted.

It works the same way as the encode() function but it directly takes the xml
template as the first argument instead of a filename.

=cut

sub sencode {

	my ($self, $text, $valueref) = @_;
	my %values = %{$valueref};

	foreach (keys %values) {	
 		$text =~ s/\$$_(\W)/$values{$_}$1/g;
	}
	if ($text =~ m/(\$.+?)("|<| |>)/) {
		carp "Undefined variable ($1) in $text, your template contained that variable, but you didn't specify a value for it!\n";
	}

	if ($self->{'_size_autocorrection'}) {
		$text = correct_sizes($self, $text);
	}

	my $pdu;
	my @enber = qw( enber - );
	my $h = start \@enber, \$text, \$pdu;
	pump $h while length $text;
	finish $h or croak "enber returned $?";

	return $pdu;
}


sub correct_sizes {
	my ($self, $text) = @_;

	my @lines = split(/\n/, $text);
	
	my $current_offset = 0;
	my @stack;
	foreach (0 .. scalar(@lines)-1) {
		if ($lines[$_] =~ m/<P O="(\d+)" T="(.+?)" TL="(\d+)" V="(\d+)"(.*?)>(.*?)<\/P>/) {
			my $offset = $1;
			my $tag = $2;
			my $tag_length = $3;
			my $value_length = $4;
			my $rest = $5;
			my $value = $6;

			$offset = $current_offset;
			#count number of bytes in $value
			$value_length = () = $value =~ /&#x..;/g; 
			#replace this line with the corrected values
			$lines[$_] = "<P O=\"$offset\" T=\"$tag\" TL=\"$tag_length\" V=\"$value_length\"$rest)>$value</P>";
			$current_offset += $tag_length;
			$current_offset += $value_length;
		}
		if ($lines[$_] =~ m/<C O="(\d+)" T="(.+?)" TL="(\d+)" V="(\d+)"(.*?)>/) {
			my $offset = $1;
			my $tag = $2;
			my $tag_length = $3;
			my $value_length = $4;
			my $rest = $5;
			$offset = $current_offset;
			#replace this line with the corrected values
			$lines[$_] = "<C O=\"$offset\" T=\"$tag\" TL=\"$tag_length\" V=\"$value_length\"$rest)>";
			$current_offset += $tag_length;
			# put this line number on the stack, so that we can jump back here and fill in the value length once we know it
			push @stack, $_;
		}
		if ($lines[$_] =~ m/<\/C O=\"(\d+)\" T=\"(.+?)\"(.+?)L=\"(\d+)\">/) {
			my $offset = $1;
			my $tag = $2;
			my $rest = $3;
			my $length = $4;
			$offset = $current_offset;

			my $opening_line = pop @stack;
			if ($lines[$opening_line] =~ m/<C O="(\d+)" T="(.+?)" TL="(\d+)" V="(\d+)"(.*?)>/) {
				my $op_offset = $1;
				my $op_tag = $2;
				my $op_tag_length = $3;
				my $op_value_length = $4;
				my $op_rest = $5;
				$op_value_length = $current_offset - $op_offset - $op_tag_length;
				$length =  $current_offset - $op_offset;
				$lines[$opening_line] = "<C O=\"$op_offset\" T=\"$op_tag\" TL=\"$op_tag_length\" V=\"$op_value_length\"$op_rest)>";
			}
			else {
				die "Internal error, file bug report!\n";
			}

			#replace this line with the corrected values
			$lines[$_] = "</C O=\"$current_offset\" T=\"$tag\"$rest L=\"$length\">";
		}
	}

	$text = join("\n", @lines);

	return $text;
}



=head2 $values = decode('pduname', $pdu);

The decode function takes the name of a template (the directory where to find
those templates can be modified with set_templatedir($dir)) and a binary pdu.

It will match the variables in the template against the decoded binary pdu and
return a reference to a hash which contains these values.

For each variable $myvalue the hash will contain four keys:

=head3 $values->{'myvalue'}

The decoded value if we could "guess" myvalues type because it was
specified as i.e. INTEGER or BIT STRING in the asn1 pdu.

=head3 $values->{'myvalue_orig'}

The original value as it was found in the unber -p output. Note that these
values are still xml-encoded. To decode them you can use this modules
decode_-functions or write your own decoders if the provided ones are not
sufficient.

=head3 $values->{'myvalue_length'}

The length of $myvalue as it was encoded in the asn1 pdu. This value is
needed for some _decode routines and can also be usefull if you write your own
decoder functions.

=head3 $values->{'myvalue_type'} 

If the type of $myvalue is specified in the pdu, for example as INTEGER, this
key contains the value.

=cut



sub decode {

	my ($self, $pduname, $pdu) = @_;

	my @stack;
	my @varpos;

	# try to find the packet description
	my @lines = read_file(File::Spec->catfile($self->{'_templatedir'}, $pduname));

	# we will parse the packet description
	# to find out which "nodes" in the tag tree are interesting for us
	# and we will construct a list of those interesting nodes (and how to "reach" them,
	# i.e. which parent nodes they are located under. In the second step we will
	# iterate over the decoded ASN data, if we are in an inetersting leaf we will decode it's value.
	
	foreach (@lines) {
		if (m/<C .*?T=\"(.*?)\"/) { push @stack, $1; }
		if (m/<\/C /) { pop @stack; }
		if (m/<P .*?T=\"(.*?)\"/) { push @stack, $1; }
		while (m/(\$.+?)("|<| |>)/gc) {
			my $varname = $1;
			if ($varname !~ m/_length$/) {
				push(@varpos, $varname . ":" . join('|', @stack));
			}
		}
		if (m/<\/P>/) { pop @stack; }
	}

	my @unber = qw( unber -p - );
	my $text;
	my $h = start \@unber, \$pdu, \$text;
	pump $h while length $pdu;
	finish $h or croak "unber returned $?";

	@lines = qw();
	@stack = qw();
	@lines = split(/\n/, $text);
	my %results;

	foreach (@lines) {
		my $line = $_;
		if ($line =~ m/<C .*?T=\"(.*?)\"/) {
			push @stack, $1;
		}
		if ($line =~ m/<\/C /) {
			pop @stack;
		}
		if ($line =~ m/<P .*?T=\"(.*?)\"/) {
			#check if this node is "interesting" - is there a entry in @varpos which matches the current stack
			push @stack, $1;
			my $current = join('|', @stack);
			foreach (0 .. scalar(@varpos)-1) {
				croak "Internal Parser error!\n" unless ($varpos[$_] =~ m/^\$(.*?):(.*?)$/);
				my $varname = $1;
				my $varposition = $2;
				if ($varposition eq $current) {
					# we are in an interesting node! 
					my $value = undef;
					my $value_len = undef;
					my $value_type = undef;
					if ($line =~ m/ V=\"(.*?)\".*?>(.*?)</) {
						$value_len = $1;
						$value = $2;
						if ($line =~ m/A=\"(.*?)\"/) {	$value_type = $1; }
						else { $value_type = 'UNDEFINED';  }
						$results{$varname . '_length'} = $value_len;
						$results{$varname . '_type'} = $value_type;
						$results{$varname} = $value;
						$results{$varname . '_orig'} = $value;
						# remove the filled varpos entry
						$varpos[$_] .= '--matched--';
						last;
					}
				}
			}
			pop @stack;
		}
	}
	
	# now we have all interesting values in the results hash, together with
	# their type (BE CAREFULL - "Siemens Bitstrings" have the type UNDEFINED)
	# and length.

	foreach (keys %results) {
		my $key = $_;
		if ($key !~ m/(_length$|_type$|_orig$)/) {
			my $value = $results{$key};
			my $type = $results{$key . '_type'};
			my $length = $results{$key . '_length'};
			if ($type eq 'OCTET STRING') {
				$results{$key} = decode_octet_string($self, $value, $length);
			}
			if ($type eq 'INTEGER') {
				$results{$key} = decode_integer($self, $value, $length);
			}
			if ($type =~ m/(BIT STRING)/) {
				$results{$key} = decode_bitstring($self, $value, $length);
			}
			if ($type eq "GeneralizedTime") {
				$results{$key} = decode_timestamp($self, $value, $length);
			}
			if ($type eq "ENUMERATED") {
				# of course not all enumerated types are int's but
				# in our context it seems to be a good guess
				$results{$key} = decode_integer($self, $value, $length);
			}
		}
	}

	return \%results;
}

=head2 $values = sdecode($xml_template, $pdu);

The sdecode function takes a template and a binary pdu. It works the same way
as the decode function, but it directly takes the template as it's first
argument instead of a filename.

=cut



sub sdecode {

	my ($self, $xml_template, $pdu) = @_;

	my @stack;
	my @varpos;

	# try to find the packet description
	my @lines = split(/\n/, $xml_template);

	# we will parse the packet description
	# to find out which "nodes" in the tag tree are interesting for us
	# and we will construct a list of those interesting nodes (and how to "reach" them,
	# i.e. which parent nodes they are located under. In the second step we will
	# iterate over the decoded ASN data, if we are in an inetersting leaf we will decode it's value.
	
	foreach (@lines) {
		if (m/<C .*?T=\"(.*?)\"/) { push @stack, $1; }
		if (m/<\/C /) { pop @stack; }
		if (m/<P .*?T=\"(.*?)\"/) { push @stack, $1; }
		while (m/(\$.+?)("|<| |>)/gc) {
			my $varname = $1;
			if ($varname !~ m/_length$/) {
				push(@varpos, $varname . ":" . join('|', @stack));
			}
		}
		if (m/<\/P>/) { pop @stack; }
	}

	my @unber = qw( unber -p - );
	my $text;
	my $h = start \@unber, \$pdu, \$text;
	pump $h while length $pdu;
	finish $h or croak "unber returned $?";

	@lines = qw();
	@stack = qw();
	@lines = split(/\n/, $text);
	my %results;

	foreach (@lines) {
		my $line = $_;
		if ($line =~ m/<C .*?T=\"(.*?)\"/) {
			push @stack, $1;
		}
		if ($line =~ m/<\/C /) {
			pop @stack;
		}
		if ($line =~ m/<P .*?T=\"(.*?)\"/) {
			#check if this node is "interesting" - is there a entry in @varpos which matches the current stack
			push @stack, $1;
			my $current = join('|', @stack);
			foreach (0 .. scalar(@varpos)-1) {
				croak "Internal Parser error!\n" unless ($varpos[$_] =~ m/^\$(.*?):(.*?)$/);
				my $varname = $1;
				my $varposition = $2;
				if ($varposition eq $current) {
					# we are in an interesting node! 
					my $value = undef;
					my $value_len = undef;
					my $value_type = undef;
					if ($line =~ m/ V=\"(.*?)\".*?>(.*?)</) {
						$value_len = $1;
						$value = $2;
						if ($line =~ m/A=\"(.*?)\"/) {	$value_type = $1; }
						else { $value_type = 'UNDEFINED';  }
						$results{$varname . '_length'} = $value_len;
						$results{$varname . '_type'} = $value_type;
						$results{$varname} = $value;
						$results{$varname . '_orig'} = $value;
						# remove the filled varpos entry
						$varpos[$_] .= '--matched--';
						last;
					}
				}
			}
			pop @stack;
		}
	}
	
	# now we have all interesting values in the results hash, together with
	# their type (BE CAREFULL - "Siemens Bitstrings" have the type UNDEFINED)
	# and length.

	foreach (keys %results) {
		my $key = $_;
		if ($key !~ m/(_length$|_type$|_orig$)/) {
			my $value = $results{$key};
			my $type = $results{$key . '_type'};
			my $length = $results{$key . '_length'};
			if ($type eq 'OCTET STRING') {
				$results{$key} = decode_octet_string($self, $value, $length);
			}
			if ($type eq 'INTEGER') {
				$results{$key} = decode_integer($self, $value, $length);
			}
			if ($type =~ m/(BIT STRING)/) {
				$results{$key} = decode_bitstring($self, $value, $length);
			}
			if ($type eq "GeneralizedTime") {
				$results{$key} = decode_timestamp($self, $value, $length);
			}
			if ($type eq "ENUMERATED") {
				# of course not all enumerated types are int's but
				# in our context it seems to be a good guess
				$results{$key} = decode_integer($self, $value, $length);
			}
		}
	}

	return \%results;
}

=head2 $tagpths = get_tagpaths_with_prefix($pdu, $prefix);

A ASN1 PDU is contains constructed and primitive datatypes. Constructed
datatypes can contain other constructed or primitive datatypes. Each datatype
(constructed or primitive) is identified by a tag.

This function decodes the pdu and constructs "tag paths": If a constructed
datatype with tag "foo" contains a constructed datatype "bar" and a primitive
datatype "moo". The constructed datatype "bar" contains a primitive datatype
"frob", we have the following xml structure:  

    <C ... T="foo">
        <C ... T="bar">
            <P ... T="frob"> ... </P>
        </C ... T="bar">
        <P ... T="moo"> ... </P>
    </C ... T="foo">

In that case we have the following "tag paths": C<foo>, C<foo|bar>,
C<foo|bar|frob>, C<foo|moo>. This function returns all tag paths that match the
given prefix. In the returned tag paths (as well as in the prefix) single tags
have to be concatenated by the pipe character '|'.

Note that this function doesn't require a name or a xml template for a PDU.
It's primary usage is to decide which template should be used to extract values
from a PDU.

The result is returned as a reference to an array which contains the matching
tag paths.

=cut

sub get_tagpaths_with_prefix {

	my ($self, $pdu, $prefix) = @_;

	my @unber = qw( unber -p - );
	my $text;
	my $h = start \@unber, \$pdu, \$text;
	pump $h while length $pdu;
	finish $h or croak "unber returned $?";

	my @stack = qw();
	my @results = qw();
	my @lines = split(/\n/, $text);
	$prefix = quotemeta($prefix);

	foreach (@lines) {
		my $line = $_;
		if ($line =~ m/<C .*?T=\"(.*?)\"/) {
			push @stack, $1;
			my $current = join('|', @stack);
			if ($current =~ m/^ $prefix/x) {
				push @results, $current;
			}
		}
		if ($line =~ m/<\/C /) {
			pop @stack;
		}
		if ($line =~ m/<P .*?T=\"(.*?)\"/) {
			push @stack, $1;
			my $current = join('|', @stack);
			if ($current =~ m/^$prefix/) {
				push @results, $current;
			}
			pop @stack;
		}
	}

	return \@results;

}


=head2 Encoding Functions

=head3 $xml = encode_bitstring("1010100")

Takes a string which contains 0's and 1's and encodes this binary string into
xml understandable by enber(1).

=cut

sub encode_bitstring {

	# we get a string like "101" and convert it to
	# number of unused bits + hex value of binary string

	my ($self, $bits) = @_;
	$bits =~ s/ //g;
	
	# calculate how many unused bits will be in the bitstring
	my $len = length($bits); 
	$len = $len % 8;
	$len = 8 - $len;
	if ($len == 8) {
		$len = 0;
	}

	# append zeroes until we have a number of bits devideable by eight
	$bits .= '0' x $len;
	#convert bits to hex
	my $hex = unpack('H*', pack('B*', $bits));
	#prepend every byte with "&#x" for xml conversion
	$hex =~ s/(..)/&#x$1;/g;

	my $text = '&#x0'.$len.';'.$hex;
	return $text;
}


=head3 $xml = encode_octet_string("foo")

Takes a perl string and encodes it as an ASN1 "OCTET STRING" in the xml format
understandable by enber(1).

=cut

sub encode_octet_string {
	# we get a string like "foo" and convert it in it's hex notation
	my ($self, $string) = @_;

	my $hex = unpack('H*', $string);
	#prepend every byte with "&#x" for xml conversion
	$hex =~ s/(..)/&#x$1;/g;
	return $hex;
}

=head3 $xml = encode_hextxt2xml("DEADBEEF")

Takes a perl string which containts the characters [0-9] and [A-F] or [a-f],
interprets this string as a hexadecimal value and encodes it in the xml format
understandable by enber(1).

=cut

sub encode_hextxt2xml {

	my ($self, $value) = @_;

	$value =~ s/(..)/&#x$1;/g;
	return $value;
}

=head3 $xml = encode_integer(42, 4)

Takes a integer and a size and encodes the integer in the xml format
understandable by enber(1). The size specifies how many bytes should be used to
encode the integer in ASN1.

=cut

sub encode_integer {
	
	my ($self, $value, $length) = @_;

	$value = pack('N', $value);
	$value = unpack('H*', $value);
	$value = substr($value, (4-$length)*2, length($value));
	#prepend every byte with "&#x" for xml conversion
	$value =~ s/(..)/&#x$1;/g;
	return $value;
}


=head2 Decoding Functions

=head3 $bitstr = decode_bitstring($vals->{'myvalue_orig'})

Takes a ASN1 BIT STRING value in the format returned by unber(1) or this
modules decode function and converts it into a perl string such as "101001".

=cut

sub decode_bitstring {

	my ($self, $value) = @_;

	my $orig = $value;
	# first byte: number of unused bits (must be smaller than 8)
	$value =~ s/(&|#|x|;)//g;
	$value =~ s/^.(.)//;
	my $unused_bits = $1;
	$value = pack('H*', $value);
	$value = unpack('B*', $value);
	# remove unused bits
	if ($unused_bits > 0) {
		$value = substr($value, 0, -$unused_bits);
	}
	return $value;
}

=head3 $time = decode_timestamp($vals->{'myvalue_orig'})

Takes a ASN1 value of the type GeneralizedTimestamp in the format returned by
unber(1) or this modules decode function and converts it into a perl string
such as "2010-09-25 11:35:10" (year-month-day hour:minute:seconds).

=cut

sub decode_timestamp {
	my ($self, $value) = @_;
	$value =~ s/(&|#|x|;)//g;
	$value = pack('H*', $value);
	if ($value =~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/) {
		return "$1-$2-$3 $4:$5:$6"
	}
}

=head3 $val = decode_octet_string($vals->{'myvalue_orig'})

Takes a ASN1 value of the type OCTET STRING in the format returned by unber(1)
or this modules decode function and converts it into a perl scalar.

=cut


sub decode_octet_string {
	my ($self, $value) = @_;
	$value =~ s/(&|#|x|;)//g;
	$value = pack('H*', $value);
	return $value;
}

=head3 $int = decode_integer($vals->{'myvalue_orig'}, $vals->{'myvalue_length'})

Takes a ASN1 value of the type INTEGER in the format returned by unber(1)
or this modules decode function and converts it into a perl scalar.

=cut

sub decode_integer {

	my ($self, $value, $length) = @_;
	
	$value =~ s/(&|#|x|;)//g;
	$value = '00'x(4-$length) . $value;
	$value = pack('H*', $value);
	$value = unpack("N", $value);
	return $value;
}

=head3 $hex = decode_xml2hextxt($vals->{'myvalue_orig'});

Takes any value in the format returned by unber(1) or this modules decode
function and converts it into a string which consists of this values hex
representation. This is usefull for opaque objects like identifiers, where you
don't really know what they mean but still want to display and compare them.

=cut

sub decode_xml2hextxt {

	my ($self, $value) = @_;

	$value =~ s/(&|#|x|;)//g;
	return $value;
}


1;

__END__

=head1 SEE ALSO

ASN1 is specified in ITU-T publications X.680 - X.690, freely accessible at
L<http://www.itu.int/rec/T-REC-X/e>.

The open source ASN1 compiler asn1c can be downloaded from
L<http://lionet.info/asn1c/>, it includes the man pages for unber(1) and enber(1).

=head1 AUTHOR

Timo Schneider, E<lt>timos@informatik.tu-chemnitz.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Timo Schneider

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
