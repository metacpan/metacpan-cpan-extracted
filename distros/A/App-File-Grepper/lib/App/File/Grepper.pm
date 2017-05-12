#! perl

package App::File::Grepper;

use warnings;
use strict;

=head1 NAME

App::File::Grepper - Greps files for pattern

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Runs a File::Find on the specified directories, and greps all text
files for a pattern.

    use App::File::Grepper;
    App::File::Grepper->main( $options, @dirs );

=head1 RATIONALE

There are many tools that can do this, e.g. C<ack>. However none of
these can call an editor when a file matches the search argument and
that is something B<I> often need.

=head1 OPTIONS

The first argument to the main() method is a reference to a hash with
options.

=over 4

=item pattern

The pattern to grep. If it starts with a slash it is interpreted as a
perl pattern. Otherwise it is assumed to be a literal text to grep
for.

If the text does not contain any uppercase letters, matching will be
done case-insensitive unless overridden by option ignorecase.

=item ignorecase

If defined, matching will be case-insensitive according to the value
of ignorecase.

=item edit-with-emacs

Pass each file where the pattern is found to the emacs editor client.

=item edit-with-vi

Pass each file where the pattern is found to the vi editor.

=item view

Pass each file where the pattern is found to the less viewer.

=item filter

A perl pattern to select which files must be processed. Note that this
pattern is applied to the basename of each file, not the full path.

=item exclude

A perl pattern to select which files must be rejected. Note that this
pattern is applied to the basename of each file, not the full path.
Also, this pattern is applied before the filter pattern.

Version control directories C<RCS>, C<CVS>, C<.svn>, C<.git> and
C<.hg> are always excluded.

=back

=cut

use File::Find;
use Term::ANSIColor;

sub main {

    my $self = shift;
    unshift(@_, $self) unless UNIVERSAL::isa( $self, __PACKAGE__ );
    my $opts = shift;
    my @dirs = @_;

    my $pat = $opts->{pattern};
    my $edit = "";
    if ( $opts->{'edit-with-emacs'} ) {
	$edit = 'emacs';
    }
    elsif ( $opts->{'edit-with-vi'} ) {
	$edit = 'vi';
    }
    elsif ( $opts->{'view'} ) {
	$edit = 'less';
    }

    my $ignorecase =
      defined($opts->{ignorecase})
      ? $opts->{ignorecase}
      : $pat !~ /[A-Z]/;

    my $opat = $pat;

    $pat = $pat =~ m;^/(.*); ? qr/$1/ :
      $ignorecase ? qr/\Q$pat\E/i : qr/\Q$pat\E/;

    *hilite = ( !$edit && -t STDOUT )
      ? sub { color('red bold').$_[0].color('reset') }
	: sub { $_[0] };

    my $filter;
    if ( defined $opts->{filter} ) {
	$filter = $opts->{filter};
	$filter = qr/$filter/;
    }
    my $exclude;
    if ( defined $opts->{exclude} ) {
	$exclude = $opts->{exclude};
	$exclude = qr/$exclude/;
    }

    binmode( STDOUT, ":utf8" );

    my $grepper = sub {

	# Prune VC dirs. Always.
	if ( -d $_ && $_ =~ /^(RCS|CVS|\.svn|\.git|\.hg)$/ ) {
	    $File::Find::prune = 1;
	    return;
	}

	# Files only.
	return unless -f $_;

	# Handle include/exclude filters.
	return if $exclude && ( $_ =~ $exclude );
	return if $filter && ( $_ !~ $filter );

	my $file = $_;

	# Okay, we've got one.
	open( my $fh, '<', $file )
	  or warn("$File::Find::name: $!\n"), return;

	unless ( -T $fh ) {
	    warn("[Binary: $File::Find::name]\n") if $opts->{verbose};
	    return;
	}

	binmode( $fh, 'raw' );

	use Encode qw(decode);

	while ( <$fh> ) {

	    eval {
		$_ = decode( 'UTF-8', $_, 1 );
	    }
	    or $_ = decode( 'iso-8859-1', $_ );

	    next unless s/^(.*?)($pat)/"$1".hilite($2)/ge;

	    if ( $edit eq 'vi') {
		system( "vi",
			$ignorecase ? ( "+set ignorecase" ) : (),
			"+/$opat",
			$file );
	    }
	    elsif ( $edit eq 'emacs') {
		system( "emacsclient",
			"+$.:" . (1+length($1)),
			$file );
	    }
	    elsif ( $edit eq 'view') {
		system( "less",
			$ignorecase ? ( "-i" ) : (),
			"+/$opat",
			$file );
	    }
	    last if $edit;

	    print( $File::Find::name, ':',
		   $., ':',
		   1+length($1), ':',
		   $_
		 );
	}

	close($fh);
    };

    find( { wanted => $grepper,
	    no_chdir => 1,
	  }, @dirs );
}

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-file-grepper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-File-Grepper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::File::Grepper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-File-Grepper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-File-Grepper>

=item * Search CPAN

L<http://search.cpan.org/dist/App-File-Grepper>

=back

=head1 ACKNOWLEDGEMENTS

This program was inspired by C<ack> not having a B<-e> option.

=head1 COPYRIGHT & LICENSE

Copyright 2012,2016 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::File::Grepper
