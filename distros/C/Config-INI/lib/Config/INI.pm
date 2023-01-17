use v5.12.0;
use warnings;
package Config::INI 0.029;
# ABSTRACT: simple .ini-file format

#pod =head1 SYNOPSIS
#pod
#pod Config-INI comes with code for reading F<.ini> files:
#pod
#pod   my $config_hash = Config::INI::Reader->read_file('config.ini');
#pod
#pod ...and for writing C<.ini> files:
#pod
#pod   Config::INI::Writer->write_file({ somekey => 'somevalue' }, 'config.ini');
#pod
#pod See L<Config::INI::Writer> and L<Config::INI::Reader> for more examples.
#pod
#pod =head1 GRAMMAR
#pod
#pod This section describes the format parsed and produced by Config::INI::Reader
#pod and ::Writer.  It is not an exhaustive and rigorously tested formal grammar,
#pod it's just a description of this particular implementation of the
#pod not-quite-standardized "INI" format.
#pod
#pod   ini-file   = { <section> | <empty-line> }
#pod
#pod   empty-line = [ <space> ] <line-ending>
#pod
#pod   section        = <section-header> { <value-assignment> | <empty-line> }
#pod
#pod   section-header = [ <space> ] "[" <section-name> "]" [ <space> ] <line-ending>
#pod   section-name   = string
#pod
#pod   value-assignment = [ <space> ] <property-name> [ <space> ]
#pod                      "="
#pod                      [ <space> ] <value> [ <space> ]
#pod                      <line-ending>
#pod   property-name    = string-without-equals
#pod   value            = string
#pod
#pod   comment     = <space> ";" [ <string> ]
#pod   line-ending = [ <comment> ] <EOL>
#pod
#pod   space = ( <TAB> | " " ) *
#pod   string-without-equals = string - "="
#pod   string = ? 1+ characters; not ";" or EOL; begins and ends with non-space ?
#pod
#pod Of special note is the fact that I<no> escaping mechanism is defined, meaning
#pod that there is no way to include an EOL or semicolon (for example) in a value,
#pod property name, or section name.  If you need this, either subclass, wait for a
#pod subclass to be written for you, or find one of the many other INI-style parsers
#pod on the CPAN.
#pod
#pod The order of sections and value assignments within a section are not
#pod significant, except that given multiple assignments to one property name within
#pod a section, only the final one is used.  A section name may be used more than
#pod once; this will have the identical meaning as having all property assignments
#pod in all sections of that name in sequence.
#pod
#pod =head1 DON'T FORGET
#pod
#pod The definitions above refer to the format used by the Reader and Writer classes
#pod bundled in the Config-INI distribution.  These classes are designed for easy
#pod subclassing, so it should be easy to replace their behavior with whatever
#pod behavior your want.
#pod
#pod Patches, feature requests, and bug reports are welcome -- but I'm more
#pod interested in making sure you can write a subclass that does what you need, and
#pod less in making Config-INI do what you want directly.
#pod
#pod =head1 THANKS
#pod
#pod Thanks to Florian Ragwitz for improving the subclassability of Config-INI's
#pod modules, and for helping me do some of my first merging with git(7).
#pod
#pod =head1 ORIGIN
#pod
#pod Originaly derived from L<Config::Tiny>, by Adam Kennedy.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::INI - simple .ini-file format

=head1 VERSION

version 0.029

=head1 SYNOPSIS

Config-INI comes with code for reading F<.ini> files:

  my $config_hash = Config::INI::Reader->read_file('config.ini');

...and for writing C<.ini> files:

  Config::INI::Writer->write_file({ somekey => 'somevalue' }, 'config.ini');

See L<Config::INI::Writer> and L<Config::INI::Reader> for more examples.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 GRAMMAR

This section describes the format parsed and produced by Config::INI::Reader
and ::Writer.  It is not an exhaustive and rigorously tested formal grammar,
it's just a description of this particular implementation of the
not-quite-standardized "INI" format.

  ini-file   = { <section> | <empty-line> }

  empty-line = [ <space> ] <line-ending>

  section        = <section-header> { <value-assignment> | <empty-line> }

  section-header = [ <space> ] "[" <section-name> "]" [ <space> ] <line-ending>
  section-name   = string

  value-assignment = [ <space> ] <property-name> [ <space> ]
                     "="
                     [ <space> ] <value> [ <space> ]
                     <line-ending>
  property-name    = string-without-equals
  value            = string

  comment     = <space> ";" [ <string> ]
  line-ending = [ <comment> ] <EOL>

  space = ( <TAB> | " " ) *
  string-without-equals = string - "="
  string = ? 1+ characters; not ";" or EOL; begins and ends with non-space ?

Of special note is the fact that I<no> escaping mechanism is defined, meaning
that there is no way to include an EOL or semicolon (for example) in a value,
property name, or section name.  If you need this, either subclass, wait for a
subclass to be written for you, or find one of the many other INI-style parsers
on the CPAN.

The order of sections and value assignments within a section are not
significant, except that given multiple assignments to one property name within
a section, only the final one is used.  A section name may be used more than
once; this will have the identical meaning as having all property assignments
in all sections of that name in sequence.

=head1 DON'T FORGET

The definitions above refer to the format used by the Reader and Writer classes
bundled in the Config-INI distribution.  These classes are designed for easy
subclassing, so it should be easy to replace their behavior with whatever
behavior your want.

Patches, feature requests, and bug reports are welcome -- but I'm more
interested in making sure you can write a subclass that does what you need, and
less in making Config-INI do what you want directly.

=head1 THANKS

Thanks to Florian Ragwitz for improving the subclassability of Config-INI's
modules, and for helping me do some of my first merging with git(7).

=head1 ORIGIN

Originaly derived from L<Config::Tiny>, by Adam Kennedy.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords castaway David Steinbrunner Florian Ragwitz George Hartzell Graham Knop Ricardo SIGNES Signes Smylers

=over 4

=item *

castaway <castaway@desert-island.me.uk>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

George Hartzell <hartzell@alerce.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Ricardo SIGNES <com.github@rjbs.manxome.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Smylers <Smylers@stripey.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
