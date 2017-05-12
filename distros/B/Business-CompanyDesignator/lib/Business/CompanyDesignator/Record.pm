package Business::CompanyDesignator::Record;

use Mouse;
use utf8;
use warnings qw(FATAL utf8);
use Carp;
use namespace::autoclean;

has 'long'                  => ( is => 'ro', isa => 'Str', required => 1 );
has 'record'                => ( is => 'ro', isa => 'HashRef', required => 1 );

has [qw(abbr1 lang)]        => ( is => 'ro', lazy_build => 1 );
has 'abbr'                  => ( is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, builder => '_build_abbr',
                                 reader => '_abbr', traits => [ qw(Array) ], handles => { abbr => 'elements' } );

sub _build_abbr {
  my $self = shift;
  my $abbr = $self->record->{abbr} or return [];
  return ref $abbr ? $abbr : [ $abbr ];
}

sub _build_abbr1 {
  my $self = shift;
  my @abbr = $self->abbr;
  if (@abbr) {
    return $abbr[0];
  }
}

sub _build_lang {
  my $self = shift;
  $self->record->{lang};
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Business::CompanyDesignator::Record - class for modelling individual L<Business::CompanyDesignator> input records

=head1 SYNOPSIS

  # Typically instantiated via Business::CompanyDesignator->record() or records()
  use Business::CompanyDesignator;
  
  $bcd = Business::CompanyDesignator->new;
  $record = $bcd->record("Limited");
  @records = $bcd->records("Inc.");

  # Accessors
  $long = $record->long;
  @abbr = $record->abbr;
  $abbr1 = $record->abbr1;
  $lang = $record->lang;

=head1 METHODS

=head2 new()

Create a new Business::CompanyDesignator::Record object.

B<Note:> objects are normally instantiated via Business::CompanyDesignator->record()
or records(), however:

  use Business::CompanyDesignator;
    
  $bcd = Business::CompanyDesignator->new;
  $record = $bcd->record("Limited");
  @records = $bcd->records("Inc.");

=head2 long()

Returns the record's long designator (a string).

  $long = $record->long;

=head2 abbr()

Returns a list of the abbreviations associated with this record (if any).

  @abbr = $record->abbr;

=head2 abbr1()

Returns the first abbreviation associated with this record (a string, if any).

  $abbr1 = $record->abbr1;

=head2 lang()

Returns the ISO-639 language code associated with this record (a string).

  $lang = $record->lang;

=head1 AUTHOR

Gavin Carr <gavin@profound.net>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2013-2015 Gavin Carr

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

