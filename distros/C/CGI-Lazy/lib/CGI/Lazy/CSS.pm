package CGI::Lazy::CSS;

use strict;

use CGI::Lazy::Globals;

#-------------------------------------------------------------------------------------------------
sub dir {
	my $self = shift;

	return $self->{_dir};
}

#----------------------------------------------------------------------------------------
sub file {
	my $self = shift;
	my $file = shift;

	my $dir = $self->dir;

	return "$dir/$file";
}

#----------------------------------------------------------------------------------------
sub load {
	my $self = shift;
	my $file = shift;
	
	my $dir = $self->dir;
	$dir =~ s/^\///; #strip a leading slash so we don't double it
	my $docroot = $ENV{DOCUMENT_ROOT};
	$docroot =~ s/\/$//; #strip the trailing slash so we don't double it

	open IF, "< $docroot/$dir/$file" or $self->q->errorHandler->couldntOpenCssFile($docroot, $dir, $file, $!);

	my $script;

	$script .= $_ while <IF>;

	close IF;

	return $self->q->csswrap($script);

}

#-------------------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	return bless {
		_q 		=> $q,
		_dir		=> $q->config->cssDir,
	
	}, $class;
}

#-------------------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================
=head1 NAME

CGI::Lazy::CSS

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new();


	print $q->header,

	      $q->css->load('somefile.css');


=head2 DESCRIPTION

CGI::Lazy::CSS is just a convience module for accessing css files.

=head1 METHODS

=head2 dir ()

Returns directory containing css specified at lazy object creation

=head2 file (css)

Returns absolute path to file css parsed with document root and css directory

=head3 css

Css file name

=head2 load (file)

Reads file from css directory , wraps in script tags for output to browser

=head3 file

filename of cssfile

=head2 new ( q )

constructor.

=head3 q

CGI::Lazy object

=cut

