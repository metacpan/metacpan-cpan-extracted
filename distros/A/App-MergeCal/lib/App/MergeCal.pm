=head1 NAME

App::MergeCal

=head1 ABSTRACT

Command line program that merges iCal files into a single calendar.

=head1 SYNOPSIS

    use App::MergeCal;

    my $app = App::MergeCal->new;
    $app->run;

    # Or, more likely, use the mergecal program

=cut

use 5.24.0;
use Feature::Compat::Class;

package App::MergeCal; # For PAUSE

class App::MergeCal {

  our $VERSION = '0.0.4';

  use Encode 'encode_utf8';
  use Text::vFile::asData;
  use LWP::Simple;
  use JSON;
  use URI;

  field $vfile_parser :param = Text::vFile::asData->new;
  field $title :param;
  field $output :param = '';
  field $calendars :param;
  field $objects;

=head1 METHODS

=head2 $app->calendars, $app->title, $app->output

Accessors for fields.

=cut

  method calendars { return $calendars }
  method title     { return $title }
  method output    { return $title }

=head2 $app->run

Main driver method.

=cut

  method run {
    $self->gather;
    $self->render;
  }

=head2 $app->gather

Access all of the calendars and gather their contents into $objects.

=cut

  method gather {
    $self->clean_calendars;
    for (@$calendars) {
      my $ics = get($_) or die "Can't get " . $_->as_string . "\n";
      $ics = encode_utf8($ics);
      open my $fh, '<', \$ics or die $!;
      my $data = $vfile_parser->parse( $fh );

      push @$objects, @{ $data->{objects}[0]{objects} };
    }
  }

=head2 $app->render

Take all of the objects in $objects and write them to an output file.

=cut

  method render {
    my $combined = {
      type => 'VCALENDAR',
      properties => {
        'X-WR-CALNAME' => [ { value => $title } ],
      },
      objects => $objects,
    };

    my $out_fh;
    if ($output) {
      open $out_fh, '>', $output
        or die "Cannot open output file [$output]: $!\n";
      select $out_fh;
    }

    say "$_\r" for Text::vFile::asData->generate_lines($combined);
  }

=head2 $app->clean_calendars

Ensure that all of the calendars are URIs. If a calendar doesn't have a scheme
then it is assumed to be a file URI.

=cut

  method clean_calendars {
    for (@$calendars) {
      $_ = URI->new($_) unless ref $_;
      if (! $_->scheme) {
        $_ = URI->new('file://' . $_);
      }
    }
  }

=head2 App::MergeCal->new, App::MergeCal->new_from_json, App::MergeCal->new_from_json_file

Constructor methods.

=over 4

=item new

Constructs an object from a hash of attribute/value pairs

=item new_from_json

Constructs an object from a JSON string representing attribute/value pairs.

=item new_from_json_file

Constructs an object from a file containing a JSON string representing
attribute/value pairs.

=back

=cut

  sub new_from_json {
    my $class = shift;
    my ($json) = @_;

    my $data = JSON->new->decode($json);

    return $class->new(%$data);
  }

  sub new_from_json_file {
    my $class = shift;
    my $conf_file = $_[0] // 'config.json';

    open my $conf_fh, '<', $conf_file or die "$conf_file: $!";
    my $json = do { local $/; <$conf_fh> };

    return $class->new_from_json($json);
  }
}

=head1 CONFIGURATION

The behaviour of the program is controlled by a JSON file. The default name
for this file is C<config.json>. The contents of the file will look something
like this:

    {
      "title":"My Combined Calendar",
      "output":"my_calendar.ics",
      "calendars":[
        "https://example.com/some_calendar.ics",
        "https://example.com/some_other_calendar.ics",
      ]
    }

This configuration will read the the calendars from the URLs listed and
combine their contents into a file called C<my_calendar.ics> (which you will
presumably make available on the internet).

The <output> configuration option is optional. If it is omitted, then the
output will be written to C<STDOUT>.

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 LICENSE

Copyright (C) 2024, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
