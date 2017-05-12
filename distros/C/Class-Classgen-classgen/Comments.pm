# This package assists in handling comments from the control file
# of classgen
#
# Michael Schlueter 5.3.2000		3.00


# 3.03:
#	No changes in here				02.10.2000

# 3.02:
#	No changes in here				06.07.2000

# 3.01:
#	removed an error from just_var. this error suppressed most of
#	the information in the header: section.		19.5.2000

package Class::Classgen::Comments;

$VERSION=3.03;

	use strict;

sub find {		# to find the comments in a line
	my ($line) = @_;

	$line=~m/(^[^#]*)(.*)/;
	return ( $1, $2 );	# $1 source text, $2 comments
}

sub repair_header {	# to put in missing ';' in the header section
	my (@code) = @_;	# the code edited into the header section
	my @code2;

	shift @code;			# remove fragment
	foreach (@code) {
#		next if( $_=~m/:/);	# this is an identifier for the sect.
		unless ( $_=~m/;/ ) {	# then find insertion point
			if($_=~m/#/){	# case where comment is present
				$_=m/(^.*)(\s*)#(.*)/;
				push @code2, ($1 . $2 . ";#$3\n");
			}else{		# case without comment
				chomp;
				push @code2, ($_ . ";\n");
			}
		} else {		# case with ; and eventually comment
			push @code2, $_;	# use original code
		}
	}
	return @code2;
}

sub just_comments {		# to extract just the comments themselves
	my ($line) = @_;	# some line of code

	$line =~ m/.*(#.*)/;
	if($1){ return $1; } else { return ''; };
}

sub just_var {			# to extract just the variable itself
	my ($var) = @_;		# the variable plus eventualy comments

	$var =~ m/([\$\%\@]\w+)/;
#	if($1){ return $1; } else { return ''; };	# 3.00 error !
	if($1){ return $1; } else { return $var; };	# 3.01
}


1;

__END__

=head1 NAME 

Comments.pm - To keep some nasty errors from users of classgen.


=head1 VERSION

3.03

=head1 SYNOPSIS

Used within classgen.

=head1 DESCRIPTION

Comments.pm checks for missing ';' in the header section. Missing ';' will allow to run classgen smoothly but lateron perl will complain about this error. Those anoying problems should be kept from the user.

It turned out to be useful to add some elucidating comments after variables in the variables-section. This increases self-documentation of the source code and better documents intentions. Variables are simply listed in the variables section. But user may tend to put a syntactically ';' or ',' after each variable. Again, classgen would run smoothly but give nasty error messages lateron from perl. All these anoying problems should be kept from the user.



=head1 ENVIRONMENT

Nothing special. Just use perl5.


=head1 DIAGNOSTICS

There is no special diagnostics. New.pm is used within classgen which is called with the B<-w> option.


=head1 BUGS

No bugs known.


=head1 FILES

Please refer to classgen.


=head1 SEE ALSO

perldoc classgen



=head1 AUTHOR

Name:  Michael Schlueter
email: mschlue@cpan.org

=head1 COPYRIGHT

Copyright (c) 2000, Michael Schlueter. All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
