package CSS::DOM::MediaList;

$VERSION = '0.16';

require CSS::DOM::Array;
@ISA = 'CSS::DOM::Array';

use CSS::DOM::Exception 'NOT_FOUND_ERR';

sub mediaText {
	my $list = shift;
	my $old = join ', ', @$list unless not defined wantarray;
	if (@_) {
		# This parser is based on the description in the HTML spec.
		@$list = map   /^\p{IsSpacePerl}*([A-Za-z0-9-]*)/,
		         split /,/, shift;
	}
	$old
}

sub deleteMedium {
	my ($list, $medium) = @_;
	my $length = @$list;
	@$list = grep $_ ne $medium, @$list;
	@$list == $length and die CSS::DOM::Exception->new(
		NOT_FOUND_ERR,
		qq'The medium "$medium" cannot be found in the list'
	);
	return # nothing;
}

sub appendMedium { # ~~~ If someone passes ‘foo>>@#’ as an argument, are we 
                   #     supposed to truncate it or throw an exception? The
                   #     DOM Style spec. is vague and refers to the ‘under-
                   #     lying style language’.  The HTML spec. has a sec-
                   #     tion on parsing of entire lists. Does that apply
                   #     to this,  or do I have to hunt through the  CSS
                   #     spec. to find that which I seek?
	my ($list ,$medium) = @_;
	@$list = (grep($_ ne $medium, @$list), $medium); 
	return # nothing;
}           

                              !()__END__()!

=head1 NAME

CSS::DOM::MediaList - Medium list class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM;
  $media_list = new CSS::DOM  ->media;

  use CSS::DOM::MediaList;
  $media_list = new MediaList 'screen', 'papyrus';

  @media = @$media_list; # use as array
  $media_list->mediaText; # returns a string
  $media_list->mediaText('print, screen'); # change it
  $media_list->deleteMedium('print');
  $media_list->appendMedium('tv');

=head1 DESCRIPTION

This module implements medium lists for L<CSS::DOM>. It implements the
CSSMediaList DOM interface and inherits from L<CSS::DOM::Array>.

=head1 METHODS

=head2 DOM Attributes

=over 4

=item mediaText

A comma-and-space-separated string of the individual media in the list,
e.g., 'screen, print'.

=back

=head2 DOM Methods

=over 4

=item deleteMedium ( $name )

Deletes the named medium from the list, or throws an error if it cannot
be found.

=item appendMedium ( $name )

Adds a medium to the end of the list.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Array>
