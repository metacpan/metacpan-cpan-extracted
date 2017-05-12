package App::Slackeria::Plugin::Ikiwiki;

use strict;
use warnings;
use autodie;
use 5.010;

use parent 'App::Slackeria::Plugin';

our $VERSION = '0.12';

sub check {
	my ($self) = @_;

	my $p = $self->{conf}->{name};

	my $re_p = $self->{conf}->{title_name} // $p;

	my $pfile = sprintf( $self->{conf}->{source_file}, $p );
	my $re_title = qr{
		^ \[ \[ \! meta\s title = "
		$re_p (?: \s v (?<version> [0-9.-]+ ))?
		" ]] $
	}x;

	if ( not -e $pfile ) {
		die("No project file\n");
	}
	else {
		open( my $fh, '<', $pfile );
		while ( my $line = <$fh> ) {
			if ( $line =~ $re_title ) {
				return { data => $+{version} // q{}, };
			}
		}
		close($fh);
		die("Wrong name or no title\n");
	}
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin::Ikiwiki - Check if project exists in ikiwiki file

=head1 SYNOPSIS

In F<slackeria/config>

    [Ikiwiki]
    href = http://derf.homelinux.org/projects/%s/
    source_file = /home/derf/web/org.homelinux.derf/in/projects/%s.mdwn

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This plugin checks if a markdown file named after the project exists and if it
has the right C<< [[!meta title ]] >> tag.  It reports the version, if
specified.

=head1 CONFIGURATION

=over

=item href

URL pointing to the rendered project page.  Mandatory

=item source_file

Markdown source file, %s is replaced with the project name.  Mandatory

=back

=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS

The title parser is not really universal.  This plugin may be of little use to
you.

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
