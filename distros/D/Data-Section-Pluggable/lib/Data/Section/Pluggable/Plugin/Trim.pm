use warnings;
use 5.020;
use true;
use experimental qw( signatures );
use stable qw( postderef );

package Data::Section::Pluggable::Plugin::Trim 0.04 {

    # ABSTRACT: Data::Section::Pluggable plugin that trims whitespace


    use Class::Tiny qw( extensions );
    use Role::Tiny::With;
    use Ref::Util qw( is_arrayref );

    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';

    sub BUILD ($self, $) {
        if(defined $self->extensions) {
            $self->extensions([$self-extensions]) unless is_arrayref $self->extensions;
        } else {
            $self->extensions(['txt']);
        }
    }

    sub process_content ($self, $dsp, $content) {
        return $content =~ s/^\s*//r =~ s/\s*\z//r;
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable::Plugin::Trim - Data::Section::Pluggable plugin that trims whitespace

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Data::Section::Pluggable;
 
 my $dsp = Data::Section::Pluggable->new
                                   ->add_plugin('trim');
 
 # prints "Welcome to Perl" without prefix
 # or trailing white space.
 say $dsp->get_data_section('hello.txt');
 
 __DATA__
 
 @@ hello.txt
   Welcome to Perl
 
 
 __END__

=head1 DESCRIPTION

This plugin trims leading and trailing whitespace from data in C<__DATA__>.
This is sometimes useful or these data sections tend to include a lot of
extra whitespace if you want to space the different sections apart.

By default, this plugin only operates on files with the C<txt> extension,
but you can override this with the L</extensions> property.

=head1 PROPERTIES

=head2 extensions

 $dsp->plugin( 'trim', extensions => \@extensions );

Array reference of filename extensions whitespace should be trimmed from.
If not provided, only C<txt> will get trimmed.

=head1 SEE ALSO

=over 4

=item L<Data::Section::Pluggable>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
