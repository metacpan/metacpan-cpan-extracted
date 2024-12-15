use warnings;
use 5.020;
use true;
use experimental qw( signatures );

package Data::Section::Pluggable::Plugin::Json 0.02 {

    # ABSTRACT: Data::Section::Pluggable Plugin for JSON


    use Role::Tiny::With;
    use JSON::MaybeXS ();

    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
    if(eval { require Data::Section::Pluggable::Role::FormatContentPlugin }) {
        with 'Data::Section::Pluggable::Role::FormatContentPlugin';
    }

    sub extensions ($class) {
        return ('json');
    }

    sub process_content ($class, $dsp, $content) {
        JSON::MaybeXS::decode_json($content);
    }

    sub format_content ($class, $dsw, $content) {
        JSON::MaybeXS::encode_json($content);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable::Plugin::Json - Data::Section::Pluggable Plugin for JSON

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Data::Section::Pluggable;
 
 my $dsp = Data::Section::Pluggable->new
                                   ->add_plugin('json');
 
 # prints "Welcome to Perl"
 say $dsp->get_data_section('hello.json')->{message};
 
 __DATA__
 @@ hello.json
 {"message":"Welcome to Perl"}

=head1 DESCRIPTION

This plugin decodes json from C<__DATA__>.  It only applies to
filenames with the C<.json> extension.  Under the covers it uses
L<JSON::MaybeXS> so it is recommended that you also install
L<Cpanel::JSON::XS> for better performance.

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
