package Blosxom::Component::DataSection;
use strict;
use warnings;
use parent 'Blosxom::Component';
use Data::Section::Simple;

__PACKAGE__->mk_accessors(
    data_section => sub {
        my $class = shift;
        Data::Section::Simple->new($class)->get_data_section;
    },
);

sub get_data_section   { $_[0]->data_section->{$_[1]}  }
sub data_section_names { keys %{ $_[0]->data_section } }

sub merge_data_section_into {
    my ( $class, $merge_into ) = @_;
    while ( my ($basename, $template) = each %{ $class->data_section } ) {
        my ( $chunk, $flavour ) = $basename =~ /(.*)\.([^.]*)/;
        $merge_into->{ $flavour }{ $chunk } = $template;
    }
}

1;

__END__

=head1 NAME

Blosxom::Component::DataSection - Read data from __DATA__

=head1 SYNOPSIS

  package my_plugin;
  use strict;
  use warnings;
  use parent 'Blosxom::Plguin';

  __PACKAGE__->load_components( 'DataSection' );

  sub start {
      my $class = shift;

      my $template = $class->get_data_section( 'my_plugin.html' );
      # <!DOCTYPE html>
      # ...

      # merge __DATA__ into Blosxom default templates
      $class->merge_data_section_into( \%blosxom::template );

      return 1;
  }

  1;

  __DATA__

  @@ my_plugin.html

  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>My Plugin</title>
  </head>
  <body>
  <h1>Hello, world</h1>
  </body>
  </html>

=head1 DESCRIPTION

This module extracts data from C<__DATA__> section of the plugin,
and also merges them into Blosxom default templates.

=head2 METHODS

=over 4

=item $template = $class->get_data_section( $name )

This method returns a string containing the data from the named section.

=item @names = $class->data_section_names

This returns a list of all the names that will be recognized
by the C<get_data_section()> method.

=item $class->merge_data_section_into( \%blosxom::template )

Given a reference to a hash which holds Blosxom default templates,
merges __DATA__ into the hash. The following data structure is expected:

  {
      html => {
          head  => '<html><head>...',
          story => '<p><a name="$fn">...',
      },
      rss => {
          head  => '<?xml version="1.0">...',
          story => '<item>...',
      },
  }

=back

=head1 SEE ALSO

L<Blosxom::Plugin>, L<Data::Section::Simple>

=head1 AUTHOR

Ryo Anazawa <anazawa@cpan.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
