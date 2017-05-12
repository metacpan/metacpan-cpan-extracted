package Data::Taxi;
use strict;
use vars qw[@ISA $VERSION $FORMAT_VERSION %HANDLE_FORMATS @EXPORT_OK %EXPORT_TAGS];
use Carp 'croak';
use Exporter;
use Debug::ShowStuff ':all';
@ISA = 'Exporter';
use 5.006;


=head1 NAME

Data::Taxi - Taint-aware, XML-ish data serialization

PLEASE NOTE: Data::Taxi is no longer being developed or supported.

=head1 SYNOPSIS

  use Data::Taxi ':all';
  my ($ob, $str);
  
  $ob = MyClass->new();
  $str = freeze($ob);
  $ob = thaw($str);



=head1 INSTALLATION

Data::Taxi can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

You can also just copy Taxi.pm into the Data/ directory of one of your library trees.


=head1 DESCRIPTION

Taxi (B<T>aint-B<A>ware B<X>ML-B<I>sh) is a data serializer with several handy features:

=over

=item Taint aware

Taxi does not force you to trust the data you are serializing.
None of the input data is executed.

=item Human readable

Taxi produces a human-readable string that simplifies checking the
output of your objects.

=item XML-ish

While I don't (currently) promise full XML compliance, Taxi produces a block
of XML-ish data that could probably be read in by other XML parsers.

=back


=cut

#------------------------------------------------------------------------
# import/export
#

=head1 EXPORT

None by default.  freeze and thaw with ':all':

   use Data::Taxi ':all';

=cut

@EXPORT_OK = qw[freeze thaw];
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# import/export
#------------------------------------------------------------------------


# version
$VERSION = '0.96';
$FORMAT_VERSION = '1.00';
undef $HANDLE_FORMATS{$FORMAT_VERSION};


# constants
use constant HASHREF  => 1;
use constant ARRREF   => 2;
use constant SCAREF   => 3;
use constant SCALAR   => 4;


=head1 Subroutines

=cut




#-----------------------------------------------------------------------------------
# freeze
# 

=head2 freeze($ob, %opts)

C<freeze> serializes a single scalar, hash reference, array reference, or
scalar reference into an XML string, C<freeze> can recurse any number of 
levels of a nested tree and preserve multiple references to the same object. 
Let's look at an example:

	my ($tree, $format, $members, $bool, $mysca);
	
	# anonymous hash
	$format = {
		'app'=>'trini',
		'ver'=>'0.9',
		'ver'=>'this &amp; that',
	};
	
	# anonymous array
	$members = ['Starflower', 'Mary', 'Paul', 'Hallie', 'Ryan'];
	
	# blessed object
	$bool = Math::BooleanEval->new('whatever');
	
	# scalar reference (to an anonymous hash, no less)
	$mysca = {'name'=>'miko', 'email'=>'miko@idocs.com', };
	
	# the whole thing
	$tree = {
		'dataformat' => $format,
		'otherdataformat' => $format,
		'bool' => $bool,
		'members' => $members,
		'myscaref' => \$mysca,
	};
	
	$frozen = freeze($tree);

C<freeze> accepts one object as input.  The code above results in the following
XML-ish string:

   <taxi ver="1.00">
      <hashref id="0">
         <hashref name="otherdataformat" id="1">
            <scalar name="ver" value="this &#38;amp; that"/>
            <scalar name="app" value="trini"/>
         </hashref>
         <scalarref name="myscaref" id="2">
            <hashref id="3">
               <scalar name="email" value="miko@idocs.com"/>
               <scalar name="name" value="miko"/>
            </hashref>
         </scalarref>
         <hashref name="bool" id="4" class="Math::BooleanEval">
            <hashref name="blanks" id="5">
            </hashref>
            <scalar name="pos" value="0"/>
            <arrayref name="arr" id="6">
               <scalar value="whatever"/>
            </arrayref>
            <scalar name="expr" value="whatever"/>
         </hashref>
         <hashref name="dataformat" id="1" redundant="1"/>
         <arrayref name="members" id="7">
            <scalar value="Starflower"/>
            <scalar value="Mary"/>
            <scalar value="Paul"/>
            <scalar value="Hallie"/>
            <scalar value="Ryan"/>
         </arrayref>
      </hashref>
   </taxi>


=cut

# Golly, and after all that POD, the subroutine is only a few lines
# long. All the work is done in obtag(), which recurses through the
# data to build the data string.

sub freeze {
	my ($ob, %opts) = @_;
	my $rv = '';
	
	# if a declaration is wanted
	if (
		$opts{'declaration'} ||
		(! defined $opts{'declaration'})
		) {
		$rv .= qq|<?xml version="1.0"?>\n|;
	}
	
	$rv .=
		'<taxi ver="' . $Data::Taxi::FORMAT_VERSION . "\">\n" .
		join('',  obtag($ob, {}, 1, %opts)) .
		"</taxi>\n";
	
	return $rv;
}
#
# freeze
#-----------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------
# obtag
#
# Private subroutine: recurses through data structure building the data string.
#
sub obtag {
	my ($ob, $ids, $depth, %opts) = @_;
	my (@rv, $indent, $allowed);
	
	# hash of allowed fields to save
	$allowed = get_allowed(\%opts);
	
	
	# get tied class
	if (defined $opts{'tied'})
		{$opts{'tied'} =~ s|\=.*||}
	
	# build the indentation string for this recursion.
	$indent = "\t" x $depth;
	
	# if reference
	if (my $ref = ref($ob)) {
		my $tagname = "$ob";
		my $org = $tagname;
		my ($tie);
		
		$tagname =~ s|^[^\=]*\=||;
		$tagname =~ s|\(.*||;
		$tagname = lc($tagname) . 'ref';
		
		# open tag
		push @rv, $indent, '<', $tagname;
		
		if (defined $opts{'name'} )
			{push @rv, ' name="', mlesc( $opts{'name'} ), '"'}
		
		# if in $ids
		if ($ids->{$ob})
			{return @rv, ' id="', $ids->{$ob}, '" redundant="1"/>', "\n"}
		
		# store object in objects hash
		# $ids->{$ob} = 1;
		$ids->{$ob} = keys(%{$ids});
		
		
		# output ID
		# push @rv, ' id="', mlesc($ob), '"';
		push @rv, ' id="', $ids->{$ob}, '"';
		
		# class
		if ($ref !~ m/^(HASH|ARRAY|REF|SCALAR)$/)
			{push @rv, ' class="', mlesc($ref), '"'}
		
		# tied hash
		if ($ref eq 'HASH') {
			if (my $tie = tied(%{$ob}) ) {
				$tie =~ s|\=.*||;
				push @rv, ' tied="', mlesc($tie), '"';
			}
		}
		
		# tied array
		elsif ($ref eq 'ARRAY') {
			if (my $tie = tied(@{$ob}) ) {
				$tie =~ s|\=.*||;
				push @rv, ' tied="', mlesc($tie), '"';
			}
		}
		
		# close tag
		push @rv, ">\n";
		
		# output children: hashref
		if ($tagname eq 'hashref') {
			HASHLOOP:
			foreach my $k (keys %{$ob} ){
				# if not allowed
				if ($allowed && (! exists $allowed->{$k}) )
					{next HASHLOOP}
				
				push @rv, obtag($ob->{$k}, $ids, $depth + 1, 'name'=>$k, 'tied'=>tied($ob->{$k}));
			}
		}
		
		# output children: arrayref
		elsif ($tagname eq 'arrayref') {
			foreach my $v ( @{$ob} )
				{push @rv, obtag($v, $ids, $depth + 1)}
		}
		
		# output children: scalarref
		elsif ($tagname eq 'scalarref')
			{ push @rv, obtag(${$ob}, $ids, $depth + 1, 'tied'=>tied(${$ob})   ) }
		
		# else don't know this type of reference
		else
			{ croak "don't know this type of reference: $tagname" }
		
		# close tag
		push @rv, $indent, '</', $tagname, ">\n";
	}
	
	# else output tag with self-ender
	else {
		push @rv, $indent, '<scalar';
		
		if (defined $opts{'name'} )
			{push @rv, ' name="', mlesc( $opts{'name'} ), '"'}

		if (defined $opts{'tied'} )
			{push @rv, ' tied="', mlesc( $opts{'tied'} ), '"'}

		if (defined $ob)
			{push @rv, ' value="', mlesc($ob), '"'}

		push @rv, "/>\n";
	}

	return @rv;
}
# 
# obtag
#-----------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# thaw data
#

=head2  thaw

C<thaw> accepts one argument, the serialized data string, and returns a single
value, the reconstituted data, rebuilding the entire data structure including
blessed references.

   $tree = thaw($frozen);

=cut

sub thaw {
	my ($raw) = @_;
	my (@els, @stack, %ids, %esc, $quote, $left, $right, $amp, $firstdone);
	
	# remove XML document header, we're not s'fisticaded 'nuff for that
	# kinda thang yet. XML gurus will wince at this code. 
	if ($raw =~ s|^\<\?||)
		{$raw =~ s|^[^\>]*>||}
	
	
	#-------------------------------------------------------------
	# placeholders for un-escaping
	#
	# I'm sure this could be done more gracefully.  Feel free to
	# to tidy up the unescaping routine and submit back your code.
	# :-) Miko
	#
	while (keys(%esc) < 4) {
		my $str = rand;
		$str =~ s|^0\.||;
		
		unless ($raw =~ m|$str|)
			{undef $esc{$str}}
	}
	
	($quote, $left, $right, $amp) = keys(%esc);
	
	$raw =~ s|&#34;|$quote|g;
	$raw =~ s|&#60;|$left|g;
	$raw =~ s|&#62;|$right|g;
	$raw =~ s|&#38;|$amp|g;
	#
	# placeholders for un-escaping
	#-------------------------------------------------------------
	
	
	# split into tags
	$raw =~ s|^\s*\<||;
	$raw =~ s|\s*\>$||;
	@els = split(m|\>\s*\<|, $raw);
	undef $raw; # don't need this anymore, might as well clean up now
	
	# loop through tags
	TAGLOOP:
	foreach my $el (@els) {
		# if end tag
		if ($el =~ m|^/|) {
			# if stack is down to 1 element, we're done
			(@stack == 1) && return $stack[0]->[0];
			
			pop @stack;
			next TAGLOOP;
		}
		
		# variables
		my ($type, $new, $selfender, %atts, $ref, $tagname);
		
		# self-ender?
		$selfender = $el =~ s|\s*\/$||s;
		
		# get tagname
		$el =~ s|^\s*||;
		$el =~ s|\s*$||;
		$el =~ s|^([^\s\"]+)\s*||s
			or die "invalid tag: $el";
		$tagname = lc($1) . ($el x 0);
		
		
		#-------------------------------------------------------------
		# parse into hash
		#
		$el =~ s|(\S+)\s*\=\s*"([^"]*)"\s*|\L$1\E\<$2\<|g;
		
		%atts = grep {
			s|$quote|"|g;
			s|$left|<|g;
			s|$right|>|g;
			s|$amp|&|g;
			1;
			} split('<', $el);
		#
		# parse into hash
		#-------------------------------------------------------------
		
		
		#-------------------------------------------------------------
		# hashrefs
		#
		if ($tagname eq 'hashref') {
			$type = HASHREF;
			
			# if tied
			if (defined $atts{'tied'}) {
				my %hash;
				tie %hash, $atts{'tied'};
				$new = \%hash;
			}
			
			# else not tied
			else
				{$new = {}}
			
			$ref = 1;
		}
		#
		# hashrefs
		#-------------------------------------------------------------
		
		
		#-------------------------------------------------------------
		# array refs
		#
		elsif ($tagname eq 'arrayref') {
			$type = ARRREF;
			
			# if tied
			if (defined $atts{'tied'}) {
				my @arr;
				tie @arr, $atts{'tied'};
				$new = \@arr;
			}
			
			# else not tied
			else
				{$new = []}
			
			$ref = 1;
		}
		#
		# array refs
		#-------------------------------------------------------------
		
		
		#-------------------------------------------------------------
		# scalarref
		#
		elsif ($tagname eq 'scalarref') {
			$type = SCAREF;
			$ref = 1;
		}
		#
		# scalarref
		#-------------------------------------------------------------
		
		
		#-------------------------------------------------------------
		# scalar
		#
		elsif ($tagname eq 'scalar') {
			$type = SCALAR;
		}
		#
		# scalar
		#-------------------------------------------------------------
		
		
		#-------------------------------------------------------------
		# taxi
		#
		elsif ( (! $firstdone) && ($tagname eq 'taxi') ) {
			# do nothing
		}
		#
		# taxi
		#-------------------------------------------------------------
		
		
		# else I don't know this tag
		else
			{croak "do not understand tag: $tagname $el"}
		
		# if first tag
		if (! $firstdone) {
			# version check
			unless (exists $Data::Taxi::HANDLE_FORMATS{$atts{'ver'}})
				{croak "Do not know this format version: $atts{'ver'}"}
			
			$firstdone = 1;
			next TAGLOOP;
		}
		
		# if ID, and ID already exists, that's the new object
		if (  defined($atts{'id'})  &&  $ids{$atts{'id'}}   )
			{$new = $ids{$atts{'id'}} }
		
		# if blessed reference
		elsif (defined $atts{'class'})
			{bless $new, $atts{'class'}}
		
		# if scalar
		elsif ($type == SCALAR)
			{$new = $atts{'value'}}
		
		# if scalar reference
		elsif ($type == SCAREF) {
			my $val;
			$new = \$val;
		}
		
		# if reference
		if ($ref)
			{$ids{$atts{'id'}} = $new}
		
		if ( @stack ) {
			# get prev and prevtype
			my($prev, $prevtype) = @{$stack[$#stack]};
			
			# if prevtype is array, push into prev
			if ($prevtype == HASHREF) {
				

				$prev->{$atts{'name'}} = $new;
			}
			
			# if prevtype is array, push into prev
			elsif ($prevtype == ARRREF)
				{push @{$prev}, $new}
			
			# else set scalar reference
			else
				{$prev = \$new}
		}

		# if this is a selfender
		elsif ($selfender)
			{return $new}
		
		# if ! self ender and current is hash or arr
		if (  (! $selfender)  &&  ( ($type == HASHREF) || ($type == ARRREF) || ($type == SCAREF) )  )
			{push @stack, [$new, $type]}
	}
	
	# if we get this far, that's an error
	die 'invalid FreezDry data format';
}
#
# thaw data
#------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------
# mlesc
# Private sub. Escapes &, <, >, and " so that they don't mess up my parser.
#
sub mlesc {
        my ($rv) = @_;
        return '' unless defined($rv);
        $rv =~ s|&|&#38;|g;
        $rv =~ s|"|&#34;|g;
        $rv =~ s|<|&#60;|g;
        $rv =~ s|>|&#62;|g;
        return $rv;
}
# 
# mlesc
#-----------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------
# get_allowed
# 
# Private sub. Returns a hash ref of allowed fields if such an options was sent.
# 
sub get_allowed {
        my ($opts) = @_;
		exists($opts->{'allowed'}) or return undef;
		
		my ($rv, %alluse);
		ref($opts->{'allowed'}) or $opts->{'allowed'} = [$opts->{'allowed'}];
		
		@alluse{@{$opts->{'allowed'}}} = ();
		$rv = \%alluse;
		delete $opts->{'allowed'};
		return $rv;
}
# 
# get_allowed
#-----------------------------------------------------------------------------------


# return true
1;

__END__


=head1 IS TAXI DATA XML?

Although Taxi's data format is XML-ish, it's not fully compliant 
to XML in all regards.  For now, Taxi only promises that it can input
its own output.  The reason I didn't go for full XML compliance is that I
wanted to keep Taxi as light as possible while achieving its main goal
in life: pure-perl serialization.  XML compliance is not part of that goal.
If you want to help make Taxi fully XML compliant w/o making it bloated,
that's cool, drop me an email and we can work together.


=head1 TODO

Tied scalars don't work.  The code started getting spaghettish trying to implement them, 
so I decided to use the Asimov method and stop thinking about it for a while.  Tied
hashes and arrays should work fine.

=head1 TERMS AND CONDITIONS

Copyright (c) 2002 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.


=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>


=head1 VERSION

 Version 0.90    June 15, 2002
 initial public release

 Version 0.91    July 10, 2002
 minor improvment to documentation

 Version 0.94    April 26, 2003
 Fixed problem handling undefined scalars.

 Version 0.95    Oct 31, 2008
 Adding notice of last release

 Version 0.96    Nov 14, 2010
 Fixing bug:


=end CPAN


=cut
