package Config::MVP;
# ABSTRACT: multivalue-property package-oriented configuration
$Config::MVP::VERSION = '2.200011';
use strict;
use warnings;

#pod =head1 SYNOPSIS
#pod
#pod If you want a useful synopsis, consider this code which actually comes from
#pod L<Config::MVP::Assembler|Config::MVP::Assembler>:
#pod
#pod   my $assembler = Config::MVP::Assembler->new;
#pod
#pod   # Maybe you want a starting section:
#pod   my $section = $assembler->section_class->new({ name => '_' });
#pod   $assembler->sequence->add_section($section);
#pod
#pod   # We'll add some values, which will go to the starting section:
#pod   $assembler->add_value(x => 10);
#pod   $assembler->add_value(y => 20);
#pod
#pod   # Change to a new section...
#pod   $assembler->change_section($moniker);
#pod
#pod   # ...and add values to that section.
#pod   $assembler->add_value(x => 100);
#pod   $assembler->add_value(y => 200);
#pod
#pod This doesn't make sense?  Well, read on.
#pod
#pod (You can also read the L<2009 RJBS Advent Calendar
#pod article|http://advent.rjbs.manxome.org/2009/2009-12-20.html> on Config::MVP!)
#pod
#pod =head1 DESCRIPTION
#pod
#pod MVP is a mechanism for loading configuration (or other information) for
#pod libraries.  It doesn't read a file or a database.  It's a helper for things
#pod that do.
#pod
#pod The idea is that you end up with a
#pod L<Config::MVP::Sequence|Config::MVP::Sequence> object, and that you can use
#pod that object to fully configure your library or application.  The sequence will
#pod contain a bunch of L<Config::MVP::Section|Config::MVP::Section> objects, each
#pod of which is meant to provide configuration for a part of your program.  Most of
#pod these sections will be directly related to a Perl library that you'll use as a
#pod plugin or helper.  Each section will have a name, and every name in the
#pod sequence will be unique.
#pod
#pod This is a pretty abstract set of behaviors, so we'll provide some more concrete
#pod examples that should help explain how things work.
#pod
#pod =head1 EXAMPLE
#pod
#pod Imagine that we've got a program called DeliveryBoy that accepts mail and does
#pod stuff with it.  The "stuff" is entirely up to the user's configuration.  He can
#pod set up plugins that will be used on the message.  He writes a config file that's
#pod read by L<Config::MVP::Reader::INI|Config::MVP::Reader::INI>, which is a thin
#pod wrapper around Config::MVP used to load MVP-style config from F<INI> files.
#pod
#pod Here's the user's configuration:
#pod
#pod   [Whitelist]
#pod   require_pgp = 1
#pod
#pod   file = whitelist-family
#pod   file = whitelist-friends
#pod   file = whitelist-work
#pod
#pod   [SpamFilter]
#pod   filterset = standard
#pod   max_score = 5
#pod   action    = bounce
#pod
#pod   [SpamFilter / SpamFilter_2]
#pod   filterset = aggressive
#pod   max_score = 5
#pod   action    = tag
#pod
#pod   [VerifyPGP]
#pod
#pod   [Deliver]
#pod   dest = Maildir
#pod
#pod The user will end up with a sequence with five sections, which we can represent
#pod something like this:
#pod
#pod   { name    => 'Whitelist',
#pod     package => 'DeliveryBoy::Plugin::Whitelist',
#pod     payload => {
#pod       require_pgp => 1,
#pod       files   => [ qw(whitelist-family whitelist-friends whitelist-work) ]
#pod     },
#pod   },
#pod   { name    => 'SpamFilter',
#pod     package => 'DeliveryBoy::Plugin::SpamFilter',
#pod     payload => {
#pod       filterset => 'standard',
#pod       max_score => 5,
#pod       action    => 'bounce',
#pod     }
#pod   },
#pod   { name    => 'SpamFilter_2',
#pod     package => 'DeliveryBoy::Plugin::SpamFilter',
#pod     payload => {
#pod       filterset => 'aggressive',
#pod       max_score => 5,
#pod       action    => 'tag',
#pod     },
#pod   },
#pod   { name    => 'VerifyPGP',
#pod     package => 'DeliveryBoy::Plugin::VerifyPGP',
#pod     payload => { },
#pod   },
#pod   { name    => 'Deliver',
#pod     package => 'DeliveryBoy::Plugin::Deliver',
#pod     payload => { dest => 'Maildir' },
#pod   },
#pod
#pod The INI reader uses L<Config::MVP::Assembler|Config::MVP::Assembler> to build
#pod up configuration section by section as it goes, so that's how we'll talk about
#pod what's going on.
#pod
#pod Every section of the config file was converted into a section in the MVP
#pod sequence.  Each section has a unique name, which defaults to the name of the
#pod INI section.  Each section is also associated with a package, which was
#pod expanded from the INI section name.  The way that names are expanded can be
#pod customized by subclassing the assembler.
#pod
#pod Every section also has a payload -- a hashref of settings.  Note that every
#pod entry in every payload is a simple scalar except for one.  The C<files> entry
#pod for the Whitelist section is an arrayref.  Also, note that while it appears as
#pod C<files> in the final output, it was given as C<file> in the input.
#pod
#pod Config::MVP provides a mechanism by which packages can define aliases for
#pod configuration names and an indication of what names correspond to "multi-value
#pod parameters."  (That's part of the meaning of the name "MVP.")  When the MVP
#pod assembler is told to start a section for C<Whitelist> it expands the section
#pod name, loads the package, and inspects it for aliases and multivalue parameters.
#pod Then if multiple entries for a non-multivalue parameter are given, an exception
#pod can be raised.  Multivalue parameters are always pushed onto arrayrefs and
#pod non-multivalue parameters are left as found.
#pod
#pod =head2 ...so what now?
#pod
#pod So, once our DeliveryBoy program has loaded its configuration, it needs to
#pod initialize its plugins.  It can do something like the following:
#pod
#pod   my $sequence = $deliveryboy->load_config;
#pod
#pod   for my $section ($sequence->sections) {
#pod     my $plugin = $section->package->new( $section->payload );
#pod     $deliveryboy->add_plugin( $section->name, $plugin );
#pod   }
#pod
#pod That's it!  In fact, allowing this very, very block of code to load
#pod configuration and initialize plugins is the goal of Config::MVP.
#pod
#pod The one thing not depicted is the notion of a "root section" that you might
#pod expect to see in an INI file.  This can be easily handled by starting your
#pod assembler off with a pre-built section where root settings will end up.  For
#pod more information on this, look at the docs for the specific components.
#pod
#pod =head1 WHAT NEXT?
#pod
#pod =head2 Making Packages work with MVP
#pod
#pod Any package can be used as part of an MVP section.  Packages can provide some
#pod methods to help MVP work with them.  It isn't a problem if they are not defined
#pod
#pod =head3 mvp_aliases
#pod
#pod This method should return a hashref of name remappings.  For example, if it
#pod returned this hashref:
#pod
#pod   {
#pod     file => 'files',
#pod     path => 'files',
#pod   }
#pod
#pod Then attempting to set either the "file" or "path" setting for the section
#pod would actually set the "files" setting.
#pod
#pod =head3 mvp_multivalue_args
#pod
#pod This method should return a list of setting names that may have multiple values
#pod and that will always be stored in an arrayref.
#pod
#pod =head2 The Assembler
#pod
#pod L<Config::MVP::Assembler|Config::MVP::Assembler> is a state machine that makes
#pod it easy to build up your MVP-style configuration by firing off a series of
#pod events: new section, new setting, etc.  You might want to subclass it to change
#pod the class of sequence or section that's used or to change how section names are
#pod expanded into packages.
#pod
#pod =head2 Sequences and Sections
#pod
#pod L<Config::MVP::Sequence|Config::MVP::Sequence> and
#pod L<Config::MVP::Section|Config::MVP::Section> are the two most important classes
#pod in MVP.  They represent the overall configuration and each section of the
#pod configuration, respectively.  They're both fairly simple classes, and you
#pod probably won't need to subclass them, but it's easy.
#pod
#pod =head2 Examples in the World
#pod
#pod For examples of Config::MVP in use, you can look at L<Dist::Zilla|Dist::Zilla>
#pod or L<App::Addex|App::Addex>.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP - multivalue-property package-oriented configuration

=head1 VERSION

version 2.200011

=head1 SYNOPSIS

If you want a useful synopsis, consider this code which actually comes from
L<Config::MVP::Assembler|Config::MVP::Assembler>:

  my $assembler = Config::MVP::Assembler->new;

  # Maybe you want a starting section:
  my $section = $assembler->section_class->new({ name => '_' });
  $assembler->sequence->add_section($section);

  # We'll add some values, which will go to the starting section:
  $assembler->add_value(x => 10);
  $assembler->add_value(y => 20);

  # Change to a new section...
  $assembler->change_section($moniker);

  # ...and add values to that section.
  $assembler->add_value(x => 100);
  $assembler->add_value(y => 200);

This doesn't make sense?  Well, read on.

(You can also read the L<2009 RJBS Advent Calendar
article|http://advent.rjbs.manxome.org/2009/2009-12-20.html> on Config::MVP!)

=head1 DESCRIPTION

MVP is a mechanism for loading configuration (or other information) for
libraries.  It doesn't read a file or a database.  It's a helper for things
that do.

The idea is that you end up with a
L<Config::MVP::Sequence|Config::MVP::Sequence> object, and that you can use
that object to fully configure your library or application.  The sequence will
contain a bunch of L<Config::MVP::Section|Config::MVP::Section> objects, each
of which is meant to provide configuration for a part of your program.  Most of
these sections will be directly related to a Perl library that you'll use as a
plugin or helper.  Each section will have a name, and every name in the
sequence will be unique.

This is a pretty abstract set of behaviors, so we'll provide some more concrete
examples that should help explain how things work.

=head1 EXAMPLE

Imagine that we've got a program called DeliveryBoy that accepts mail and does
stuff with it.  The "stuff" is entirely up to the user's configuration.  He can
set up plugins that will be used on the message.  He writes a config file that's
read by L<Config::MVP::Reader::INI|Config::MVP::Reader::INI>, which is a thin
wrapper around Config::MVP used to load MVP-style config from F<INI> files.

Here's the user's configuration:

  [Whitelist]
  require_pgp = 1

  file = whitelist-family
  file = whitelist-friends
  file = whitelist-work

  [SpamFilter]
  filterset = standard
  max_score = 5
  action    = bounce

  [SpamFilter / SpamFilter_2]
  filterset = aggressive
  max_score = 5
  action    = tag

  [VerifyPGP]

  [Deliver]
  dest = Maildir

The user will end up with a sequence with five sections, which we can represent
something like this:

  { name    => 'Whitelist',
    package => 'DeliveryBoy::Plugin::Whitelist',
    payload => {
      require_pgp => 1,
      files   => [ qw(whitelist-family whitelist-friends whitelist-work) ]
    },
  },
  { name    => 'SpamFilter',
    package => 'DeliveryBoy::Plugin::SpamFilter',
    payload => {
      filterset => 'standard',
      max_score => 5,
      action    => 'bounce',
    }
  },
  { name    => 'SpamFilter_2',
    package => 'DeliveryBoy::Plugin::SpamFilter',
    payload => {
      filterset => 'aggressive',
      max_score => 5,
      action    => 'tag',
    },
  },
  { name    => 'VerifyPGP',
    package => 'DeliveryBoy::Plugin::VerifyPGP',
    payload => { },
  },
  { name    => 'Deliver',
    package => 'DeliveryBoy::Plugin::Deliver',
    payload => { dest => 'Maildir' },
  },

The INI reader uses L<Config::MVP::Assembler|Config::MVP::Assembler> to build
up configuration section by section as it goes, so that's how we'll talk about
what's going on.

Every section of the config file was converted into a section in the MVP
sequence.  Each section has a unique name, which defaults to the name of the
INI section.  Each section is also associated with a package, which was
expanded from the INI section name.  The way that names are expanded can be
customized by subclassing the assembler.

Every section also has a payload -- a hashref of settings.  Note that every
entry in every payload is a simple scalar except for one.  The C<files> entry
for the Whitelist section is an arrayref.  Also, note that while it appears as
C<files> in the final output, it was given as C<file> in the input.

Config::MVP provides a mechanism by which packages can define aliases for
configuration names and an indication of what names correspond to "multi-value
parameters."  (That's part of the meaning of the name "MVP.")  When the MVP
assembler is told to start a section for C<Whitelist> it expands the section
name, loads the package, and inspects it for aliases and multivalue parameters.
Then if multiple entries for a non-multivalue parameter are given, an exception
can be raised.  Multivalue parameters are always pushed onto arrayrefs and
non-multivalue parameters are left as found.

=head2 ...so what now?

So, once our DeliveryBoy program has loaded its configuration, it needs to
initialize its plugins.  It can do something like the following:

  my $sequence = $deliveryboy->load_config;

  for my $section ($sequence->sections) {
    my $plugin = $section->package->new( $section->payload );
    $deliveryboy->add_plugin( $section->name, $plugin );
  }

That's it!  In fact, allowing this very, very block of code to load
configuration and initialize plugins is the goal of Config::MVP.

The one thing not depicted is the notion of a "root section" that you might
expect to see in an INI file.  This can be easily handled by starting your
assembler off with a pre-built section where root settings will end up.  For
more information on this, look at the docs for the specific components.

=head1 WHAT NEXT?

=head2 Making Packages work with MVP

Any package can be used as part of an MVP section.  Packages can provide some
methods to help MVP work with them.  It isn't a problem if they are not defined

=head3 mvp_aliases

This method should return a hashref of name remappings.  For example, if it
returned this hashref:

  {
    file => 'files',
    path => 'files',
  }

Then attempting to set either the "file" or "path" setting for the section
would actually set the "files" setting.

=head3 mvp_multivalue_args

This method should return a list of setting names that may have multiple values
and that will always be stored in an arrayref.

=head2 The Assembler

L<Config::MVP::Assembler|Config::MVP::Assembler> is a state machine that makes
it easy to build up your MVP-style configuration by firing off a series of
events: new section, new setting, etc.  You might want to subclass it to change
the class of sequence or section that's used or to change how section names are
expanded into packages.

=head2 Sequences and Sections

L<Config::MVP::Sequence|Config::MVP::Sequence> and
L<Config::MVP::Section|Config::MVP::Section> are the two most important classes
in MVP.  They represent the overall configuration and each section of the
configuration, respectively.  They're both fairly simple classes, and you
probably won't need to subclass them, but it's easy.

=head2 Examples in the World

For examples of Config::MVP in use, you can look at L<Dist::Zilla|Dist::Zilla>
or L<App::Addex|App::Addex>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alexandr Ciornii George Hartzell Karen Etheridge Kent Fredric Philippe Bruhat (BooK)

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

George Hartzell <hartzell@alerce.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
