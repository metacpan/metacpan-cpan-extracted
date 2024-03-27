package Data::Message::Simple;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.15 qw(check_length check_required check_strings);
use Mo::utils::Language 0.05 qw(check_language_639_1);
use Readonly;

Readonly::Array our @TYPES => qw(info error);

our $VERSION = 0.04;

has lang => (
	is => 'ro',
);

has text => (
	is => 'ro',
);

has type => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check lang.
	check_language_639_1($self, 'lang');

	# Check text.
	check_required($self, 'text');
	check_length($self, 'text', 4096);

	# Check message type.
	if (! defined $self->{'type'}) {
		$self->{'type'} = 'info';
	}
	check_strings($self, 'type', \@TYPES);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Message::Simple - Data object for simple message.

=head1 SYNOPSIS

 use Data::Message::Simple;

 my $obj = Data::Message::Simple->new(%params);
 my $lang = $obj->lang;
 my $text = $obj->text;
 my $type = $obj->type;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Message::Simple->new(%params);

Constructor.

=over 8

=item * C<lang>

Message language.
It's optional.
If defined, possible values are ISO 639-1 language codes.

Default value is undef.

=item * C<text>

Message text.
Maximum length of text is 4096 characters.
It's required.

=item * C<type>

Message type.
Possible value are 'error' and 'info'.
It's required.
Default value is 'info'.

=back

Returns instance of object.

=head2 C<lang>

 my $lane = $obj->lang;

Get ISO 639-1 language code of text.

Returns string.

=head2 C<text>

 my $text = $obj->text;

Get message text.

Returns string.

=head2 C<type>

 my $type = $obj->type;

Get message type.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'text' has length greater than '4096'.
                         Value: %s
                 Parameter 'text' is required.
                         Value: %s
                 Parameter 'type' must be one of defined strings.
                         String: %s
                         Possible strings: %s
         From Mo::utils::Language:
                 Parameter 'lang' doesn't contain valid ISO 639-1 code.
                         Codeset: %s
                         Value: %s

=head1 EXAMPLE

=for comment filename=create_and_print_message.pl

 use strict;
 use warnings;

 use Data::Message::Simple;

 my $obj = Data::Message::Simple->new(
         'lang' => 'en',
         'text' => 'This is text message.',
 );

 # Print out.
 print 'Message type: '.$obj->type."\n";
 print 'ISO 639-1 language code: '.$obj->lang."\n";
 print 'Text: '.$obj->text."\n";

 # Output:
 # Message type: info
 # ISO 639-1 language code: en
 # Text: This is text message.

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Language>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Message-Simple>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
