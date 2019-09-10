

# CommentToPod
# Generate valid Pod header for packages and functions with
# preceeding comments, like this. (see the source for this file. CommentToPod.pm)

package App::CommentToPod;
$App::CommentToPod::VERSION = '0.002';
# ABSTRACT: Turns comment above functions to pod.

use strict;
use warnings;

use Class::Tiny qw(), {
	podfile => "",
	package => "",
	mock_empty => 0,
};


sub addPod {
	my $self = shift;
	my $file = shift;

	my @lines = split(/\n/, $file);

	my $c = 0;

	if (!$self->gotpod(\@lines)) {
		## add POD header
		$self->printpod(\@lines);
	}

	while ($c < scalar(@lines)) {
		if (!$self->package && $lines[$c] =~ /^package/) {
			$self->{package} = ($lines[$c] =~ m/package\ ([\w\:]+)/)[0]
		}
		$self->checkForComment(\@lines, \$c);
		$self->{podfile} .= $lines[$c] . "\n";

		$c++;
	}

	return 1;
}


sub gotpod {
	my $self  = shift;
	my $lines = shift;

	foreach my $l (@$lines) {
		if ($l =~ m/^=pod/) {
			return 1;
		}
	}
	return 0;
}


sub printpod {
	my $self  = shift;
	my $lines = shift;

	my $comment = "";
	my $c       = 0;
	while ($self->lineIsCommentOrBlank($lines->[$c])) {
		my $l = $lines->[$c];
		$l =~ s/^#/    /g;
		$comment .= $l . "\n";
		$c++;
		last if $c > scalar(@$lines);
	}

	if ($lines->[$c] !~ /^package/) {
		$self->{podfile} .= $comment;
		return 0;
	}

	my $package = ($lines->[$c] =~ m/package\ ([\w\:]+)/)[0];
	$self->package($package);

	my $podheader = "";
	$podheader .= "=pod\n\n";
	$podheader .= "=encoding utf8\n\n";
	$podheader .= "=head1 NAME\n\n";
	$podheader .= "$package\n\n";
	$podheader .= "=head1 SYNOPSIS\n\n";
	$podheader .= "$comment\n\n";
	$podheader .= "=cut\n\n";

	$podheader .= "=head2 Methods\n\n";
	$podheader .= "=cut\n\n";

	$self->{podfile} .= $podheader;

}

sub checkForComment {
	my $self  = shift;
	my $lines = shift;
	my $c     = shift;

	if ($self->lineIsComment($lines->[$$c])) {
		$self->commentAboveSub($lines, $c);
		return;
	}

	# if mock_empty is enabled, generate a pod stub above
	# undocumented functions
	if ($self->mock_empty && $lines->[$$c] =~ m/^sub/){
		my $fname = ($lines->[$$c] =~ m/sub\ (\w+)/)[0];
		my $comment = "$fname(...) // not documented\n\n";
		for(0 .. 1){
			$comment .= "   " . $lines->[$$c+$_] . "\n";
		}
		$comment .= "   " . "...\n";
		$self->commentToPod(  $comment, $fname);
	}
}

sub commentAboveSub {
	my $self  = shift;
	my $lines = shift;
	my $c     = shift;

	my $comment = "";
	while ($self->lineIsComment($lines->[$$c])) {
		$comment .= $lines->[$$c] . "\n";
		$$c++;
	}

	if ($lines->[$$c] !~ /^sub/) {
		$self->{podfile} .= $comment . "\n";
		return 0;
	}

	my $fname = ($lines->[$$c] =~ m/sub\ (\w+)/)[0];

	$self->commentToPod($comment, $fname);

	return 1;
}

sub lineIsComment {
	my $self = shift;
	my $l    = shift;
	return $l =~ m/^#/;
}

sub lineIsBlank {
	my $self = shift;
	my $l    = shift;
	return $l eq '';
}

sub lineIsCommentOrBlank {
	my $self = shift;
	my $l    = shift;
	return 1 if $self->lineIsBlank($l);
	return $self->lineIsComment($l);
}


sub commentToPod {
	my $self         = shift;
	my $comment      = shift;
	my $functionName = shift;

	my $podcomment = "";
	$podcomment .= "=over 12\n\n";
	$podcomment .= "=item C<$functionName>\n\n";
	foreach my $l (split(/\n/, $comment)) {
		$l =~ s/^#\s?//g;
		$podcomment .= $l . "\n";
	}
	$podcomment .= "\n=back\n\n=cut\n\n";
	$self->{podfile} .= $podcomment;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CommentToPod - Turns comment above functions to pod.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

     CommentToPod
     Generate valid Pod header for packages and functions with
     preceeding comments, like this. (see the source for this file. CommentToPod.pm)

=head2 Methods

=over 12

=item C<addPod>

Comments like this, over functions is I<rendered> to B<pod>, via
L<App::CommentToPod>. Pod syntax is valid, example:

   This is a code block
   as seen in paragraph over, you could add some pod trics like
   I<rendered> to B<pod>, via L<App::CommentToPod>

=back

=over 12

=item C<gotpod>

check if file got any pod section

=back

=over 12

=item C<printpod>

print pod header.

=back

=over 12

=item C<commentToPod>

commentToPod($comment, $functionName) turns a comment into a pod block.

=back

=head1 NAME

App::CommentToPod

=head1 AUTHOR

Kjell Kvinge <kjell@kvinge.biz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Kjell Kvinge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
