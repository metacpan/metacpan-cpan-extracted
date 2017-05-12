package Data::SCORM;

use Any::Moose;
use Any::Moose qw/ ::Util::TypeConstraints /;
use Data::SCORM::Manifest;
use File::Temp qw/ tempdir /;
use Path::Class::Dir;
use IPC::Run qw/ run /;

use Data::Dumper;

=head1 NAME

Data::SCORM - Parse SCO files (PIFs)

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

see Data::SCORM::Manifest

=cut

has 'manifest' => (
	is        => 'rw',
	isa       => 'Data::SCORM::Manifest',
	);

subtype 'PathClassDir'
	=> as 'Path::Class::Dir';

coerce 'PathClassDir'
	=> from 'Str'
		=> via { Path::Class::Dir->new($_) };

has 'path' => (
	is        => 'rw',
	isa       => 'PathClassDir',
	coerce    => 1,
	);

sub extract_from_pif {
	my ($class, $pif, $path) = @_;
	
	$path ||= tempdir; # no cleanup?, as caller may want to rename etc.
	
    my $status = unzip ($pif, $path);
    die "Couldn't extract pif $pif, $status"
        if $status;

	return $class->from_dir($path);
}

sub unzip {
    # Archive::Extract, Archive::Zip would arguably be the Right Thing
    # to do here.  But we have to handle some corrupt archives, e.g. without
    # an EOCF (End of Central Directory) number.
    # so we'll use unzip for now.

    my ($pif, $path) = @_;
    my $status = run 
        [ unzip => $pif,
           -d => $path ], '>', '/dev/null';

    my $ok = $status ?
        ($status ~~ [1, 1<<8] ? 1 : 0) # oddity of unzip 'warning' status
        : 1;

    if ($ok) {
        return;
    } else {
        $status >>= 8; # oddity of 'system'
        die "unzip(1) encountered warning/error $status";
        return $status;
    }
}

sub from_dir {
	my ($class, $path) = @_;
	$path = Path::Class::Dir->new($path);
	my $manifest = $path->file( 'imsmanifest.xml' );
	if ($manifest->stat) { # if it exists
		return $class->new(
			path     => $path,
			manifest => Data::SCORM::Manifest->parsefile($manifest),
		  );
	} else {
        # may be a single directory
        my @subdirectories = 
            grep { 
                my $name = ($_->dir_list)[-1];
                $name !~/^__/ 
            } # e.g. __MACOSX
            grep $_->is_dir, 
            $path->children;
        if (@subdirectories == 1) {
            return $class->from_dir( $subdirectories[0] );
        }
        die "Invalid zip (must contain exactly 1 directory)";
	}
}

# __PACKAGE__->make_immutable;
no Any::Moose;

=head1 AUTHOR

osfameron, C<< <osfameron at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-scorm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SCORM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SCORM

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SCORM>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SCORM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 OSFAMERON.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::SCORM
