package Database::BI::I18N::en_us;

use strict;
use warnings;

our $VERSION = '0.023.0';

use Readonly;

# American English: the messages, by package, that are spelled differently
# from the British ones in each package's %MESSAGES.  Every other message reads
# the same in both and is not repeated here.  t/i18n.t respells each British
# message with the word list the en-us templates are made from
# (t/lib/BI/Test/EnUS.pm) and fails when this table does not say the same, so
# a new British message that needs an American spelling has to be added here.
Readonly our %MESSAGES => (
	'Database::BI::Controller::Dashboard' => {
		warn_measure_fallback  => 'Measure "%s" on column "%s" is not uniformly numeric; totaled in Perl',
		error_text_card_colour => 'A color must be written #rrggbb',
		error_insights_no_data => 'No data available to analyze',
	},
	'Database::BI::Model::DataSource' => {
		error_backend_init => 'DataSource: failed to initialize database backend for table "%s": %s',
	},
);

1;

__END__

=head1 NAME

Database::BI::I18N::en_us - The application's messages in American English

=head1 VERSION

0.023.0

=head1 DESCRIPTION

C<%Database::BI::I18N::en_us::MESSAGES> maps a package name to the messages of
that package that American English spells differently; L<Database::BI::I18N>
gives every other message in British English, which reads the same.  It is
used when L<CGI::Lingua> finds that the reader wants English (United States).

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
