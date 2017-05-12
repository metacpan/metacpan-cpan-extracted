package Blosxom::Plugin::DataSection;
use strict;
use warnings;
use Data::Section::Simple;

my @exports = qw( get_data_section merge_data_section_into );

sub init {
    my ( $class, $caller ) = @_;
    $caller->add_attribute( data_section => \&_build_data_section );
    $caller->add_method( $_ => \&{$_} ) for @exports;
    return;
}

sub _build_data_section {
    Data::Section::Simple->new($_[0])->get_data_section;
}

sub get_data_section { $_[0]->data_section->{$_[1]} }

sub merge_data_section_into {
    my ( $pkg, $merge_into ) = @_;
    my $data_section = $pkg->data_section;
    for my $name ( keys %{$data_section} ) {
        my ( $chunk, $flavour ) = $name =~ /(.*)\.([^.]*)/;
        $merge_into->{ $flavour }{ $chunk } = $data_section->{ $name };
    }
}

1;

__END__

=head1 NAME

Blosxom::Plugin::DataSection - Read data from __DATA__

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
