package Data::Phrasebook::Loader::Ini;
use strict;
use warnings FATAL => 'all';
use Carp qw( croak );
use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );
use Config::IniFiles;

our $VERSION = '0.14';

=head1 NAME

Data::Phrasebook::Loader::Ini - Absract your phrases with ini files.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'Ini',
        file   => 'phrases.ini',
    );

    # simple keyword to phrase mapping
    my $phrase = $q->fetch($keyword);

    # keyword to phrase mapping with parameters
    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword,{this => 'that'});

=head1 ABSTRACT

This module provides a loader class for phrasebook implementations using INI
files.

=head1 DESCRIPTION

This module provides a base class for phrasebook implementations.

Phrases can be contained within one or more dictionaries, with each phrase
accessible via a unique key. Phrases may contain placeholders, please see
L<Data::Phrasebook> for an explanation of how to use these. Groups of phrases
are kept in a dictionary. In this implementation a dictionary is considered to
be equivilent to a section in an ini file.

An example ini file:

  [BASE]
  foo=\
    Welcome to :my world. \
    It is a nice :place.

Within the phrase text placeholders can be used, which are then replaced with
the appropriate values once the get() method is called. The default style of
placeholders can be altered using the delimiters() method.

=head1 INHERITANCE

L<Data::Phrasebook::Loader::Ini> inherits from the base class
L<Data::Phrasebook::Loader::Base>.
See that module for other available methods and documentation.

=head1 METHODS

=head2 load

Given a C<file>, load it. C<file> must contain a INI style layout.

   $loader->load( $file, $dict );

This method is used internally by L<Data::Phrasebook::Generic>'s
C<data> method, to initialise the data store.

It must take a C<file> (be it a scalar, or something more complex)
and return a handle.

=cut

sub load
{
    my ($class, $file, $dict) = @_;
    croak "No file given as argument!" unless defined $file;
	croak "Cannot read configuration file [$file]\n"
		unless(-r $file);

	my $cfg = Config::IniFiles->new(
					-file => $file,
					-allowcontinue => 1,	# allows continuation lines
				);
	croak "Cannot access configuration file [$file]".
			" - [@Config::IniFiles::errors]\n"	unless($cfg);
	$class->{cfg} = $cfg;

	# what sections are we using?
	($class->{default}) = $cfg->Sections;
	$class->{dict} = $class->{default};
	$class->{dict} = $dict
  		if($dict && $class->{cfg}->SectionExists( $dict ));
};

=head2 get

Returns the phrase stored in the phrasebook, for a given keyword.

   my $value = $loader->get( $key );

=cut

sub get {
	my ($class, $key) = @_;

  	my $data = $class->{cfg}->val( $class->{dict}, $key );
  	$data = $class->{cfg}->val( $class->{default}, $key )	unless($data);
	return	unless($data);

	$data =~ s!^\s+!!s;
	$data =~ s!\s+$!!s;
	$data =~ s!\s+! !sg;

	return $data;
}

=head2 dicts

Returns the list of dictionaries available.

   my @dicts = $loader->dicts();

=cut

sub dicts {
	my $class = shift;
    $class->{cfg}->Sections
}

=head2 keywords

Returns the list of keywords available. List is lexically sorted.

   my @dicts = $loader->keywords();

=cut

sub keywords {
	my $class = shift;
	my $dict  = shift;

    if($dict) {
        my @dicts = sort $class->{cfg}->Parameters($dict);
        return @dicts;
    }

    my @keywords = $class->{cfg}->Parameters($class->{dict});
    push @keywords, $class->{cfg}->Parameters($class->{default})
        unless($class->{dict} eq $class->{default});

    my %keywords = map {$_=>1} @keywords;
    @keywords = sort keys %keywords;
    return @keywords;
}

1;

__END__

=head1 CONTINUATION LINES

As this module uses C<Config::IniFiles>, it allows for the use of
continuation lines as follows:

  [Section]
  Parameter=this parameter \
    spreads across \
    a few lines

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Config::IniFiles>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are
able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
