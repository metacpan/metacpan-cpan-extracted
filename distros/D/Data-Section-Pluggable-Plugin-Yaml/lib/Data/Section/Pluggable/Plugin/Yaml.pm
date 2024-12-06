use warnings;
use 5.020;
use true;
use experimental qw( signatures );
use stable qw( postderef );

package Data::Section::Pluggable::Plugin::Yaml 0.01 {

    # ABSTRACT: Data::Section::Pluggable Plugin for YAML


    use Role::Tiny::With;
    use YAML::XS ();

    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';

    sub extensions ($class) {
        return ('yaml', 'yml');
    }

    sub process_content ($class, $dsp, $content) {
        YAML::XS::Load($content);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable::Plugin::Yaml - Data::Section::Pluggable Plugin for YAML

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Data::Section::Pluggable;
 
 my $dsp = Data::Section::Pluggable->new
                                   ->add_plugin('yaml');
 
 # prints "Welcome to Perl"
 say $dsp->get_data_section('hello.yml')->{message};
 
 __DATA__
 @@ hello.yml
 ---
 message: Welcome to Perl

=head1 DESCRIPTION

This plugin decodes YAML from C<__DATA__>.  It only applies to
filenames with the C<.yml> or C<.yaml> extension.  Under the
covers it uses L<YAML::XS>.

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
