use warnings;
use 5.020;
use true;
use experimental qw( signatures );
use stable qw( postderef );

package Data::Section::Pluggable 0.02 {

    # ABSTRACT: Read structured data from __DATA__


    use Class::Tiny qw( package _formats _cache );
    use Exporter qw( import );
    use Ref::Util qw( is_ref is_plain_hashref is_coderef is_plain_arrayref );
    use MIME::Base64 qw( decode_base64 );
    use Carp ();

    our @EXPORT_OK = qw( get_data_section );

    sub BUILDARGS ($class, @args) {
        if(@args == 1) {
            return $args[0] if is_plain_hashref $args[0];
            return { package => $args[0] };
        } else {
            my %args = @args;
            return \%args;
        }
    }

    sub BUILD ($self, $) {
        unless(defined $self->package) {
            my $package = caller 2;
            $self->package($package);
        }
        $self->_formats({});
    }


    sub get_data_section ($self=undef, $name=undef) {

        # handle being called as a function instead of
        # a method.
        unless(is_ref $self) {
            $name = $self;
            $self = __PACKAGE__->new(scalar caller);
        }

        my $all = $self->_get_all_data_sections;
        return undef unless $all;

        if (defined $name) {
            if(exists $all->{$name}) {
                return $self->_format($name, $all->{$name});
            }
            return undef;
        } else {
            return $self->_format_all($all);
        }
    }

    sub _format_all ($self, $all) {
        my %new;
        foreach my $key (keys %$all) {
            $new{$key} = $self->_format($key, $all->{$key});
        }
        \%new;
    }

    sub _format ($self, $name, $content) {
        $content = $self->_decode($content->@*);
        if($name =~ /\.(.*?)\z/ ) {
            my $ext = $1;
            if($self->_formats->{$ext}) {
                $content = $_->($self, $content) for $self->_formats->{$ext}->@*;
            }
        }
        return $content;
    }

    sub _decode ($self, $content, $encoding) {
        return $content unless $encoding;
        if($encoding ne 'base64') {
            Carp::croak("unknown encoding: $encoding");
        }
        return decode_base64($content);
    }

    sub _get_all_data_sections ($self) {
        return $self->_cache if $self->_cache;

        my $fh = do { no strict 'refs'; \*{$self->package."::DATA"} };

        return undef unless defined fileno $fh;

        # Question: does this handle corner case where perl
        # file is just __DATA__ section?  turns out, yes!
        # added test t/data_section_pluggable__data_only.t
        seek $fh, 0, 0;
        my $content = do { local $/; <$fh> };
        $content =~ s/^.*\n__DATA__\n/\n/s; # for win32
        $content =~ s/\n__END__\n.*$/\n/s;

        my @data = split /^@@\s+(.+?)\s*\r?\n/m, $content;

        # extra at start whitespace, or __DATA_ for data only file
        shift @data;

        my $all = {};
        while (@data) {
            my ($name_encoding, $content) = splice @data, 0, 2;
            my ($name, $encoding);
            if($name_encoding =~ /^(.*)\s+\((.*?)\)$/) {
                $name = $1;
                $encoding = $2;
            } else {
                $name = $name_encoding;
            }
            $all->{$name} = [ $content, $encoding ];
        }

        return $self->_cache($all);
    }


    sub add_format ($self, $ext, $cb) {
        Carp::croak("callback is not a code reference") unless is_coderef $cb;
        push $self->_formats->{$ext}->@*, $cb;
        return $self;
    }


    sub add_plugin ($self, $name, %args) {

        Carp::croak("plugin name must match [a-z][a-z0-9_]+, got $name")
            unless $name =~ /^[a-z][a-z0-9_]+\z/;

        my $class = join '::', 'Data', 'Section', 'Pluggable', 'Plugin', ucfirst($name =~ s/_(.)/uc($1)/egr);
        my $pm    = ($class =~ s!::!/!gr) . ".pm";

        require $pm unless $self->_valid_plugin($class);

        my $plugin;
        if($class->can("new")) {
            $plugin = $class->new(%args);
        } else {
            if(%args) {
                Carp::croak("extra arguments are not allowed for class plugins (hint create constructor)");
            }
            $plugin = $class;
        }

        Carp::croak("$class is not a valid Data::Section::Pluggable plugin")
            unless $self->_valid_plugin($plugin);

        if($plugin->does('Data::Section::Pluggable::Role::ContentProcessorPlugin')) {
            my @extensions = $plugin->extensions;
            @extensions = $extensions[0]->@* if is_plain_arrayref $extensions[0];
            die "extensions method for $class returned no extensions" unless @extensions;

            my $cb = sub ($self, $content) {
                return $plugin->process_content($self, $content);
            };

            $self->add_format($_, $cb) for @extensions;

        };

        return $self;
    }

    sub _valid_plugin ($self, $plugin) {
        $plugin->can('does') && $plugin->does('Data::Section::Pluggable::Role::ContentProcessorPlugin');
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Pluggable - Read structured data from __DATA__

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Data::Section::Pluggable;
 
 my $dsp = Data::Section::Pluggable->new
                                   ->add_plugin('trim')
                                   ->add_plugin('json');
 
 # prints "Welcome to Perl" without prefix
 # or trailing white space.
 say $dsp->get_data_section('hello.txt');
 
 # also prints "Welcome to Perl"
 say $dsp->get_data_section('hello.json')->{message};
 
 # prints "This is base64 encoded.\n"
 say $dsp->get_data_section('hello.bin');
 
 __DATA__
 
 @@ hello.txt
   Welcome to Perl
 
 
 @@ hello.json
 {"message":"Welcome to Perl"}
 
 @@ hello.bin (base64)
 VGhpcyBpcyBiYXNlNjQgZW5jb2RlZC4K

=head1 DESCRIPTION

Data::Section::Simple is a module to extract data from C<__DATA__> section of Perl source file.
This module started out as a fork of L<Data::Section::Simple> (itself based on L<Mojo::Loader>),
and includes some of its tests to ensure compatibility, but it also includes features not
available in either of those modules.

This module caches the result of reading the C<__DATA__> section in the object if you use the OO
interface.  It doesn't do any caching of the processing required of "formats" (see below).

This module also supports C<base64> encoding using the same mechanism as L<Mojo::Loader>, which
is helpful for putting binary sections in C<__DATA__>.

As mentioned, this module aims to be and is largely a drop in replacement for L<Data::Section::Simple>
with some extra features.  Here are the known ways in which it is not compatible:

=over 4

=item

Because L<Data::Section::Simple> does not support C<base64> encoded data, these data sections
would include the C< (base64)> in the filename instead of decoding the content.

=item

When a section is not found L<Data::Section::Simple> return the empty list from C<get_data_section>,
where as this module returns C<undef>, in order to keep the return value more consistent.

=back

=head1 CONSTRUCTOR

 my $dsp = Data::Section::Pluggable->new($package);
 my $dsp = Data::Section::Pluggable->new(\%attributes);
 my $dsp = Data::Section::Pluggable->new(%attributes);

=head1 ATTRIBUTES

=head2 package

The name of the package to read from C<__DATA__>.  If not specified, then
the current package will be used.

=head1 METHODS

=head2 get_data_section

 my $hash = get_data_section;
 my $data = get_data_section $name;
 my $hash = $dsp->get_data_section;
 my $data = $dsp->get_data_section($name);

Gets data from C<__DATA_>.  This can be called either as a function (which is
optionally exported from this module), or as an object method.  Creating an
instance of L<Data::Section::Pluggable> allows you to use packages other than
the default or use plugins.

=head2 add_format

 $dsp->add_format( $ext, sub ($dsp, $content) { return ... } );

Adds a content processor to the given filename extension.  The extension should be a filename
extension without the C<.>, for example C<txt> or C<json>.

The callback takes the L<Data::Section::Pluggable> instance as its first argument and the content
to be processed as the second.  This callback should return the processed content as a scalar.

You can chain multiple content processors to the same filename extension, and they will be
called in the order that they were added.

=head2 add_plugin

 $dsp->add_plugin( $name, %args );

Applies the plugin with C<$name>.  If the plugin supports instance mode (that is: it has a constructor
named C<new>), then C<%args> will be passed to the constructor.  For included plugins see L</CORE PLUGINS>.
To write your own see L</PLUGIN ROLES>.

=head1 CORE PLUGINS

=head2 json

Automatically decode json into Perl data structures.
See L<Data::Section::Pluggable::Plugin::Json>.

=head2 trim

Automatically trim leading and trailing white space.
See L<Data::Section::Pluggable::Plugin::Trim>.

=head1 PLUGIN ROLES

=head2 ContentProcessorPlugin

Used for adding content processors for specific formats.  This
is essentially a way to wrap the L<add_format method|/add_format>
as a module.  See L<Data::Section::Pluggable::Role::ContentProcessorPlugin>.

=head1 SEE ALSO

These are some alternative modules that do a similar thing, each
with their own feature set and limitations.

=over 4

=item L<Data::Section>

=item L<Data::Section::Simple>

=item L<Data::Section::Writer>

=item L<Mojo::Loader>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
