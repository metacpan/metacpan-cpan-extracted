package Apache::Blog::Entry;
use File::Basename;
use Apache::File;
use Date::Manip;
use POSIX ();

use strict;

BEGIN {
	# this comes from Date::Manip. don't know if it should be in the
	# public version. it should probably be a configuration option
	&Date_Init("TZ=BST");
}

# we have a class that represents an entry. then we can call methods
# like $entry->title and $entry->date in the main Apache::Blog class and
# not have to worry about the content of text files there.
sub new {
	my ($class, $filename) = @_;

	my $fh = Apache::File->new( $filename );

	# first line is the short name
	my $short_name = <$fh>;

	# second line is the date
	my $date = <$fh>;

	# the rest is the entry
	my $entry;
	{ local $/=undef;
	  $entry = <$fh>;
	};

	# get the unixtime of the entry too (%s is the Date::Manip way
	# of saying "seconds since the epoch")
	my $unixtime = Date::Manip::UnixDate($date ,'%s');

	# and fix up the date
	$date = POSIX::strftime( '%a %d %b %y %H:%M', localtime $unixtime );

	# see if we can get any comments
	my $comments_ref = [];
	if (-d "$filename-comment") {
		my @comments = Apache::Blog::Entry->get_all( "$filename-comment" );
		$comments_ref = \@comments;
	} # end comment if


	# store those results (wonder if there's a better way to count
	# words than scalar( @{[split /\s+/, $entry]} )
	my %self = (  date => $date,
		      unixtime => $unixtime,
		      entry => $entry,
		      short_name => $short_name,
		      filepath => $filename,
		      filename => basename( $filename ),
	              wc => scalar( @{[split /\s+/, $entry]} ), 
		      comments => $comments_ref,
		   );

	return bless(\%self, $class);
} # end new

sub date { return shift->{date} };
sub unixtime { return shift->{unixtime} };
sub short_name { return shift->{short_name} };
sub filename { return shift->{filename} };
sub filepath { return shift->{filepath} };
sub wc { return shift->{wc} };
sub comments { return @{ shift->{comments} } };

# does simple html-formatting of the plain text
sub entry {
	my $self = shift;

	my $text = $self->{'entry'};

        # make UL lists work (perhaps)
	# there's bound to be a better way of doing this
        $text =~ s/^(\s*)\* (.*)$/$1<li>$2<\/li>/mg;
        if ($text =~ /<li>/) {
                $text =~ s/<li>/<ul><li>/;
                $text = reverse $text;
                $text =~ s/>il\/</>lu\/<>il\/</;
                $text = reverse $text;
        } # end it
 
        # bold?
        $text =~ s/\*([^*]+)\*/<b>$1<\/b>/g;	

	# blank lines -> <p>
	$text =~ s/^\s*$/\n<p>\n/mg;

	return $text;

} # end entry

# gets all of the entries in a directory
sub get_all {
	my ($class, $dir) = @_;

	# get all of the details of all of the entries
	opendir DIR, $dir;
	my @entries = map { Apache::Blog::Entry->new( $dir."/".$_ ) }
	              grep !/\.html$/ && !/^\./ && !(-d $dir."/".$_), readdir DIR;
	closedir DIR;

	# now sort those
	my @out_entries;
	foreach my $entry (sort { $b->unixtime <=> $a->unixtime } @entries) {
		push @out_entries, $entry;
	} # end foreach

	return @out_entries;
} # end get_all



package Apache::Blog;

use strict;

use vars qw( $VERSION );
$VERSION = '0.03';

use Apache::Constants; # qw(:common);
use Apache::Request;
use HTML::Template;
use File::Basename;

use strict;

# this pretty much just dispatches the request to a different handler,
# depending on what's actually been requested.
sub handler {
	my $r = shift;

	return &handle_comment($r) if ($r->filename =~ /post-comment$/ );
	return &handle_older($r) if ( $r->filename =~ /older\.html$/ );
	if (-d $r->filename) {
		# they've just asked for the directory - need to send newest entry
		my @entries = Apache::Blog::Entry->get_all( $r->filename );
		my $latest = $entries[0];

		$r->filename( $latest->filepath );
	}

	return handle_file($r);

	return DECLINED;

} # end handler

# we do this if it's an entry we want to show
sub handle_file {
	my $r = shift;

	my $dir = dirname( $r->filename );

	my $template = $dir."/entry-template.html";

	# return declined if the entry template doesn't exist
	if (!-e $template) {
		return DECLINED;
	} # end if

	$template = HTML::Template->new( filename => $template, die_on_bad_params => 0 );

	my $entry = Apache::Blog::Entry->new( $r->filename );

	# this is cheating, and breaking OO encapsulation, but i think
	# it's fair enough in this case.
	$template->param( %$entry );
	# entry is the only method that actually does something, rather
	# than doing "return shift->{'whatever'}", so we need explicitly
	# run it.
	$template->param( entry => $entry->entry);

	# need to find the next and previous entries too
	my @all = Apache::Blog::Entry->get_all( dirname($r->filename) );
	
	# this looks like an overly complicated way of finding out the
	# index in @all (which was got in the last line) of this entry
	# is. we do that so we can tell what the one after it, and the
	# one before it are, so we can have links to them.
	my $this_index = 0;
	$this_index++ while (defined($all[$this_index]) && $all[ $this_index ]->filename ne $entry->filename);
	
	# previous
	if (defined($all[$this_index+1])){
		$template->param( prev => $all[$this_index+1]->filename );
	} else {
		$template->param( prev => $entry->filename );
	} #end previous

	# next
	if ($this_index == 0) {
		$template->param( next => $entry->filename );
	} else {
		$template->param( next => $all[$this_index-1]->filename );
	} # end next

	# make the clever comments thing work
	my @out_comments;
	foreach my $comment ($entry->comments) {
		push @out_comments, { who => $comment->short_name,
		                      date => $comment->date,
		                      entry => $comment->entry,
		                    };
	} # end foreach

	$template->param( comments => \@out_comments );

	$r->content_type( 'text/html' );
	$r->send_http_header;
	$r->print( $template->output );

	return OK;
} # end handle_file

sub handle_older {
	my $r = shift;

	# display all the entries

	# is there a template?
	my $template = dirname($r->filename)."/older.html";

	if (!-e $template) {
		return DECLINED;
	} # end if

	$template = HTML::Template->new( filename => $template, die_on_bad_params=>0 );


	my @out_entries = Apache::Blog::Entry->get_all( dirname($r->filename) );

	$template->param( older_entries => \@out_entries );

	my $total_words = 0;
	$total_words += $_->wc for @out_entries;

	$template->param( total_words => $total_words );
	

	$r->content_type( 'text/html' );
	$r->send_http_header;
	$r->print( $template->output );
	
	
	return OK;
} # end handle_directory

sub handle_comment {
	my $r = shift;
	my $apr = Apache::Request->new($r);

	my $name = $apr->param('name');
	my $comment = $apr->param('comment');
	my $filename = $apr->param('filename');

	# if the comment directory doesn't exist, we should create it
	my $comment_dir = dirname($r->filename)."/$filename-comment";
	if (!-d $comment_dir) {
		# looks like perl 5.6.1 doesn't need the permissions bit
		# on mkdir, but perl 5.005_03 does. great fun when your
		# perl -c is 5.6.1, but your mod_perl is 5.005_03.
		# perhaps this should tell me something about my
		# development environment. perhaps i shouldn't be so
		# liberal here with the permissions either.
		unless (mkdir($comment_dir, 0755)) {
			$r->log_reason("Can't create $comment_dir: $!");
			return SERVER_ERROR;
		} # end mkdir
	} # end no directory

	# need a filename. we start at 1 and move upwards. there's
	# almost certainly a race condition here, but this is written
	# for my site where i get about one comment a week. if yours is
	# so busy you're worried about this breaking, then feel free to
	# fix it.
	my @existing_files = glob("$comment_dir/*");
	my $new_basename = scalar(@existing_files) + 1;

	open (COMMENT, ">$comment_dir/$new_basename");
	print COMMENT "$name\n";
	print COMMENT scalar(localtime)."\n";
	print COMMENT $comment;
	close COMMENT;

	# not quite sure what this will do if the user is being a bitch
	# and have proxied away the referer header. this could be
	# construed as a bug.
	$r->header_out( 'Location' => $r->header_in( 'Referer' ));

	return 302;
} # end handle_comment


1;

__END__

=head1 NAME

Apache::Blog - mod_perl weblog handler

=head1 SYNOPSIS

In httpd.conf

  Alias /blog/ /home/daniel/blog/
  <Location /blog>
    SetHandler perl-script
    PerlHandler +Apache::Blog
  </Location>

=head1 DESCRIPTION

Apache::Blog is a simple handler for online diaries. At the moment it
works on the one-entry-one-page paradigm, but would be easy to apapt to
multiple entries per page if this is prefered. In the future this will
be a configuration option.

It is inspired by the service offered at http://www.diaryland.com/

It uses HTML::Template, so it is easy to design new layouts. There are
some samples included with the distribution.

All diary entries are stored as plain text files, there's no database
stuff going on here. This is to make it simple to add entries - any
editor can be used to write entries.

To use, decide on a directory which is to hold your weblog entries,
and set PerlHandler like in the example. The alias isn't nessasary,
but I like it that way.

Also in that directory need to be two template files, one called
entry-template.html, and one called older.html.

Entries take the format:

  Short Title
  Thu Jun 20 17:24:52 BST 2002

  The entry down here.

The date can be in any format that Date::Manip likes. In vim I do :r!date
to add the date line.

Apache::Blog does some simple manipulation on the text. It will turn
lines which start with a * into bullet lists, and blank lines are turned
into <p> tags. You can also *bold* text. It doesn't highlight links or
anything. A more sophisticated text->html converter may be included in
the future.

The module can also allow comments on entries, for this to work properly
the webserver must have write access to the directory containing your
entries.

Entry filenames can be anything you like, as long as it doesn't end in
.html or start with a period. I generally go with filenames like "2002-06-20"

See the sample layouts, especially the "simple" layout, to see how to
create your own.

Someone should write a blogger -> Apache::Blog template converter, one
for diaryland templates as well. Best way to do that would probably be
an HTML::Template filter so it's transparent. There's a lot of templates
for the different services out there so that's probably a good itch to
get scratched.

=head1 AUTHOR

Daniel Gardner <daniel@danielgardner.org>

=head1 SEE ALSO

HTML::Template, Date::Manip

=cut
