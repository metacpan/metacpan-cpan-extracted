use warnings;
use 5.020;
use true;
use experimental qw( signatures );
use stable qw( postderef );

package Data::Section::Pluggable::Role::ContentProcessorPlugin 0.01 {

    # ABSTRACT: Plugin role for Data::Section::ContentProcessorPlugin


    use Role::Tiny;

    requires 'extensions';
    requires 'process_content';

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable::Role::ContentProcessorPlugin - Plugin role for Data::Section::ContentProcessorPlugin

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Instance mode:

 use experimental qw( signatures );
 use Data::Section::Pluggable;
 
 package Data::Section::Pluggable::Plugin::MyPlugin {
     use Role::Tiny::With;
     use Class::Tiny qw( extensions );
     with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
 
     sub process_content ($self, $dps, $content) {
         $content =~ s/\s*\z//;  # trim trailing whitespace
         return "[$content]";
     }
 }
 
 my $dps = Data::Section::Pluggable->new
                                   ->add_plugin('my_plugin', extensions => ['txt']);
 
 # prints '[Welcome to Perl]'
 say $dps->get_data_section('hello.txt');
 
 __DATA__
 @@ hello.txt
 Welcome to Perl

Class mode:

 use experimental qw( signatures );
 use Data::Section::Pluggable;
 
 package Data::Section::Pluggable::Plugin::MyPlugin {
     use Role::Tiny::With;
     with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
 
     sub extensions ($class) {
         return ('txt');
     }
 
     sub process_content ($class, $dps, $content) {
         $content =~ s/\s*\z//;  # trim trailing whitespace
         return "[$content]";
     }
 }
 
 my $dps = Data::Section::Pluggable->new
                                   ->add_plugin('my_plugin');
 
 # prints '[Welcome to Perl]'
 say $dps->get_data_section('hello.txt');
 
 __DATA__
 @@ hello.txt
 Welcome to Perl

=head1 DESCRIPTION

This plugin role provides a simple wrapper mechanism around
the L<Data::Section::Pluggable> L<method add_format|/add_format>,
making it an appropriate way to add such recipes to CPAN.

=head1 CONSTRUCTOR

=head1 new

 my $class->new(%args);  # optional

If a constructor C<new> is provided, it will be called when the plugin
is added to create an instance of the plugin.  The methods below will
be called as instance methods.  Otherwise the methods will be called
as class methods.

=head1 METHODS

All methods are to be implemented by your class.

=head2 extensions

 my @extensions = $plugin->extensions;
 my \@extensions = $plugin->extensions;

Returns a list or array reference of filename extensions the plugin
should apply to.

=head2 process_content

 my $processed = $plugin->process_content($dps, $content);

Takes the L<Data::Section::Pluggable> instance and content and returns
the process content.

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
