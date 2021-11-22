package Config::MVP::Reader::INI 2.101464;
# ABSTRACT: an MVP config reader for .ini files

use Moose;
extends 'Config::MVP::Reader';
with 'Config::MVP::Reader::Findable::ByExtension';

use Config::MVP 2; # Reader is a base class

#pod =head1 DESCRIPTION
#pod
#pod Config::MVP::Reader::INI reads F<.ini> files containing MVP-style
#pod configuration.
#pod
#pod =cut

# Clearly this should be an attribute with a builder blah blah blah. -- rjbs,
# 2009-07-25
sub default_extension { 'ini' }

sub read_into_assembler {
  my ($self, $location, $assembler) = @_;

  my $reader = Config::MVP::Reader::INI::INIReader->new($assembler);
  $reader->read_file($location);

  return $assembler->sequence;
}

{
  package
   Config::MVP::Reader::INI::INIReader;
  use parent 'Config::INI::Reader';

  sub new {
    my ($class, $assembler) = @_;
    my $self = $class->SUPER::new;
    $self->{assembler} = $assembler;
    return $self;
  }

  sub assembler { $_[0]{assembler} }

  sub change_section {
    my ($self, $section) = @_;

    my ($package, $name) = $section =~ m{\A\s*(?:([^/\s]+)\s*/\s*)?(.+)\z};
    $package = $name unless defined $package and length $package;

    Carp::croak qq{couldn't understand section header: "$_[1]"}
      unless $package;

    $self->assembler->change_section($package, $name);
  }

  sub finalize {
    my ($self) = @_;
    $self->assembler->finalize;
  }

  sub set_value {
    my ($self, $name, $value) = @_;
    unless ($self->assembler->current_section) {
      my $starting_name = $self->starting_section;

      if ($self->assembler->sequence->section_named( $starting_name )) {
        Carp::croak q{can't set value outside of section once starting }
                  . q{section exists};
      }

      $self->assembler->change_section(\undef, $starting_name);
    }

    $self->assembler->add_value($name, $value);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Reader::INI - an MVP config reader for .ini files

=head1 VERSION

version 2.101464

=head1 DESCRIPTION

Config::MVP::Reader::INI reads F<.ini> files containing MVP-style
configuration.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords nperez Olivier Mengué

=over 4

=item *

nperez <nperez@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
