package Data::Phrasebook;
use strict;
use warnings FATAL => 'all';
use base qw( Data::Phrasebook::Debug );
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook - Abstract your queries!

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Plain',
        loader => 'Text',
        file   => 'phrases.txt',
    );

    # simple keyword to phrase mapping
    my $phrase = $q->fetch($keyword);

    # keyword to phrase mapping with parameters
    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword,{this => 'that'});

=head1 DESCRIPTION

Data::Phrasebook is a collection of modules for accessing phrasebooks from
various data sources.

=head1 PHRASEBOOKS

To explain what phrasebooks are it is worth reading Rani Pinchuk's
(author of L<Class::Phrasebook>) article on Perl.com:

L<http://www.perl.com/pub/a/2002/10/22/phrasebook.html>

Common uses of phrasebooks are in handling error codes, accessing databases
via SQL queries and written language phrases. Examples are the mime.types
file and the hosts file, both of which use a simple phrasebook design.

Unfortunately Class::Phrasebook is a complete work and not a true class
based framework. If you can't install XML libraries, you cannot use it.
This distribution is a collaboration between Iain Truskett and myself to
create an extendable and class based framework for implementing phrasebooks.

=head1 CLASSES

In creating a phrasebook object, a class type is required. This class defines
the nature of the phrasebook or the behaviours associated with it. Currently
there are two classes, Plain and SQL.

The Plain class is the default class, and allows retrieval of phrases via the
fetch() method. The fetch() simply returns the phrase that maps to the given
keyword.

The SQL class allows specific database handling. Phrases are retrieved via the
query() method. The query() method internally retrieves the SQL phrase, then
returns the statement handler object, which the user can then perform a
prepare/execute/fetch/finish sequence on. For more details see
Data::Phrasebook::SQL.

=head1 CONSTRUCTOR

=head2 new

The arguments to new depend upon the exact class you're creating.

The default class is C<Plain> and only requires the Loader arguments. The
C<SQL> class requires a database handle as well as the Loader arguments.

The C<class> argument defines the object class of the phrasebook and the
behaviours that can be associated with it. Using C<Foobar> as a fake class,
the class module is searched for in the following order:

=over 4

=item 1

If you've subclassed C<Data::Phrasebook>, for example as C<Dictionary>,
then C<Dictionary::Foobar> is tried.

=item 2

If that failed, C<Data::Phrasebook::Foobar> is tried.

=item 3

If B<that> failed, C<Foobar> is tried.

=item 4

If all the above failed, we croak.

=back

This should allow you some flexibility in what sort of classes
you use while not having you type too much.

For other parameters, see the specific class you wish to instantiate.
The class argument is removed from the arguments list and the C<new>
method of the specified class is called with the remaining arguments.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $debug = delete $args{debug} || 0;
    $class->debug($debug);

    if($debug) {
		$class->store(3,"$class->new IN");
		$class->store(4,"$class->new args=[".$class->dumper(\%args).']');
	}

    my $sub = delete $args{class} || 'Plain';
    if (eval "require ${class}::$sub") {
        $sub = $class."::$sub";
    } elsif (eval "require Data::Phrasebook::$sub") {
        $sub = "Data::Phrasebook::$sub";
    } elsif (eval "require $sub") {
        # it's a module by itself
    } else {
        croak "Could not find appropriate class for '$sub': [$@]";
    }

    $class->store(4,"$class->new sub=[$sub]")	if($class->debug);

    return $sub->new( %args );
}

1;

__END__

=head1 DELIMITERS

Delimiters allow for variable substitution in the phrase. The default style
is ':variable', which would be passed as:

    $q->delimiters( qr{ :(\w+) }x );

As an alternative, a Template Toolkit style would be passed as:

    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );

=head1 DICTIONARIES

=head2 Simple Dictionaries

Data::Phrasebook supports the use of dictionaries. See the specific Loader
module to see how to implement the dictionary within your phrasebook. Using
Data::Phrasebook::Loader::Ini as an example, the dictionary might be laid out
as:

  [Stuff]
  language=Perl
  platform=Linux

  [Nonsense]
  platform=Windows

The phrasebook object is then created and used as:

  my $q = Data::Phrasebook->new(
    class  => 'Plain',
    loader => 'Ini',
    file   => 'phrases.ini',
    dict   => 'Nonsense',
  );

  my $language = $q->fetch('language');	# retrieves 'Perl'
  my $platform = $q->fetch('platform');	# retrieves 'Windows'

The former is from the default (first) dictionary, and the second is from the
named dictionary ('Nonsense'). If a phrase is not found in the named dictionary
an attempt is made to find it in the default dictionary. Otherwise undef will
be returned.

Once a dictionary or file is specified, changing either requires reloading. As
this is done at the loader stage, we need to let it know what it needs to
reload. This can be done with the either (or both) of the following:

  $q->file('phrases2.ini');
  $q->dict('Stuff');

A subsequent fetch() will then reload the file and dictionary, before
retrieving the phrase required. However, a reload only takes place if both the
file and the dictionary passed are not the ones currently loaded.

=head2 Multiple Dictionaries

As of version 0.25, the ability to provide prescendence over multiple
dictionaries for the same phrasebook. Using Data::Phrasebook::Loader::Ini
again as an example, the phrasebook might be laid out as:

  [AndTheOther]
  language=Perl
  platform=Linux
  network=LAN

  [That]
  platform=Solaris
  network=WLAN

  [This]
  platform=Windows

The phrasebook object is then created and used as:

  my $q = Data::Phrasebook->new(
    class  => 'Plain',
    loader => 'Ini',
    file   => 'phrases.ini',
    dict   => ['This','That','AndTheOther'],
  );

  my $language = $q->fetch('language');	# retrieves 'Perl'
  my $platform = $q->fetch('platform');	# retrieves 'Windows'
  my $network  = $q->fetch('nework');	# retrieves 'WLAN'

The first dictionary, if not specified and supported by the Loader module, is
still used as the default dictionary.

The dictionaries can be specified, or reordered, using the object method:

  $q->dict('That','AndTheOther','This');

A subsequent reload will occur with the next fetch call.

=head1 DEDICATION

Much of the code for the original class framework is from Iain's original code.
My code was much simpler and was tied to using just an INI data source. Merging
all the ideas and code together we came up with this distribution.

Unfortunately Iain died in December 2003, so he never got to see or play
with the final working version. I can only thank him for his thoughts and
ideas in getting this distribution into a state worthy of release.

  Iain Campbell Truskett (16.07.1979 - 29.12.2003)

=head1 SEE ALSO

L<Data::Phrasebook::Plain>,
L<Data::Phrasebook::SQL>,
L<Data::Phrasebook::SQL::Query>,
L<Data::Phrasebook::Debug>,
L<Data::Phrasebook::Generic>,
L<Data::Phrasebook::Loader>,
L<Data::Phrasebook::Loader::Text>,
L<Data::Phrasebook::Loader::Base>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Original author: Iain Campbell Truskett (16.07.1979 - 29.12.2003)
  Maintainer: Barbie <barbie@cpan.org> since January 2004.
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003 Iain Truskett.
  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
