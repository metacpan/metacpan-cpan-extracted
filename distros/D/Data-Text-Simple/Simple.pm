package Data::Text::Simple;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.09 qw(check_number check_required);
use Mo::utils::Language 0.05 qw(check_language_639_1);

our $VERSION = 0.02;

has id => (
	is => 'ro',
);

has lang => (
	is => 'ro',
);

has text => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check id.
	check_number($self, 'id');

	# Check lang.
	check_language_639_1($self, 'lang');

	# Check text.
	check_required($self, 'text');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Text::Simple - Data object for text in language.

=head1 SYNOPSIS

 use Data::Text::Simple;

 my $obj = Data::Text::Simple->new(%params);
 my $id = $obj->id;
 my $lang = $obj->lang;
 my $text = $obj->text;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Text::Simple->new(%params);

Constructor.

=over 8

=item * C<id>

Id of record.
Id could be number.

It's optional.

Default value is undef.

=item * C<lang>

Language ISO 639-1 code.

It's optional.

=item * C<text>

Main text.

It's required.

=back

Returns instance of object.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns number.

=head2 C<lang>

 my $lang = $obj->lang;

Get language ISO 639-1 code.

Returns string.

=head2 C<text>

 my $text = $obj->text;

Get text.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'id' must be a number.
                         Value: %s
                 Parameter 'text' is required.
         From Mo::utils::Language:
                 Parameter 'lang' doesn't contain valid ISO 639-1 code.
                         Codeset: %s
                         Value: %s

=head1 EXAMPLE

=for comment filename=create_and_print_text.pl

 use strict;
 use warnings;

 use Data::Text::Simple;

 my $obj = Data::Text::Simple->new(
         'id' => 7,
         'lang' => 'en',
         'text' => 'This is a text.',
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Language: '.$obj->lang."\n";
 print 'Text: '.$obj->text."\n";

 # Output:
 # Id: 7
 # Language: en
 # Text: This is a text.

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Language>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Text-Simple>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
