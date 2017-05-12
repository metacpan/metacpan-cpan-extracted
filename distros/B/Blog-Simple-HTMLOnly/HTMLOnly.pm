package Blog::Simple::HTMLOnly;

# use 5.6.1;
use strict;
use warnings;

use vars qw/@ISA $VERSION/;
$VERSION = '0.05'; # depends

use HTML::TokeParser;

=head1 NAME

Blog::Simple::HTMLOnly - Very simple weblog (blogger) with just Core modules.

=head1 SYNOPSIS

	my $blog = Blog::Simple::HTMLOnly->new();
	$blog->create_index(); # generally only needs to be called once
	#
	# ...
	#
	my $content="<p>blah blah blah in XHTM</p><p><b>Better</b> when done in
	HTML!</p>";
	my $title  = 'some title';
	my $author = 'a.n. author';
	my $email  = 'anaouthor@somedomain.net';
	my $smmry  = 'blah blah';
	my $ctent  = '<blockquote>Twas in the month of Liverpool and the city of July...</blockquote>',
	$blog->add($title,$author,$email,$smmry,$ctent);
	#
	# ...
	#
	my $format = {
		simple_blog_wrap => '<table width='100%'><tr><td>',
		simple_blog => '<div class="box">',
		title       => '<div class="title"><b>',
		author      => '<div class="author">',
		email       => '<div class="email">',
		ts          => '<div class="ts">',
		summary     => '<div class="summary">',
		content     => '<div class="content">',
	};
	$blog->render_current($format,3);
	$blog->render_all($format);
	$blog->remove('08');
	exit;

Please see the *.cgi files included in the tar distribution for examples of simple use.

=head1 DEPENDENCIES

Nothing outside of the core perl distribution.

=head1 EXPORT

Nothing.

=head1 DESCRIPTION

This is a backwards-compatible modification of C<Blog::Simple>
by JA Robson <gilad@arbingersys.com>, indentical in all but
the need for C<XML::XSLT> and Perl 5.6.1. It also includes an additional
method to render a specific blog, and the latest C<n> blogs.

Instead of C<XML::XSLT>, this module uses C<HTML::TokeParser>,
of the core distribution. Naturally formatting is rather restricted,
but it can produce some useful results if you know your way around
CSS (L<http://www.zvon.org|http://www.zvon.org>), and is better than
a poke in the eye with a sharp stick.

=head1 USAGE

Please read the documentation for L<Blog::Simple> before continuing,
but ignore the documentation for the rendering methods.

The rendering methods C<render_current> and C<render_all> no longer
take a paramter of an XSLT file, but instead a reference to a hash,
the keys of which are the names of the nodes in a C<Blog::Simple>
XML file, values being HTML to wrap around the named node.

Only the opening tags need be supplied: the correct end-tags will
supplied in lower-case by this module.

For an example, please see the L<SYNOPSIS>.

=cut

#this method takes a predetermined number of blogs from the top of the 'bb.idx' file
#and generates an output file (HTML). The $format argument is explained in the POD
#

=head2 METHOD render_current_by_author

As C<METHOD render_current> but accepts a format hash, number of entries to display,
an optional B<author ID>, and optional output file.

=cut

sub render_current_by_author { my ($self, $format, $dispNum, $author, $outFile) = (@_);
	$self->{_show_author} = $author;
	return $self->render_current($format, $dispNum, $outFile);
}

sub render_current { my ($self, $format, $dispNum, $outFile) = (@_);
	local *BB;
	# make sure we're getting a reasonable number of blogs to print
	$dispNum = 1 if $dispNum < 1;

	#read in the blog entries from the 'bb.idx' file
	unless (open BB, $self->{blog_idx}){
		die "No blog index $self->{blog_idx}: $!, caller:" .(join" ",caller);
	}
    flock *BB,2 if $^O ne 'MSWin32';
    seek BB,0,0;    	# rewind to the start
    truncate BB, 0;		# the file might shrink!
	my @getFiles;
	my $cnt=0;
	while (<BB>) {
		next if (($cnt == $dispNum) || ($_ =~ /^\#/));
		my @tmp = split(/\t/, $_);
		next if defined $self->{_show_author} and $tmp[3] ne $self->{_show_author};
		push(@getFiles, $tmp[0]);
		$cnt++;
	}
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';

	#open the 'blog.xml' files individually and concatenate into xmlString
	my $xmlString = "<simple_blog_wrap>\n";
	foreach my $fil (@getFiles) {
		my $preStr;
		open (GF, "$fil") or die "Error opening $fil - $!";
		flock *GF,2 if $^O ne 'MSWin32';
		seek GF,0,0;       # rewind to the start
		truncate GF, 0;	# the file might shrink!
		while (<GF>) { $preStr .= $_; }
		close GF;
		flock (*GF, 8) if $^O ne 'MSWin32';
		$xmlString .= $preStr;
	}
	$xmlString .= "</simple_blog_wrap>\n";

	#process the generated Blog file
	my $outP = $self->transform ($format,\$xmlString);

	if (not defined $outFile) { #if output file set to nothing, spit to STDOUT
		print $$outP;
	}
	else {
		open (OF, ">$self->{path}". $outFile);
		flock *OF,2 if $^O ne 'MSWin32';
		seek OF,0,0;       # rewind to the start
		truncate OF, 0;	# the file might shrink!
		print OF $$outP;
		close OF;
		flock (*OF, 8) if $^O ne 'MSWin32';
	}
	return $outP;
}

#this subroutine creates an archive output by opening 'bb.idx' and
#concatentating all the <simple_blog></simple_blog> files in the
#blogbase into a single string, and processing it $format as explained
#in the pod. Works nearly identical to gen_Blog_Current,
#except it gets all blogs, not just the 'n' most current.

sub render_all { my ($self, $format, $outFile) = @_;
	#read in the blog entries from the 'bb.idx' file
	open(BB, $self->{blog_idx}) or die 'Error opening idx '.$self->{blog_idx}." - $!";
	flock *BB,2 if $^O ne 'MSWin32';
	seek BB,0,0;       # rewind to the start
	truncate BB, 0;	# the file might shrink!
	my @getFiles;
	while (<BB>) {
		next if ($_ =~ /^\#/);
		my @tmp = split(/\t/, $_);
		next if defined $self->{_show_author} and $tmp[3] ne $self->{_show_author};
		push (@getFiles, $tmp[0]);
	}
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';


	#open the 'blog.xml' files individually and concatenate into xmlString
	my $xmlString = "<simple_blog_wrap>\n";
	foreach my $fil (@getFiles) {
		my $preStr;
		open (GF, $fil) or die "Error opening $fil - $!";
		flock *GF,2 if $^O ne 'MSWin32';
		seek GF,0,0;       # rewind to the start
		truncate GF, 0;	# the file might shrink!
		while (<GF>) { $preStr .= $_; }
		close GF;
		flock (*GF, 8) if $^O ne 'MSWin32';
		$xmlString .= $preStr;
	}
	$xmlString .= "</simple_blog_wrap>\n";

	#process the generated Blog file
	my $outP = $self->transform ($format,\$xmlString);

	if (not defined($outFile)) { #if output file not defined, spit to STDOUT
		print $$outP;
	}
	else {
		open (OF, ">$self->{path}". $outFile);
		flock *OF,2 if $^O ne 'MSWin32';
		seek OF,0,0;       # rewind to the start
		truncate OF, 0;	# the file might shrink!
		print OF $$outP;
		close OF;
		flock (*OF, 8) if $^O ne 'MSWin32';
	}
	return $outP;
}


=head2 METHOD render_all_by_author

Identical to C<render_all> but takes an additional argument, that is the author ID.

=cut

sub render_all_by_author { my ($self, $format, $author, $outFile) = @_;
	$self->{_show_author} = $author;
	return $self->render_all($format, $outFile);
}



# Transform XML to HTML
# Accepts: reference to a 'formatting' hash; reference to a string of XML
# Returns: reference to a string of HTML
sub transform { my ($self, $format, $xml) = (shift, shift, shift);
	local $_;

	if (not defined $format or ref $format ne 'HASH'){
		Carp::confess "transform takes two arguments, the first being a hash reference for formatting";
	}
	if (not defined $xml or ref $xml ne 'SCALAR'){
		Carp::confess "transform takes two arguments, the second being a scalar reference of XML";
	}
	my $open = {};
	my $html;
	foreach my $node (keys %$format){
		my $p    = HTML::TokeParser->new(\$format->{$node});
		my $html = "";
		while (my $t = $p->get_token){
			push @{$open->{$node}},"@$t[1]" if @$t[0] eq 'S';
		}
	}

	my $p = HTML::TokeParser->new($xml);
	my @current;
	#	use Data::Dumper; die Dumper $xml,$format; #simple_blog_wrap|simple_blog|ts|

	while (my $t = $p->get_token){
		if (@$t[0] eq 'S' and @$t[1] =~ /^(simple_blog_wrap|simple_blog|ts|title|author|email|summary|content)$/){
			# warn "Open ",@$t[1],"\n" if $^W;
			push @current, @$t[1];
			$html .= $format->{@$t[1]} if exists $format->{@$t[1]};
		}
		elsif (@$t[0] eq 'T'){
			# warn "Text @$t[1]","\n" if $^W;
			$html .= @$t[1] . $p->get_text;
		}
		elsif (@$t[0] eq 'E' and @$t[1] =~ /^(simple_blog_wrap|simple_blog|ts|title|author|email|summary|content)$/){
			# warn "Close @$t[1] with ", join",",@{$open->{$current[$#current]}},"\n"  if $^W;
			$html .= join '',( map {"</$_>"} reverse @{$open->{$current[$#current]}}) if $open->{$current[$#current]};
			pop @current;
		} elsif (@$t[0] eq 'S') {
			$html .= @$t[4];
		} elsif (@$t[0] =~ /^(E|PI)$/) {
			$html .= @$t[2];
		} else {
			$html .= @$t[1];
		}
	}
	return \$html;
}


=head2 METHOD: render_these_blogs

Alias for C<render_this_blog>.

=head2 METHOD: render_this_blog

Renders to C<STDOUT> the nominated blog(s).

In addition to the method's object reference, accepts
a date and an author, and a format hash (see above).
The date should be in a C<localtime> output with spaces
turned to underscores (C<_>).

On success, returns a reference to the Blog in HTML.
On failure returns C<undef>, sending a warning to C<STDERR>
if you have C<warnings> on (C<-w>).

=cut

sub render_these_blogs {
	my $self=shift;
	return $self->render_this_blog(@_);
}

sub render_this_blog { my ($self,$date,$author,$format) = (shift,shift,shift,shift);
	local (*IN, *DIR);
	my ($html);
	$date =~ s/[^\w\d_\*]//sg;
	$date =~ s/\*/\.\*\?/g;
	opendir DIR, $self->{blog_base};
	my @dirs = grep {/^$date$/} readdir DIR;
	closedir DIR;
	foreach my $dir (reverse sort @dirs){
		unless (open IN, $self->{blog_base}.$dir.'/blog.xml'){
			warn "Could not find blog, <pre>",
				$self->{blog_base}.$date."_".$author,
				"</pre>" if $^W;
			return undef;
		}
		my $xmlString;
		read IN,$xmlString,-s IN;
		close IN;
		$$html .= ${ $self->transform ($format,\$xmlString) };
	}
	print $$html;
	return $html;
}

#################################################################
#
# Taken almost verbatum from Blog::Simple
#
#################################################################

#instantiate object, create dir/files under path
sub new {
	#get parameters
	my ($obj, $pth) = @_;

	Carp::croak 'You must supply a path as the sole argument.' if not $pth;

	$pth =~ s/\\/\//g; #turn backslashes into forward

	#add the final slash, if needed
	$pth .= "/" if $pth !~ /\/$/;

	#create object data structure
	my %sBlog = (
		path => $pth,
		blog_idx => $pth . "bb.idx",
		blog_base => $pth . "b_base/",
		del_list => ''
	);

	#create the paths
	mkdir($sBlog{path}); #root path
	mkdir($sBlog{blog_base});

	my $sBRef = \%sBlog;
	bless $sBRef, $obj;
}

#generate the 'bb.idx' file
sub create_index { my $obj = shift;
	open(F, ">$obj->{blog_idx}") or die $obj->{blog_idx}, " ",$!;
    flock *F,2 if $^O ne 'MSWin32';
    seek F,0,0;       # rewind to the start
    truncate F, 0;	# the file might shrink!
	print F "#path_to_blog	date_stamp	title	author	summary";
	close F;
	flock (*F, 8) if $^O ne 'MSWin32';
}

#adds a blog to the 'b_base' directory
sub add { my ($obj, $title, $author, $email, $smmry, $content) = @_;
	local (*BF,*BB);

	#handle undefined variables
	if (not defined($title)) { $title = ''; }
	if (not defined($author)) { $author = ''; }
	if (not defined($email)) { $email = ''; }
	if (not defined($smmry)) { $smmry = ''; }
	if (not defined($content)) { $content = ''; }

	my $tmp = localtime(time);
	my $ts = $tmp; #for 'bb.idx' entry

	$content =~ s/\t/     /g; #remove any tabs in the content, summary
	$smmry =~ s/\t/     /g;


#The core blog XML template
#==========================
	my $blogTmplt =<<END_BT;
<simple_blog>
	<title>$title</title>
	<author>$author</author>
	<email>$email</email>
	<ts>$ts</ts>
	<summary>$smmry</summary>
	<content>$content</content>
</simple_blog>
END_BT
#==========================

	#prepare the directory to be unique
	$tmp =~ s/[\s:]/_/g;
	my $tmpA = $author;
	$tmpA =~ s/[^a-zA-Z]/_/g;
	my $unqDir = $obj->{blog_base} . $tmp . "_" . $tmpA . "/";

	#create the directory
	mkdir $unqDir or die 'Could not mkdir '.$unqDir.' - '. $!;

	#put 'blog.xml' in it
	open(BF, ">${unqDir}blog.xml") or die "Could not open to write $unqDir/blog.xml - $!";
    flock *BF,2 if $^O ne 'MSWin32';
    seek BF,0,0;       # rewind to the start
    truncate BF, 0;	# the file might shrink!
	print BF $blogTmplt;
	close BF;
	flock (*BF, 8) if $^O ne 'MSWin32';

	#save entry to 'bb.idx'
	open(BB, $obj->{blog_idx}) or die "Could not open $obj->{blog_idx} - $!";
    flock *BB,2 if $^O ne 'MSWin32';
    seek BB,0,0;       # rewind to the start
    truncate BB, 0;	# the file might shrink!
	my $bbIdx;
	while (<BB>) { $bbIdx .= $_; }
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';

	my $curLine = "${unqDir}blog.xml\t$ts\t$title\t$author\t$smmry\n";

	open(BB, ">$obj->{blog_idx}") or die "Error writing $obj->{blog_idx} - $!";
    flock *BB,2 if $^O ne 'MSWin32';
    seek BB,0,0;       # rewind to the start
    truncate BB, 0;	# the file might shrink!
	print BB $curLine; print BB $bbIdx;
	close BB;
	flock (*BB, 8) if $^O ne 'MSWin32';
}

#remove entry from bb.idx
#the parameter passed is a regular expression. This way, multiple entries
#can be removed simultaneously. Only removes entries from the 'bb.idx' file
#and returns the paths that need to be removed as an array.
sub remove {
	my ($obj, $rex) = @_;
	local (*RB);

	if (defined($rex)) {
		my @bbI;
		my @delF;

		#get the index, check for matches, return only those lines
		#that do not match
		open(RB, $obj->{blog_idx}) or die 'Could not open '.$obj->{blog_idx}.' '.$!;
		flock *RB,2 if $^O ne 'MSWin32';
		seek RB,0,0;       # rewind to the start
		truncate RB, 0;	# the file might shrink!
		foreach my $chk (<RB>) {
			if ($chk =~ /$rex/) {
				#do the removal code
				my @lA = split(/\t/, $chk);
				push(@delF, $lA[0]);
			}
			else { push(@bbI, $_); }
		}
		close RB;
		flock (*RB, 8) if $^O ne 'MSWin32';

		#write the new index
		open(RB, ">".$obj->{blog_idx}) or die 'Could not open to write to '.$obj->{blog_idx}.' '.$!;
		print RB @bbI;
		close RB;

		$obj->{del_list} = \@delF;
	} #defined($rex)

}



1;
__END__


=head1 OTHER MODIFICATIONS TO Blog::Simple

The only other things I've changed are:

=over 4

=item *

All files C<flock> if not running on Win32 (cygwin is
ignored as I don't know if it needs it; presumably it does,
though).

=item *

The render routines return a reference to a scalar,
which is the formatted HTML.

-item *

C<for> loops simplified.

=back

=head1 SEE ALSO

See L<Blog::Simple>, L<HTML::TokeParser>.

=head1 AUTHOR

Lee Goddard (lgoddard -at- cpan -dot- org),
Most of the work already done by J. A. Robson, E<lt>gilad@arbingersys.comE<gt>

=head1 COPYRIGHT

This module: Copyright (C) Lee Goddard, 2003, and J. A. Robson.
All Rights Reserved.
Made available under the same terms as Perl itself.

=cut

