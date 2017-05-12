package Acme::123;
require Exporter; 

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(printnumbers setLanguage getnumbers);
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = qw(@numbers);
}

my %languages = (
	'en' => [qw /one two three four five six seven eight nine ten/],
      'fr' => [qw /un deux trois quatre cinq six sept huit neuf dix/],
	'sp' => [qw /uno dos tres cuatro cinco seis siete ocho nueve diez/],
	'it' => [qw /uno due tre quattro cinque sei sette otto nove dieci/]
);
my @numbers = @{$languages {en}};

sub printnumbers {
	foreach (@numbers) {
		print "$_ \n";
	}
}

sub setLanguage {
	my $self = shift;
	my $language = shift;
	@numbers = @{$languages {$language}};
}

sub getnumbers {
	return @numbers;
}

sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}

=head1 NAME

Acme::123 - Prints 1-10 in different languages

=head1 SYNOPSIS

	use Acme::123;
	my $123 = Acme::123->new;

	$123->printnumbers; #print English numbers

	$123->setLanguage('fr'); #sets language to French

	$123->printnumbers; #prints French numbers

=head1 DESCRIPTION

Prints numbers one through ten in different languages. Currently only
English, French, Spanish, and Italian supported. In later versions, more languages
will be supported.

=head1 TODO

	Support for many more languages.

	Print one through one hundred in many different langauges.

=head1 AUTHOR

    Nathan <jprogrammer082@gmail.com>  

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Lingua::Num2Word

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

