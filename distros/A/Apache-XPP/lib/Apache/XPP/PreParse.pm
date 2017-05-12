=head1 NAME

Apache::XPP::PreParse - XPP TAG Parser

=cut

=head1 SYNOPSIS

 use Apache::XPP::PreParse;
 $preparsers	= Apache::XPP::PreParse->parsers;
 foreach (@{ $preparsers }) {
 	$preparsers->( \$text );
 }

=head1 REQUIRES

Nothing

=head1 EXPORTS

Nothing

=cut

package Apache::XPP::PreParse;

use Carp;
use strict;
use vars qw($AUTOLOAD @parsers $debug );

BEGIN {
	$Apache::XPP::PreParse::REVISION       = (qw$Revision: 1.19 $)[-1];
	$Apache::XPP::PreParse::VERSION        = '2.01';

	$debug		= undef;
	@parsers	= qw( parser_xppcomment parser_xppcache parser_xppxinclude
		parser_print parser_appmethod parser_xppforeach parser_xppshift
		parser_xppwhile );
}

=head1 DESCRIPTION

Apache::XPP::PreParse handles pre parsing of an xpp page to convert 'tags' into valid 
XPML. Tags are meant as a shortcut for code that might otherwise be burdensome or 
confusing for and xpml author, such as ref checking before calling a method: 
<xpp method="cities_popup_menu" obj="$app"> might be converted to: 
<?xpp if (ref($app)) { print $app->cities_popup_menu; } ?>.

=head1 METHODS

=over

=item C<parsers> (  )

Returns a new parser object

=cut
sub parsers {
	my $self = shift;
	my $class = ref($self) || $self;
	no strict 'refs';
	return \@{"${class}::parsers"};
} # END method parsers


=item C<add_parser> ( \&parser )

Adds a parser to the list of registered pre-parsers.

=cut
sub add_parser {
	my $proto		= shift;
	my $class		= ref($proto) || $proto;
	my $parser		= shift;
	push(@parsers, $parser);
} # END method add_parser

=item C<parse_tag> ( $tag )

Given an xpp TAG $tag, will return an array with two elements.
The first element is an array reference of the order of keys in
the tag. The second element is a hash reference to the key-value
pairs.

=cut
sub parse_tag {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $tag		= shift;
	if ($tag =~ m/\<(.+)?\>/s) {
		my $tagcontent	= $1;
		warn "CONTENT: $tagcontent" if ($debug >= 2);
		my (@keys, %data);
		while ($tagcontent =~ s/^(?:\s*)([^=\s]+)(?:\="(.*?)")?//so) {
			push(@keys, $1);
			$data{ $1 }	= $2;
		}
		
		return (\@keys, \%data);
	} else {
		return undef;
	}
} # END method parse_tag

=item C<dtag> ( \$text, $tag, $subref )

This is for processing tags with a start tag and seperate end tag.
All the data in between is sent to $subref->( $params, $data) where
$params is a hashref containing all the key value pairs in the
start tag and $data is the data contained in between the opening and
closing tag.

=cut

sub dtag {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $text	= shift;
	my $tag		= shift;
	my $subref	= shift;

	warn "Invalid paramaters passed!" 
		unless (defined(${ $text }) && defined($tag) && defined($subref));

	while ( ${ $text } =~ s/(<$tag(?:\s*\w+?=\".+?\")*>)((?:(?!<$tag|<\/$tag).)*(?:<$tag(?:\s*\w+?=\".+?\")*>.*?<\/$tag>)?(?:(?!<\/$tag>).)*?)<\/$tag>/my ($keys, $params) = $proto->parse_tag( $1 ); $subref->( $params, $2, @_ );/se ) {}
}		

=item C<parse_stag>

Called by stag to parse the matched tag with the supplied rules.

=cut

sub parse_stag {
	my $proto = shift;
	my ($keys, $data, $rrules) = @_;
	my $replace;
	foreach my $rule (ref($rrules->[0]) ? @{ $rrules } : ($rrules)) {
			my ($template, $fields);
			if ($#{ $rule } == 2) {
				my $opt	= $rule->[0];
				($template, $fields)	= @{ $rule }[1,2];
				unless (exists $data->{ $opt }) {
					next;
				}
			} elsif ($#{ $rule } == 1) {
				($template, $fields)	= @{ $rule };
			}
			
			$replace = sprintf( $template, map { $data->{$_} } @{ $fields } );

			last;
		}
	return $replace;

}

=item C<stag> ( \$text, $match, \@replace_rules )

Given a string to match, uses the replace rules to replace tags that contain
the $match with it's equivalent. See examples below for syntax of replace rules.

=cut

sub stag {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $text	= shift;
	my $match	= shift;
	my $rrules	= shift;

	${ $text } =~ s/($match(?:\s*\w+?(?:=\".+?\")?)*\s*>)/$proto->parse_stag($proto->parse_tag( $1 ), $rrules);/seg;
	
} # END method stag

###################### This is the old code. Until the above regex is fully tested lets
###################### keep it.
#	my ($spos, $epos);
#	my @matches;
#	my $i			= -1;
#	my $tagflag		= 0;
#	my $valflag		= 0;
#	my $tagmatch	= 0;
#	while (my $chr = substr( ${ $text }, ++$i, 1 )) {
#		if (($chr eq '<') && !($valflag)) {
#			warn "*** begin at [$i]\n" if ($debug >= 2);
#			warn "\t<<< " . substr(${ $text }, $i, index(${ $text }, '>', $i)-$i+1) . " >>>\n" if ($debug >= 3);
#			$tagflag	^= 1;
#			$tagmatch	= 0;
#			$spos		= $i;
#		} elsif (($chr eq '"') && ($tagflag)) {
#			if ($valflag) {
#				warn "*** endVAL" if ($debug >= 3);
#			} else {
#				warn "*** beginVAL" if ($debug >= 3);
#			}
#			$valflag	^= 1;
#		} elsif (($chr eq '>') && !($valflag)) {
#			warn "    end\n" if ($debug >= 2);
#			$tagflag	= 0;
#			$epos		= $i + 1;
#			push(@matches, [$spos, $epos]) if ($tagmatch);
#		}
#		
#		my $tmp		= substr( ${ $text }, $i, length($match) );
#		$tmp		=~ s/\n/\\n/g;
#		warn "\t(CHR, TAG, VAL, NEXTLEN, NEXT) ($chr, $tagflag, $valflag, " . length($match) . ", $tmp\n" if ($debug >= 3);
#		
#		if (($tagflag) && !($valflag) && (lc(substr( ${ $text }, $i, length($match) )) eq lc($match))) {
#			warn "*** MATCHING TAG" if ($debug >= 2);
#			$tagmatch	= 1;
#		}
#	}
#	
#	@matches	= sort { $b->[0] <=> $a->[0] } @matches;
#	foreach (@matches) {
#		my ($st,$en)	= @{ $_ };
#		my $replace		= \substr( ${ $text }, $st, ($en - $st) );
#		my ($keys, $data)	= $proto->parse_tag( ${ $replace } );
#		foreach my $rule (ref($rrules->[0]) ? @{ $rrules } : ($rrules)) {
#			warn "RULE: " . Dumper($rule) if ($debug >= 2);
#			my ($template, $fields);
#			if ($#{ $rule } == 2) {
#				my $opt	= $rule->[0];
#				($template, $fields)	= @{ $rule }[1,2];
#				unless (exists $data->{ $opt }) {
#					next;
#				}
#			} elsif ($#{ $rule } == 1) {
#				($template, $fields)	= @{ $rule };
#			}
#			
#			${ $replace }	= sprintf( $template, map { $data->{ $_ } } @{ $fields } );
#			last;
#		}
#	}
################################

*AUTOLOAD = \&{ "Apache::XPP::AUTOLOAD" };

##################################################

=item C<parser_xppcomment>

Used to comment out blocks of xpml code.

Ex:
 <XPPCOMMENT>
  <title><?= $obj->title() ?></title>
 </XPPCOMMENT>

=cut

sub parser_xppcomment {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $text	= shift;
	my $subref = sub { 
					return "";
				};	
	$self->dtag($text, "XPPCOMMENT", $subref);
}

=item C<parser_xppcache>

Cache a block of code using a specific expire/store module. Pass
the caches name, group, expire, and store. See L<xppcachetut.pod>
for more information.

Ex:
 <XPPCACHE name="mycache" group="cachegroup" store="File" expire="Duration, 10s">
  ....
 </XPPCACHE>

=cut

sub parser_xppcache {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $text = shift;
	my $subref = sub {
					my $params = shift;
					my $data = shift;
					unless ( (defined ($params->{'name'}))	&& 
					 		 (defined ($params->{'group'}))	&&
							 (defined ($params->{'store'}))	&&
							 (defined ($params->{'expire'})) ) {
						warn "<XPPCACHE> tags must contain the following params: "
							."name, group, store and expiretype.";		 
						return undef;	
					}		
					my $cache = Apache::XPP::Cache->new( 
									$params->{'name'}, $params->{'group'}, {}, 
									[ split( /,\s*/, $params->{'store'} ), \$data ],
									[ split( /,\s*/, $params->{'expire'} ) ]);
					return $cache->content;
				};
	$self->dtag($text, "XPPCACHE", $subref);
}	

=item C<parser_appmethod>

Assign or print an object method. Ref checks the object before using
it. Assigns the result to the value of the as tag parameter. If this
param isn't present the result is printed.

Ex:
 <XPP app app="$obj" attr="bleh" as="$var">
 <XPP app app="$obj" attr="bleh">

=cut

sub parser_appmethod {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $text	= shift;
	$self->stag(
					$text,
					
					#if the tag begins with '<xpp app' ...
					q{<XPP app},
					[
						# and contains an 'as' attribute - replace with:
						#   sprintf('<?xpp my %s = ref(%s) ? %s->%s : ""; ?>', @attributes{ qw(as app app attr) });
						[ 'as', '<?xpp my %s = ref(%s) ? %s->%s : ""; ?>', [qw(as app app attr)] ],

						# otherwise - replace with:
						#   sprintf('<?xpp= %s->%s; ?>', @attributes{ qw(app attr) });
						[ '<?xpp= %s->%s; ?>', [qw(app attr)] ],
					]
				  );
}

=item C<parser_print>

Prints the result of an object method.

Ex:
 <XPP print obj="$obj" attr="bleh">

=cut

sub parser_print {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $text	= shift;
	$self->stag(
					$text,
					
					# if the tag begins with '<XPP print' ...
					q{<XPP print},
					
					# replace it with:
					#   sprintf('<?xpp print ref(%s) ? %s->%s() : ""; ?>', @attributes{ qw(obj obj attr) });
					[ '<?xpp print ref(%s) ? %s->%s() : ""; ?>', [qw(obj obj attr)] ]
				  );
}

=item C<parser_xppxinclude>

Calls xinclude with the passed filename and options.

Ex:
 <XPP xinclude filename="include.xmi" options="$obj1, $obj2">

=cut

sub parser_xppxinclude {
	my $self = shift;
	my $text = shift;
	$self->stag(
					$text,

					#if the tag begins with <XPPXINCLUDE
					q{<XPP xinclude},
					[ '<?xpp xinclude("%s", [ split(/,\s*/, %s) ]); ?>', [qw(filename options)] ]
					);

}					

=item C<parser_xppforeach>

Places the included block within a foreach loop. Assigning each element
of the array to 'as.' If 'as' is not present it uses $_.

Ex:
 <XPPFOREACH array="@ary" as="$val">
 <XPPFOREACH array="@ary">

=cut

sub parser_xppforeach {
	my $self = shift;
	my $text = shift;
	my $subref = sub {
						my $params = shift;
						my $data = shift;
						my $as = $params->{'as'}?'my '.$params->{'as'}:'';
						my $xppstring = "<?xpp foreach $as (".$params->{'array'}.") { ?>\n"	
										.$data ."\n<?xpp } ?>\n";
						return $xppstring;
					};	
	$self->dtag($text,"XPPFOREACH",$subref);
}	

=item C<parser_xppwhile>

Places the included block within a while block, looping on the condition
specified in 'condition'. If the option 'counter' is specified, the number
of loops performed will be assigned to that scalar.

Ex:
 <XPPWHILE condition="my $bar = shift @foo" counter="$count">
  Shifted off <?= $bar ?>.<BR>
 </XPPWHILE>
 I looped <?= $count ?> times.

=cut

sub parser_xppwhile {
	my $self = shift;
	my $text = shift;
	my $subref = sub {
						my $params = shift;
						my $data = shift;
						my $xppstring = '<?xpp ';
						my $counter = $params->{counter};
						$xppstring .= "my $counter = 0;\n" if $counter;
						$xppstring .= "while ($params->{condition}) { ";
						$xppstring .= "\n$counter++;\n" if $counter;
						$xppstring .= "?>\n$data\n<?xpp } ?>\n";
						return $xppstring;
					};	
	$self->dtag($text,"XPPWHILE",$subref);
}	

=item C<parser_xppshift>

Shifts one value off the given array (C<@_> if none is specified) and assigns
the value to the specified scalar, scoped lexically (using C<my()>).

Ex:
 <XPPSHIFT array="@ary" as="$val">

=cut

sub parser_xppshift {
   	my $self = shift;
   	my $text = shift;
   	$self->stag( $text, '<XPPSHIFT',
   		[
   			[ 'array', '<?xpp my %s = shift(%s); ?>', [ 'as', 'array' ] ],
   			[ '<?xpp my %s = shift; ?>', [ 'as' ] ],
   		]
	);
}

1;

__END__

=back

=head1 REVISION HISTORY

$Log: PreParse.pm,v $
Revision 1.19  2002/01/16 21:06:01  kasei
Updated VERSION variables to 2.01

Revision 1.18  2000/09/28 20:10:59  zhobson
- Added parser_xppwhile and the <XPPWHILE> tag
- Added parser_xppshift and the <XPPSHIFT> tag

Revision 1.17  2000/09/14 23:01:30  dougw
Fixed stag pod.

Revision 1.16  2000/09/13 00:32:04  dougw
Pod for tag methods.

Revision 1.15  2000/09/11 20:15:33  david
Sent AUTOLOAD to Apache::XPP::AUTOLOAD.

Revision 1.14  2000/09/07 19:03:19  dougw
over fix

Revision 1.13  2000/09/07 18:48:36  dougw
Took out some use vars

Revision 1.12  2000/09/07 18:45:42  dougw
Version Update.

Revision 1.11  2000/09/07 00:05:38  dougw
POD fixes.


=head1 SEE ALSO

perl(1).
tagtut

=head1 KNOWN BUGS

None

=head1 TODO

...

=head1 COPYRIGHT

 Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
 software. It may be used, redistributed and/or modified under the terms
 of the GNU Lesser General Public License as published by the Free Software
 Foundation.

 You should have received a copy of the GNU Lesser General Public License
 along with this library; if not, write to the Free Software 
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Greg Williams <greg@cnation.com>
Doug Weimer <dougw@cnation.com>

=cut
