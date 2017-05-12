#!/usr/local/bin/perl

package CGI::Thin;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION = 0.52;
	@ISA		= qw (Exporter);
	@EXPORT		= qw (&Parse_CGI);
	@EXPORT_OK	= qw (&Force_Array);
}

########################################### main pod documentation begin ##

=head1 NAME

CGI::Thin - A very lightweight Parser for CGI Forms

=head1 SYNOPSIS

C<use CGI::Thin;>

C<my %cgi_data = &Parse_CGI ();>

=head1 DESCRIPTION

This module is a very lightweight parser of CGI forms.  And it has a 
special feature that it will return an array if the same key is used
twice in the form.  You can force an array even if only one value returned
to avoid complications.

The hash %cgi_data will have all the form data from either a POST or GET form
and will also work for "multipart/form-data" forms necessary for uploading files.

=head1 USAGE

  Functions

    * `CGI::Thin::Parse_CGI(@keys)'
        The optional @keys will be used to force arrays to be returned.

        The function also has special features for getting multiple values for a
        single form key.  For example if we have this form...

          <input type="checkbox" name="color" value="red">red
          <input type="checkbox" name="color" value="green">green
          <input type="checkbox" name="color" value="blue">blue

        One of three things can happen.

        1)  The user does not select any color.
            So $cgi_data{'color'} will not exist.
        2)  The user selects exactly one color.
            So $cgi_data{'color'} will be the scalar value selected.
        3)  The user selects exactly more than one color.
            So $cgi_data{'color'} will be a reference to an array of the values selected.

        To fix this you could call the parser by giving it a list of keys that you want
        to force to be arrays.  In this case like...

          use CGI::Thin;
          my %cgi_data = &Parse_CGI ('color');

        Now it they pick exactly one color, $cgi_data{'color'} will be a reference to
        an array of the one value selected.  And thus there will be no need for
        special cases later in the code.

=head1 BUGS

=head2 Fixed

=over 4

=item *

Added %([0-9a-fA-F]{2} to the regular expression to avoid illegal escapes

=item *

Now split the key/value pairs by [;&] not just the ampersand

=back

=head2 Pending

=over 4

=item *

Long headers lines that have been broken over multiple lines in
multipart/form-data don't seem to be handled.

=item *

Large file uploads (like 150MB) will clobber main memory.  One possible addition is
to change how multipart/form-data is read and to spit files directly to the temp directory
and return to the script a filename so it can be retreived from there.

=item *

Any thoughts on adapting it for use withing a mod_perl environment?

Under Apache::Registry, which emulates a CGI environmnet, it should be.
Under plain ol' mod_perl, we need to interact with the
Apache::Request class a bit instead of %ENV and STDIN.

This feature may be added in the next incarnation of the module, or possibly a companion
CGI::Thin::Mod_Perlish may be created to do it if the code will be too different.

=back

=head1 SEE ALSO

CGI::Thin::Cookies

=head1 SUPPORT

    Visit CGI::Thin's web site at
        http://www.PlatypiVentures.com/perl/modules/cgi_thin.shtml
    Send email to
        mailto:cgi_thin@PlatypiVentures.com

=head1 AUTHOR

    R. Geoffrey Avery
    CPAN ID: RGEOFFREY
    modules@PlatypiVentures.com
    http://www.PlatypiVentures.com/perl

=head1 COPYRIGHT

This module is free software, you may redistribute it or modify in under the same terms as Perl itself.

=cut

############################################# main pod documentation end ##

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Parse_CGI
{
	my %hash = ();

	foreach my $entry (split(/[&;]/, $ENV{'QUERY_STRING'})) {
		&Insert_Item (\%hash, &Divide_Item ($entry));
	}

	if ((defined $ENV{'CONTENT_TYPE'}) && ($ENV{'CONTENT_TYPE'} =~ m|multipart/form-data|si)) {
		my $in;
		read(STDIN, $in, $ENV{'CONTENT_LENGTH'});

		### Find the field "boundary" string.
		my $boundary = substr($in, 0, index($in, "\r\n") - 1);
		### Tokenize the input.
		my @args = split(/\s*$boundary\s*/s, $in);
		### remove extra pieces before first and after last boundary
		shift @args;
		pop @args;

		foreach my $entry (@args) {
			# Split the token into header and content
			my ($head, $item) = split(/\r\n\r\n/ios, $entry, 2);

			# ... name="CGI_FILE" filename="myfile.txt" ....
			# so this is a bit of a trick, based on the double
			# occurence of 'name'.
			my ($name, $file) = ($head =~ /name="(.*?)"/gios);

			my $mimetype;
			if ($head =~ /Content-type:\s*(\S+)/gios) {
				$mimetype = $1;
			}

			### Build a hash for the file if a filename was specified
			$item = {
						"Name"		=> $file,
						"Content"	=> $item,
						"MIME_Type"	=> $mimetype || 'unknown mime type',
						"head"		=> $head,
					} if ($file);

			&Insert_Item (\%hash, $name, $item);

		} # foreach
							  
	} elsif( $ENV{'REQUEST_METHOD'} eq "POST" ){
		my $in;
		read(STDIN, $in, $ENV{'CONTENT_LENGTH'});
		
		foreach my $entry (split(/[&;]/, $in)) {
			&Insert_Item (\%hash, &Divide_Item ($entry));
		}
	}

	foreach (@_) {
		$hash{$_} = &Force_Array ($hash{$_}) if ($hash{$_});
	}

	return (%hash);

}

################################################ subroutine header begin ##
# Convert plus's to spaces
# Convert %XX from hex numbers to alphanumeric
# Return key and value
################################################## subroutine header end ##

sub Divide_Item
{
	my ($item) = @_;

	$item =~ tr/+/ /;
	my ($key, $value) = split ("=", $item, 2);
	$key   =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;
	$value =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;
	return ($key, $value);
}


################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Insert_Item
{
	my ($p_hash, $key, $val) = @_;

	if ( defined($p_hash->{$key})) {
		unless (ref ($p_hash->{$key}) eq "ARRAY") {
			my $firstval = $p_hash->{$key};
			$p_hash->{$key} = [$firstval];
		}
		push (@{$p_hash->{$key}}, $val);
	} else {
		$p_hash->{$key} = $val;
	}
}

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Force_Array
{
	my ($item) = @_;

	$item = [$item] unless( ref($item) eq "ARRAY" );

	return ($item);
}

###########################################################################
###########################################################################

1;

__END__

