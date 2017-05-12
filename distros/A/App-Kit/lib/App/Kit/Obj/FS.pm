package App::Kit::Obj::FS;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

has _app => (
    is       => 'ro',
    required => 1,
);

# same RSS/time as redefine-self but less room for error maintaining the resulting code in 2 places (plus Sub::Defer is already loaded via Moo), so it wins!
Sub::Defer::defer_sub __PACKAGE__ . '::cwd' => sub {
    require Cwd;
    return sub { shift; goto &Cwd::cwd }
};

# TODO: sort out conf file methods (or Config::Any etc):
#   read_json
#   write_json

#### same RSS/time as redefine-self plus 3.5% more ops ##
# sub cwd {
#     require Cwd;
#     shift;
#     goto &Cwd::cwd
# }
#
# sub cwd {
#     require Cwd;
#     no warnings 'redefine';
#     *cwd = sub {
#         shift;
#         goto &Cwd::cwd
#     };
#     shift;
#     goto &Cwd::cwd
# }
#
#
#### adds .75MB to RSS and 44.6% increase in opts, ick! ##
# sub cwd { shift->_cwd_code->(@_); }
#
# has _cwd_code => (
#     'is' => 'ro',
#     'lazy' => '1',
#     'default' => sub {
#         require Cwd;
#         return sub { shift; goto &Cwd::cwd }
#     },
# );

# TODO chdir related stuff:
# Sub::Defer::defer_sub __PACKAGE__ . '::chdir' => sub {
#     require Cwd;
#     return sub {
#         my $self = shift;
#         $self->starting_dir( $self->cwd );
#         goto &Cwd::chdir;
#     };
# };
#
# sub chbak {
#     my $self  = shift;
#     my $start = $self->starting_dir();
#     return 2 if !defined $start;
#
#     $self->chdir($start) || return;
#     $self->starting_dir(undef);
#
#     return 1;
# }

sub file_lookup {
    my ( $self, @rel_parts ) = @_;

    my $call = ref( $rel_parts[-1] ) ? pop(@rel_parts) : { 'inc' => [] };
    $call->{'inc'} = [] if !exists $call->{'inc'} || ref $call->{'inc'} ne 'ARRAY';

    my @paths;
    my $name = $self->_app->str->prefix;
    for my $base ( @{ $call->{'inc'} }, $self->spec->catdir( $self->bindir(), ".$name.d" ), @{ $self->inc } ) {
        next if !$base;
        push @paths, $self->spec->catfile( $base, @rel_parts );
    }

    return @paths if wantarray;

    my $path = '';
    for my $check (@paths) {
        if ( -e $check && -s _ ) {
            $path = $check;
            last;
        }
    }

    return $path if $path;
    return;
}

# Sub::Defer::defer_sub __PACKAGE__ . '::mkfile' => sub {
#     require File::Touch;
#     return sub {
#         my ($fs, $path) = @_;
#         $fs->mk_parent( $path ) || return;
#         eval { File::Touch::touch( $path ) } || return;
#         return 1;
#     };
# };

Sub::Defer::defer_sub __PACKAGE__ . '::mkpath' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::mk;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::rmpath' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::rm;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::empty_dir' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::empty_dir;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::mk_parent' => sub {
    require File::Path::Tiny;
    return sub {
        shift;
        goto &File::Path::Tiny::mk_parent;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::tmpfile' => sub {
    require File::Temp;
    return sub {
        $_[0] = 'File::Temp';    # quicker than: shift; unshift(@_, 'Class::Name::Here');
        goto &File::Temp::new;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::tmpdir' => sub {
    require File::Temp;
    return sub {
        $_[0] = 'File::Temp';    # quicker than: shift; unshift(@_, 'Class::Name::Here');
        goto &File::Temp::newdir;
    };
};

has spec => (
    'is'      => 'ro',
    'lazy'    => '1',
    'default' => sub {
        require File::Spec;
        return 'File::Spec';
    },
);

has bindir => (
    'is'   => 'rw',
    'lazy' => '1',

    # 'isa'     => sub { die "'bindir' must be a directory" unless -d $_[1] },
    'default' => sub {
        require FindBin;
        require Cwd;
        return $FindBin::Bin || FindBin->again() || Cwd::cwd();
    },
);

has inc => (
    'is'      => 'rw',
    'default' => sub { [] },
    'isa'     => sub { die "'inc' must be an array ref" unless ref( $_[0] ) eq 'ARRAY' },
);

# has starting_dir => (
#     'is'      => 'rw',
#     'default' => sub { undef },
# );

Sub::Defer::defer_sub __PACKAGE__ . '::read_dir' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::read_dir;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::read_file' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::read_file;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::write_file' => sub {
    require File::Slurp;
    return sub {
        shift;
        goto &File::Slurp::write_file;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::get_iterator' => sub {
    require Path::Iter;
    return sub {
        shift;
        goto &Path::Iter::get_iterator;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::yaml_write' => sub {
    require YAML::Syck;
    return sub {
        my ( $self, $file, $ref ) = @_;

        local $YAML::Syck::ImplicitTyping = 0;
        local $YAML::Syck::SingleQuote    = 1;    # to keep from arbitrary quoting/unquoting (to help make diff's cleaner)
        local $YAML::Syck::SortKeys       = 1;    # to make diff's cleaner

        return YAML::Syck::DumpFile( $file, $ref );    # this does not keep the same $YAML::Syck:: vars apparently: shift;goto &YAML::Syck::DumpFile;

        # as of at least v1.27 it writes the characters without \x escaping so no need for:
        # return $self->write_file(
        #     $file,
        #     String::UnicodeUTF8::unescape_utf8( YAML::Syck::Dump($ref) )
        # );
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::yaml_read' => sub {
    require YAML::Syck;
    return sub {
        my ( $self, $file ) = @_;
        local $YAML::Syck::ImplicitTyping = 0;
        return YAML::Syck::LoadFile($file);    # this does not keep the same $YAML::Syck:: vars apparently: shift;goto &YAML::Syck::LoadFile;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::json_write' => sub {
    require JSON::Syck;
    return sub {
        shift;
        goto &JSON::Syck::DumpFile;            # already does ♥ instead of \xe2\x99\xa5 (i.e. so no need for String::UnicodeUTF8::unescape_utf8() like w/ the YAML above)
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::json_read' => sub {
    require JSON::Syck;
    return sub {
        shift;
        goto &JSON::Syck::LoadFile;
    };
};

# TODO new FCR

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::FS - file system utility object

=head1 VERSION

This document describes App::Kit::Obj::FS version 0.1

=head1 SYNOPSIS

    my $fs = App::Kit::Obj::FS->new();
    my @guts = $fs->read_file(…);

=head1 DESCRIPTION

file system utility object

=head1 INTERFACE

=head2 new()

Returns the object.

Takes one required attribute: _app. It should be an L<App::Kit> object for it to use internally.

Has 3 optional attributes:

=head3 spec

Lazy loads L<File::Spec> and returns the class accessor for L<File::Spec> methods. Setting this via new() is probably not a good idea.

    my $dir = $fs->spec->catdir(…);

=head3 bindir

The applications main directory. Defaults to script’s directory or the current working directory.

Lazy loads L<FindBin> and L<Cwd>.

=head3 inc

An array ref of paths for file_lookup() to use. Defaults to [].

=head2 cwd()

Lazy wrapper of L<Cwd>’s cwd().

=head2 file_lookup()

In scalar context returns the first path that exists for the given arguments.

In array context returns all possible paths for the given arguments without any existence check.

The final argument can be a config hashref with the inc key whose value is an array of paths.

The arguments are the pieces of the path you are interested in that get put together in a portable way.

    my $conf = $fs->file_lookup('data', 'foo.json'); # e.g. …/my_app_base/.appkit.d/data/foo.json

The path is looked for in this order:

=over 4

1. the 'inc' paths in the given argument if any

2. a directory in the object’s base path called .$prefix.d (where $prefix is the _app attributes’s ->str->prefix).

3. the objects’s inc attribute

=back

=head2 mkpath()

Lazy wrapper of L<File::Path::Tiny>’s mk().

=head2 rmpath()

Lazy wrapper of L<File::Path::Tiny>’s rm().

=head2 empty_dir()

Lazy wrapper of L<File::Path::Tiny>’s empty_dir().

=head2 mk_parent()

Lazy wrapper of L<File::Path::Tiny>’s mk_parent().

=head2 tmpfile()

Lazy wrapper of L<File::Temp>’s tmpfile().

=head2 tmpdir()

Lazy wrapper of L<File::Temp>’s tmpdir().

=head2 read_dir()

Lazy wrapper of L<File::Slurp>’s read_dir().

=head2 read_file()

Lazy wrapper of L<File::Slurp>’s read_file().

=head2 write_file()

Lazy wrapper of L<File::Slurp>’s write_file().

=head2 json_read()

Lazy wrapper to consistently load a JSON file to a data structure.

    my $data = $fs->read_json($file);

=head2 json_write()

Lazy wrapper to consistently write a data structure as a JSON file.

    $fs->write_json($file, $data);

=head2 yaml_read()

Lazy wrapper to consistently load a YAML file to a data structure.

    my $data = $fs->read_yaml($file);

=head2 yaml_write()

Lazy wrapper to consistently write a data structure as a YAML file.

    $fs->write_yaml($file, $data);

=head2 get_iterator()

Lazy wrapper of L<Path::Iter>’s get_iterator().

=head1 DIAGNOSTICS

=over

=item C<< 'inc' must be an array ref >>

The value given for 'inc' was not an array ref.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Moo> for the object.

Lazy loaded as needed:

L<Cwd> L<File::Path::Tiny> L<File::Temp> L<File::Slurp> L<Path::Iter> L<File::Spec> L<FindBin>L<Cwd>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
