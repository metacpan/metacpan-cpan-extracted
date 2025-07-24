package CPAN::MetaCurator::Util::HTML;

use 5.40.0;
use parent 'CPAN::MetaCurator::Util::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use DateTime::Tiny;

use File::Slurper qw/read_dir read_text/;
use File::Spec;

use Moo;

our $VERSION = '1.00';

# ------------------------------------------------

sub build_html
{
	my($self, $pad)	= @_;
	my($header)		= $self -> load_template('header', $pad);
	my($body)		= $self -> load_template('body', $pad);
	my($footer)		= $self -> load_template('footer', $pad);
	my($now)		= DateTime::Tiny -> now; # (time_zone => $$pad{time_zone});# DateTime::Tiny does not handle time_zone.
	my(%data)		= (domain_name => $$pad{domain_name}, logo_path => $$pad{logo_path}, module => 'CPAN::MetaCurator',
						page_name => $$pad{page_name}, time => $now -> as_string, version => $VERSION);

	for $_ (keys %data)
	{
		$header =~ s/!$_!/$data{$_}/;
	}

	return ($header, $body, $footer);

} # End of build_html.

# ------------------------------------------------

sub load_template
{
	my($self, $name, $pad)	= @_;
	my($header_template)	= File::Spec -> catfile($self -> home_path, "templates/$name.html");

	return read_text($header_template);

} # End of load_template.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
