use strict;
use warnings;

package CGI::ProgressBar;

=head1 NAME

CGI::ProgressBar - CGI.pm sub-class with a progress bar object

=head1 SYNOPSIS

	use strict;
	use warnings;
	use CGI::ProgressBar qw/:standard/;
	$| = 1;	# Do not buffer output
	print header,
		start_html(
			-title=>'A Simple Example',
			-style=>{
				-src  => '', # You can override the bar style here
				-code => '', # or inline, here.
			}
		),
		h1('A Simple Example'),
		p('This example will update a JS/CSS progress bar.'),
		progress_bar( -from=>1, -to=>100 );
	# We're set to go.
	for (1..10){
		print update_progress_bar;
		# Simulate being busy:
		sleep 1;
	}
	# Now we're done, get rid of the bar:
	print hide_progress_bar;
	print p('All done.');
	print end_html;
	exit;

=head1 DESCRIPTION

This module provides an HTML/JS progress bar for web browsers, to keep end-users occupied when otherwise
nothing would appear to be happening.

It aims to require that the recipient client have a minimum
of JavaScript 1.0, HTML 4.0, and CSS/1.

All feedback would be most welcome. Address at the end of the POD.

=cut

use 5.004;

=head2 DEPENDENCIES

	CGI

=cut

our $VERSION = '0.05';

BEGIN {
	use CGI::Util; # qw(rearrange);
	use base 'CGI';

=head2 EXPORT

	progress_bar
	update_progress_bar
	hide_progress_bar

=cut

	no strict 'refs';
	foreach (qw/ progress_bar update_progress_bar hide_progress_bar/){
		*{caller(0).'::'.$_} = \&{__PACKAGE__.'::'.$_};
	}
	use strict 'refs';
}

=head1 USE

The module sub-classes CGI.pm, providing three additional methods (or
functions, depending on your taste), each of which are detailed below.

Simply replace your "use CGI qw//;" with "use CGI::ProgressBar qw//;".

Make sure you are aware of your output buffer size: C<$|=$smothingsmall>.

Treat each new function as any other CGI.pm HTML-producing routine with
the exception that the arguments should be supplied as in OOP form. In
other words, the following are all the same:

	my $html = $query->progress_bar;
	my $html = progress_bar;
	my $html = progress_bar(from=>1, to=>10);
	my $html = $query->progress_bar(from=>1, to=>10);
	my $html = $query->progress_bar(-to=>10);

This will probably change if someone would like it to.

=head1 FUNCTIONS/METHODS

=head2 FUNCTION/METHOD progress_bar

Returns mark-up that instantiates a progress bar.
Currently that is HTML and JS, but perhaps the JS
ought to go into the head.

The progress bar itself is an object in this class,
stored in the calling (C<CGI>) object - specifically
in the field C<progress_bar>, which we create.
(TODO: Make this field an array to allow multiple bars per page.)

=over 4

=item from

=item to

Values which the progress bar spans.
Defaults: 0, 100.

=item orientation

If set to C<vertical> displays the bar as a strip down the screen; otherwise,
places it across the screen.

=item width

=item height

The width and height of the progress bar, in pixels. Cannot accept
percentages (yet). Defaults: 400, 20, unless you specify C<orientation>
as C<vertical>, in which case this is reversed.

=item blocks

The number of blocks to appear in the progress bar.
Default: 10. You probably want to link this to C<from> and C<to>
or better still, leave it well alone: it may have been a mistake to even include it.
C<steps> is an alias for this attribute.

=item label

Supply this parameter with a true value to have a numerical
display of progress. Default is not to display it.

=item layer_id

Most HTML elements on the page have C<id> attributes. These
can be accessed through the C<layer_id> field, which is a hash
with the follwoing keys relating to the C<id> value:

=item mycss

Custom CSS to be written inline (ugh) after any system CSS.

=over 4

=item form

The C<form> which contains everything we display.

=item container

The C<div> containing everything we display.

=item block

This value is used as a prefixed for the C<id> of each block of the bar,
with the suffix being a number incremented from C<1>.

=item number

The digits being updated as the bar progresses, if the option is enabled.

=back

=back

=cut

our $CSS = '';

sub progress_bar {
    local $_;
    my ($self,%args);
    ($self,@_) = &CGI::self_or_default(@_);

	my $pb = bless {
		_updates=> 0,		debug	=> undef,
		mycss	=> '',		orientation	=> 'horizontal',
		from	=> 1,		to		=> 100,	width	=> '400',
		height	=> '20',	blocks	=> 10,
		label	=> 0,		colors	=> [100,'blue'],
	},__PACKAGE__;

	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		warn "Usage: \$class->new(  keys=>values,  )";
		return undef;
	}
	foreach my $k (keys %args){
		my $nk = $k;
		$nk =~ s/^-(.*)$/$1/;
		$pb->{$nk} = $args{$k};
	}
	$pb->{blocks} = $args{steps} if $args{steps};

	$pb->{orientation} = 'vertical' if $pb->{orientation} eq 'v';
	if ($pb->{orientation} eq 'vertical'){
		my $w = $pb->{width};
		$pb->{width} = $pb->{height};
		$pb->{height} = $w;
	}

	$pb->{colors}	= $pb->{colors}? {@{$pb->{colors}}} : {100=>'blue'};
	$pb->{_length}	= $pb->{to} - $pb->{from};	# Units in the bar
	$pb->{_interval} = 1;	# publicise?
#	$pb->{_interval} = $pb->{_length}>0? ($pb->{_length}/$pb->{blocks}) : 0;
 	$pb->{block_wi} = int( $pb->{width} / $pb->{blocks} ) -2;
	# IN A LATER VERSION....Store ourself in caller's progress_bar array
	# push @{ $self->{progress_bar} },$pb;
	$self->{progress_bar} = $pb;

	for my $k (qw[ from to blocks _interval ]){
		$pb->{$k} = int($pb->{$k});
	}

	if ($pb->{debug}){
		require Data::Dumper; import Data::Dumper;
		warn 'New CGI::ProgressBar '.Dumper($pb);
		warn 'Total blocks='.($pb->{blocks});
		warn 'Expected total calls='.($pb->{to}/$pb->{_interval});
	}

	return $self->_pb_init();
}



=head2 FUNCTION/METHOD update_progress_bar

Updates the progress bar.

=cut

sub update_progress_bar {
# 	my ($self, @crud) = CGI::self_or_default;
	return "<script type='text/javascript'>//<!--
	pblib_progress_update()\n//-->\n</script>\n";
}

=head2 FUNCTION/METHOD hide_progress_bar

Hides the progress bar.

=cut

sub hide_progress_bar {
	my ($self, @crud) = CGI::self_or_default;
	#my $pb = $self->{progress_bar}[$#{$self->{progress_bar}}];

	return $self->{progress_bar}?
	"<script type='text/javascript'>//<!--
	$self->{progress_bar}->{layer_id}->{container}.style.display='none';\n//-->\n</script>\n"
	: '' ;
}

=head1 CSS STYLE CLASS EMPLOYED

You can add CSS to be output into the page body (ugh) in the C<mycss> field.
Bear in mind that the width and height settings are programatically assigned.

=item pblib_bar

A C<DIV> containing the whole progress bar, including any
accessories (such as the label). The only attribute used
by this module is C<width>, which is set dynamically.
The rest is up to you. A good start is:

	padding:    2 px;
	border:     solid black 1px;
	text-align: center;

=item pblib_block_off, pblib_block_on

An individual block within the status bar. The following
attributes are set dynamically: C<width>, C<height>,
C<margin-right>.

=item pblib_number

Formatting for the C<label> text (part of which is actually
an C<input type='text'> element. C<border> and C<text-align>
are used here, and the whole appears centred within a C<table>.

=cut

sub CGI::_pb_init {
	my ($self, @crud) = CGI::self_or_default;
	my $html = "";
	# my $pb = $self->{progress_bar}[$#{$self->{progress_bar}}];
	$self->{progress_bar}->{block_wi} = 1 if not $self->{progress_bar}->{block_wi} or $self->{progress_bar}->{block_wi} < 1 ;

	$self->{progress_bar}->{layer_id} = {
		container	=> 'pb_cont'.time,
		form		=> 'pb_form'.time,
		block		=> 'b'.time,
		number		=> 'n'.time,
	};
	$self->CGI::_init_css;
	$html .= "<style type='text/css'>".$self->{progress_bar}->{css}."\n".$self->{progress_bar}->{mycss}."</style>\n";
	$html .= "\n<!-- begin progress bar $self->{progress_bar}->{layer_id}->{container} -->" if $^W;
	$html .= "\n<div id='$self->{progress_bar}->{layer_id}->{container}'>\n";
	$html .= "\t<table>\n\t<tr><td><table align='center'><tr><td>" if $self->{progress_bar}->{label};

	$html .= "\t<div class='pblib_bar'>\n\t";
	foreach my $i (1 .. $self->{progress_bar}->{blocks}){
		$html .= "<span class='pblib_block_off' id='$self->{progress_bar}->{layer_id}->{block}$i'>&nbsp;</span>";
	}
	$html .= "\n\t</div>\n";
	$html .= "</td></tr>\n<tr><td align='center'>
		<form name='$self->{progress_bar}->{layer_id}->{form}' action='noneEver'>
			<input name='$self->{progress_bar}->{layer_id}->{number}' type='text' size='6' value='0' class='pblib_number'
			/><span class='pblib_number'> / $self->{progress_bar}->{to}</span>
		</form>
		</td></tr></table>
		</td></tr></table>" if $self->{progress_bar}->{label};
	$html .= "</div>\n";
	$html .="<!-- end progress bar $self->{progress_bar}->{layer_id}->{container} -->\n\n" if $^W;
	$html .= "\n<script language='javascript' type='text/javascript'>\n// <!--";
	$html .= "\t progress bar produced by ".__PACKAGE__." at ".scalar(localtime)."\n" if $^W;
	$html .= "
	var pblib_at = $self->{progress_bar}->{from};
	pblib_progress_clear();
	function pblib_progress_clear() {
		for (var i = 1; i <= $self->{progress_bar}->{blocks}; i++)
			document.getElementById('$self->{progress_bar}->{layer_id}->{block}'+i).className='pblib_block_off';
		pblib_at = ".($self->{progress_bar}->{from}).";
	}
	function pblib_progress_update() {
		pblib_at += $self->{progress_bar}->{_interval};
		if (pblib_at > $self->{progress_bar}->{blocks}){
			pblib_progress_clear();
		} else {
			for (var i = 1; i <= Math.ceil(pblib_at); i++){
				document.getElementById('$self->{progress_bar}->{layer_id}->{block}'+i).className='pblib_block_on';
			}\n";
	$html .= "document.".$self->{progress_bar}->{layer_id}->{form}.".".$self->{progress_bar}->{layer_id}->{number}.".value++\n" if $self->{progress_bar}->{label};
	$html .= "}\n//-->\n</script>\n";

	return $html;
}

sub CGI::_init_css {
	my ($self, @crud) = CGI::self_or_default;
	$CSS = "
	.pblib_bar {
		border: 1px solid black;
		padding:    1px;
		background: white;
		display: block;
		text-align:left;
		width: ".($self->{progress_bar}->{width})."px;
	}
	.pblib_block_on,
	.pblib_block_off {
		display: block;
	".( $self->{progress_bar}->{orientation} eq 'vertical'?
		"float:none;
		 width: 100%;
		 height: ".($self->{progress_bar}->{block_wi})."px;"
	  : "float:left;
	     width: ".($self->{progress_bar}->{block_wi})."px;"
	)."
	}
	.pblib_block_off { border:1px solid white; background: white; }
	.pblib_block_on  { border:1px solid blue;  background: navy; }
	";
	if ($self->{progress_bar}->{label}){
		$CSS .=".pblib_number {
		text-align: right;
		border: 1px solid transparent;
		}";
	}
	$self->{progress_bar}->{css} = $CSS;
}

=head1 BUGS, CAVEATS, TODO

=over 4

=item One bar per page

This may change.

=item Parameter passing doesn't match F<CGI.pm>

But it will in the next release if you ask me for it.

=item C<colors> not implimented

I'd like to see here something like the C<Tk::ProgressBar::colors>;
not because I've ever used it, but because it might be cool.

=item Horizontal orientation only

You can get around this by adjusting the CSS, but you'd rather not.
And even if you did, the use of C<-label> might not look very nice
unless you did something quite fancy. So the next version (or so)
will support an C<-orientation> option.

=item Inline CSS and JS

Because it's easiest for me. I suppose some kind of over-loading of
the C<CGI::start_html> would be possible, but then I'd have to check
it, and maybe update it, every time F<CGI.pm> was updated, which I
don't fancy.

=cut

1;
__END__

=head1 CGI UPLOAD HOOK

I'm not convinced it works yet, even in F<CGI.pm> verion 3.15.

If anyone knows otherwise, please mail me: I have spent an hour
on the below, and it seems that the hook is called more times
than necessary....

=head2 PROCESS

The script has to both upload and process a file.

The hook script is called when the object is constructed,
thus before any headers can be output. There the hook needs
to output its own headers, and we only output headers for
the 'select file' page when the hook has not been called.

The first tiem the hook is called, then, it outputs HTTP
headers and begins the page. This is fine.

The next time it is called, it outputs the JS call to
update the progress bar. This is fine.

The problem is that the hook seems to be called many more
times than necessary.

=back

=head2 SOURCE

	#!/usr/local/bin/perl
	use warnings;
	use strict;

	use CGI::ProgressBar qw/:standard/;
	$| = 1;	# Do not buffer output

	my $data;
	my $hook_called;
	my $cgi = CGI->new(\&bar_hook, $data);

	if (not $hook_called){
		print $cgi->header,
		$cgi->start_html( -title=>'A Simple Example', ),
		$cgi->h1('Simple Upload-hook Example');
	}

	print $cgi->start_form( -enctype=>'application/x-www-form-urlencoded'),
		$cgi->filefield( 'uploaded_file'),
		$cgi->submit,
		$cgi->end_form,p;

	if ($cgi->param('uploaded_file')){
		print 'uploaded_file: '.param('uploaded_file');
	}


	sub bar_hook {
		my ($filename, $buffer, $bytes, $data) = @_;
		if (not $hook_called){
			print header,
			start_html( -title=>'Simple Upload-hook Example', ),
			h1('Uploading'),
			p(
				"Have to read <var>$ENV{CONTENT_LENGTH}</var> in blocks of <var>$bytes</var>, total blocks should be ",
				($ENV{CONTENT_LENGTH}/$bytes)
			),
			progress_bar( -from=>1, -to=>($ENV{CONTENT_LENGTH}/$bytes), -debug=>1 );
			$hook_called = 1;
		} else {
			# Called every $bytes, I would have thought.
			# But calls seem to go on much longer than $ENV{CONTENT_LENGTH} led me to believe they ought:
			print update_progress_bar;
			print "$ENV{CONTENT_LENGTH} ... $total_bytes ... $hook_called ... div="
			.($hook_called/$total_bytes)
			."<br>"
		}
		sleep 1;
		$hook_called += $total_bytes;
	}

	print $cgi->hide_progress_bar;
	if ($hook_called){
		print p('All done after '.$hook_called.' calls');
	}
	print $cgi->end_html;
	exit;




=head1 AUTHOR

Lee Goddard C<lgoddard -in- cpan -dat- org>, C<cpan -ut- leegoddard -dut- net>

=head2 COPYRIGHT

Copyright (C) Lee Goddard, 2002, 2003, 2005. All Rights Reserved.
This software is made available under the same terms as Perl
itself. You may use and redistribute this software under the
same terms as Perl itself.

=head1 KEYWORDS

HTML, CGI, progress bar, widget

=head1 SEE ALSO

L<perl>. L<CGI>, L<Tk::ProgressBar>,

=head1 MODIFICATIONS

25 March 2004: Updated the POD.^

16 December 2005: Updated the styles and POD. Removed I<gap> attribute.

16 December 2005: Updated the default styles.

30 November 2010: Updated with patch from I<tlhackque> - thank you.


=cut
