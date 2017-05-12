# ABSTRACT: Read from a TAP archive and convert it for displaying

package Archive::TAP::Convert;
$Archive::TAP::Convert::VERSION = '0.007';
use strict;
use warnings;

use Capture::Tiny qw( capture_merged );
use TAP::Harness;
use TAP::Harness::Archive;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(convert_from_taparchive);

# one and only subroutine of this module
sub convert_from_taparchive {

    my %args = @_;

    # Input Arguments: archive, formatter, force_inline
    # Set default values:
    die 'no archive specified'
        unless (exists $args{archive});

    my $formatter;

    if ( exists $args{formatter} && ref ( $args{formatter} ) =~ /^TAP::Formatter::/ ) {
      $formatter = $args{formatter};
    }
    else {
      $args{formatter} = 'TAP::Formatter::HTML'
          unless (exists $args{formatter});
      $args{force_inline} = 0
          unless (exists $args{force_inline});

      # This is the complicate but flexible version to:
      #   use TAP::Formatter::HTML;
      #   my $formatter = TAP::Formatter::HTML->new;
      (my $require_name = $args{formatter} . ".pm") =~ s{::}{/}g;
      eval {
          require $require_name;
          $formatter = $args{formatter}->new();
      };
      die "Problems with formatter $args{formatter}"
        . " at $require_name: $@"
          if $@;
    }

    # if set, include all CSS and JS in HTML file
    if ($args{force_inline}) {
        $formatter->force_inline_css(1);
        $formatter->force_inline_js (1);
    }

    # Now we do a lot of magic to convert this stuff...

    my $harness = TAP::Harness->new({ formatter => $formatter });

    $formatter->really_quiet(1);
    $formatter->prepare;

    my $session;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive({
        archive          => $args{archive},
        parser_callbacks => {
            ALL => sub {
                $session->result( $_[0] );
            },
        },
        made_parser_callback => sub {
            $session = $formatter->open_test( $_[1], $_[0] );
        }
    });

    $aggregator->start;
    $aggregator->stop;

    # This code also prints to STDOUT but we will catch it!
    return capture_merged { $formatter->summary($aggregator) };

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::TAP::Convert - Read from a TAP archive and convert it for displaying

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Either:

  use Archive::TAP::Convert qw(convert_from_taparchive);

  my $html = convert_from_taparchive(
                archive   => '/must/be/the/complete/path/to/test.tar.gz',
                formatter => 'TAP::Formatter::HTML',
             );

Or:

  use Archive::TAP::Convert qw(convert_from_taparchive);
  use TAP::Formatter::HTML; # or ::JUnit, ::Console, etc.

  my $formatter = TAP::Formatter::HTML->new;
  # possibly configure formatter

  my $html = convert_from_taparchive(
                archive   => '/must/be/the/complete/path/to/test.tar.gz',
                formatter => $formatter,
             );

=head1 ABOUT

This is a software library for the I<perl programming language>.

The modul can be of help for you if you have TAP archives (e.g. created with C<prove -a> and now you wish to have the content of this archives in a special format like HTML or JUnit (or whatever format).

=head1 EXPORTED METHODS

=head2 convert_from_taparchive

The method takes three arguments.
Only C<archive> is required.
It takes the B<full> path to your TAP archive.
The C<formatter> defaults to C<TAP::Formatter::HTML>, but you can define any other formatter by string or even pass a reference to an existing formatter-object.
The method will return the content of the TAP archive, parsed according to the formatter you have specified.

 my $html = convert_from_taparchive(
                archive      => '/must/be/the/complete/path/to/test.tar.gz',
                formatter    =>'TAP::Formatter::HTML',
                force_inline => 1,
            );

You can give any optional true value to C<force_inline> and it will pack all Javascript and CSS inside the HTML instead of linking to to files from L<TAP::Formatter::HTML>.
This defaults to zero, meaning do not inline.

=head1 BUGS AND LIMITATIONS

No known issues.

=head1 SEE ALSO

=over

=item *

Might also be interesting for you: L<Archive::TAP::Peek>

=item *

The previous name of this module was: L<Convert::TAP::Archive> (deprecated)

=item *

Used in this module: L<Test::Harness>

=item *

Available formatters: L<TAP::Formatter::Base> and its implementations for L<HTML|TAP::Formatter::HTML>, L<JUnit|TAP::Formatter::JUnit> or L<Console|TAP::Formatter::Console>.

=back

=head1 CONTRIBUTORS

=over

=item *

Xavier Caron (XAV / maspalio)

=back

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>, Renée Bäcker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Boris Däppen, Renée Bäcker, plusW.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
