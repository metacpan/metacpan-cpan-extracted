#!/usr/local/bin/perl -p

BEGIN {
	$in_pdf_manual = -1;
#	print "=head1 NAME\n\n";
#	print "CIPP - Reference Manual\n\n";
}

$in_pdf_manual *= -1 if /=for pdf-manual/;
$_ = '' if $in_pdf_manual < 0;

if ( /^[^\s=]/ and not /^B</ ) {
	s!<([^\s].*?)>!C<E<lt>$1E<gt>>!g;
}
